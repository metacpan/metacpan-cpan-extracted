package Catalyst::Plugin::AutoCRUD::Model::StorageEngine::DBIC::CRUD;
{
  $Catalyst::Plugin::AutoCRUD::Model::StorageEngine::DBIC::CRUD::VERSION = '2.143070';
}

use strict;
use warnings;

our @EXPORT;
BEGIN {
    use base 'Exporter';
    @EXPORT = qw/ create list update delete list_stringified /;
}

use Data::Page;
use List::MoreUtils qw(zip uniq);
use Scalar::Util qw(blessed);
use overload ();

my $is_numberish = { map {$_ => 1} qw/
    bigint
    bigserial
    dec
    decimal
    double precision
    float
    int
    integer
    mediumint
    money
    numeric
    real
    smallint
    serial
    tinyint
    year
/ };

# stringify a row of fields according to rules described in our POD
sub _stringify {
    my $row = shift;
    return () if !defined $row or !blessed $row;
    return (
        eval { $row->display_name } || (
            overload::Method($row, '""')
        ? $row.''
        : (
            $row->result_source->source_name .': '.
            join (', ', map { $_ .'('. $row->get_column($_) .')' }
                            $row->primary_columns)
        ))
    );
}

# create a JSON dict for this row's PK
sub _create_JSON_ID {
    my $row = shift;
    return undef if !defined $row or !blessed $row;
    return [map {{
        tag => 'input',
        type => 'hidden',
        name => 'cpac_filter.'. $_,
        value => $row->get_column($_),
    }} $row->primary_columns];
}

# create a unique identifier for this row from PKs
sub _create_ID {
    my $row = shift;
    return join "\000\000",
        map { "$_\000${\$row->get_column($_)}" } $row->primary_columns;
}

# take unique identifier and reconstruct hash of row PK vals
sub _extract_ID {
    my ($val, $finder, $prefix, $map) = @_;
    $prefix = $prefix ? "$prefix." : '';
    $finder ||= {};

    foreach my $i (split m/\000\000/, $val) {
        my ($k, $v) = split m/\000/, $i;
        $k = $map->{$k} if $map;
        $finder->{"$prefix$k"} = $v;
    }
    return $finder;
}

# find whether this DMBS supports ILIKE or just LIKE
sub _likeop_for {
    my $model = shift;
    my $sqlt_type = $model->result_source->storage->sqlt_type;
    my %ops = (
        SQLite => '-like',
        MySQL  => '-like',
        Oracle => '-like',
    );
    return $ops{$sqlt_type} || '-ilike';
}

sub list {
    my ($self, $c) = @_;
    my $conf = $c->stash->{cpac}->{tc};
    my $meta = $c->stash->{cpac}->{tm};

    my $response = $c->stash->{json_data} = {};
    my @columns = @{$conf->{cols}};

    my ($page, $limit, $sort, $dir) =
        @{$c->stash}{qw/ cpac_page cpac_limit cpac_sortby cpac_dir /};
    my $filter = {}; my $search_opts = {};

    # sanity check the sort param
    $sort = $c->stash->{cpac}->{g}->{default_sort}
        if not (defined $sort and $sort =~ m/^[\w ]+$/ and exists $meta->f->{$sort});
    $sort = $c->stash->{cpac}->{g}->{default_sort}
        if $meta->f->{$sort}->extra('rel_type') and $meta->f->{$sort}->extra('rel_type') =~ m/_many$/;

    # we want to prefetch all related data for _stringify
    foreach my $rel (@columns) {
        next unless ($meta->f->{$rel}->is_foreign_key or $meta->f->{$rel}->extra('is_reverse'));
        next if $meta->f->{$rel}->extra('rel_type') and $meta->f->{$rel}->extra('rel_type') =~ m/_many$/;
        next if $meta->f->{$rel}->extra('masked_by');
        push @{$search_opts->{prefetch}}, $rel;
    }

    # use of FK or RR partial text filter must disable the DB-side page/sort
    my %delay_page_sort = ();
    foreach my $p (keys %{$c->req->params}) {
        next unless (my $col) = ($p =~ m/^cpac_filter\.([\w ]+)/);
        next unless exists $meta->f->{$col}
            and ($meta->f->{$col}->is_foreign_key or $meta->f->{$col}->extra('is_reverse'));

        $delay_page_sort{$col} += 1
            if $c->req->params->{"cpac_filter.$col"} !~ m/\000/;
    }

    # find filter fields in UI form that can be passed to DB
    foreach my $p (keys %{$c->req->params}) {
        next unless (my $col) = ($p =~ m/^cpac_filter\.([\w ]+)/);
        next unless exists $meta->f->{$col};
        next if exists $delay_page_sort{$col};
        my $val = $c->req->params->{"cpac_filter.$col"};

        # exact match on RR value (checked above)
        if ($meta->f->{$col}->extra('is_reverse')) {
            if ($meta->f->{$col}->extra('rel_type') eq 'many_to_many') {
                push @{$search_opts->{join}},
                    {@{ $meta->f->{$col}->extra('via') }};
                $col = $meta->f->{$col}->extra('via')->[1];
            }
            else {
                push @{$search_opts->{join}}, $col;
            }

            _extract_ID($val, $filter, $col);
            next;
        }

        # exact match on FK value (checked above)
        if ($meta->f->{$col}->is_foreign_key) {
            my %fmap = zip @{$meta->f->{$col}->extra('ref_fields')},
                           @{$meta->f->{$col}->extra('fields')};
            _extract_ID($val, $filter, 'me', \%fmap);
            next;
        }

        # for numberish types the case insensitive functions may not work
        # plus, an exact match is probably what the user wants (i.e. 1 not 1*)
        if (exists $is_numberish->{lc $meta->f->{$col}->data_type}) {
            $filter->{"me.$col"} = $c->req->params->{"cpac_filter.$col"};
            next;
        }

        # ordinary search clause if any of the filter fields were filled in UI
        $filter->{"me.$col"} = {
            # find whether this DMBS supports ILIKE or just LIKE
            _likeop_for($c->model($meta->extra('model')))
                => '%'. $c->req->params->{"cpac_filter.$col"} .'%'
        };
    }

    # any sort on FK -must- disable DB-side paging, unless we already know the
    # supplied filter is a legitimate PK of the related table
    if (($meta->f->{$sort}->is_foreign_key or $meta->f->{$sort}->extra('is_reverse'))
            and not (exists $c->req->params->{"cpac_filter.$sort"} and not exists $delay_page_sort{$sort})) {
        $delay_page_sort{$sort} += 1;
    }

    # sort col which can be passed to the db
    if ($dir =~ m/^(?:ASC|DESC)$/ and !exists $delay_page_sort{$sort}
        and not ($meta->f->{$sort}->is_foreign_key or $meta->f->{$sort}->extra('is_reverse'))) {
        $search_opts->{order_by} = { '-'.lc($dir) => "me.$sort" };
    }

    # set up pager, if needed (if user filtering by FK then delay paging)
    if ($page =~ m/^\d+$/ and $limit =~ m/^\d+$/ and not scalar keys %delay_page_sort) {
        $search_opts->{page} = $page;
        $search_opts->{rows} = $limit;
    }

    if ($ENV{AUTOCRUD_DEBUG} and $c->debug) {
        use Data::Dumper;
        $c->log->debug( Dumper [$filter, $search_opts, \%delay_page_sort] );
    }

    my $rs = $c->model($meta->extra('model'))->search($filter, $search_opts);
    $response->{rows} ||= [];

    if ($ENV{AUTOCRUD_DEBUG} and $c->debug) {
        $c->model($meta->extra('model'))->result_source->storage->debug(1);
    }

    # make data structure for JSON output
    DBIC_ROW:
    while (my $row = $rs->next) {
        my $data = {};
        foreach my $col (@columns) {
            if (($meta->f->{$col}->is_foreign_key
                or $meta->f->{$col}->extra('is_reverse'))
                and not $meta->f->{$col}->extra('masked_by')) {

                if ($meta->f->{$col}->extra('rel_type')
                    and $meta->f->{$col}->extra('rel_type') =~ m/many_to_many$/) {

                    my $link = $meta->f->{$col}->extra('via')->[0];
                    my $target = $meta->f->{$col}->extra('via')->[1];

                    $data->{$col} = $row->can($link) ?
                        [ uniq sort map { _stringify($_) } map {$_->$target} $row->$link->all ] : [];
                }
                elsif ($meta->f->{$col}->extra('rel_type')
                       and $meta->f->{$col}->extra('rel_type') =~ m/has_many$/) {

                    $data->{$col} = $row->can($col) ?
                        [ uniq sort map { _stringify($_) } $row->$col->all ] : [];

                    # check filter on FK, might want to skip further processing/storage
                    if (exists $c->req->params->{"cpac_filter.$col"}
                            and exists $delay_page_sort{$col}) {
                        my $p_val = $c->req->params->{"cpac_filter.$col"};
                        my $fk_match = ($p_val ? qr/\Q$p_val\E/i : qr/./);

                        next DBIC_ROW if 0 == scalar grep {$_ =~ m/$fk_match/}
                                                          @{$data->{$col}};
                    }
                }
                else {
                    # here assume table names are sane perl identifiers
                    $data->{$col} = _stringify($row->$col);
                    $data->{"cpac__pk_for_$col"} = _create_JSON_ID($row->$col);

                    # check filter on FK, might want to skip further processing/storage
                    if (exists $c->req->params->{"cpac_filter.$col"}
                            and exists $delay_page_sort{$col}) {
                        my $p_val = $c->req->params->{"cpac_filter.$col"};
                        my $fk_match = ($p_val ? qr/\Q$p_val\E/i : qr/./);

                        next DBIC_ROW if $data->{$col} !~ m/$fk_match/;
                    }
                }
            }
            else {
                # proxy cols must be called as accessors, but normally we'd
                # prefer to use get_column, so try both, otherwise empty str

                my $evalue = eval{$row->get_column($col)};
                if ($@) { $evalue = eval{$row->$col} }
                if ($@) { $evalue = '' }
                $data->{$col} = (defined $evalue ? $evalue : '');
            }
        }

        #if ($ENV{AUTOCRUD_DEBUG} and $c->debug) {
        #    $c->log->debug( Dumper ['item:', $data] );
        #}

        # these are used for delete and update to overcome ExtJS single col PK
        $data->{cpac__id} = _create_ID($row);
        $data->{cpac__display_name} = _stringify($row);
        push @{$response->{rows}}, $data;
    }

    # sort col which cannot be passed to the DB
    if (exists $delay_page_sort{$sort}) {
        @{$response->{rows}} = sort {
            $dir eq 'ASC' ? ($a->{$sort} cmp $b->{$sort})
                          : ($b->{$sort} cmp $a->{$sort})
        } @{$response->{rows}};
    }

    $response->{total} =
        eval {$rs->pager->total_entries} || scalar @{$response->{rows}};

    # user filtered by FK so do the paging now (will be S-L-O-W)
    if ($page =~ m/^\d+$/ and $limit =~ m/^\d+$/ and scalar keys %delay_page_sort) {
        my $pg = Data::Page->new;
        $pg->total_entries(scalar @{$response->{rows}});
        $pg->entries_per_page($limit);
        $pg->current_page($page);
        $response->{rows} = [ $pg->splice($response->{rows}) ];
        $response->{total} = $pg->total_entries;
    }

    if ($ENV{AUTOCRUD_DEBUG} and $c->debug) {
        $c->log->debug( Dumper $response );
        $c->model($meta->extra('model'))->result_source->storage->debug(0);
    }

    return $self;
}

sub create {
    my ($self, $c) = @_;
    return &_create_update_txn($c, sub {
        my $c = shift;
        my $meta = $c->stash->{cpac}->{tm};
        my $rs = $c->model( $meta->extra('model') );
        return $rs->new({});
    });
}

sub update {
    my ($self, $c) = @_;
    return &_create_update_txn($c, sub {
        my $c = shift;
        my $params = $c->req->params;
        my $meta = $c->stash->{cpac}->{tm};
        my $rs = $c->model( $meta->extra('model') );
        return $rs->find(_extract_ID($params->{'cpac__id'} || ''), {key => 'primary'});
    });
}

sub _create_update_txn {
    my ($c, $mk_self_row) = @_;
    my $meta = $c->stash->{cpac}->{tm};
    my $response = $c->stash->{json_data} = {};

    if ($ENV{AUTOCRUD_DEBUG} and $c->debug) {
        $c->model($meta->extra('model'))->result_source->storage->debug(1);
    }

    my $success =
        eval{ $c->model($meta->extra('model'))
            ->result_source->storage->txn_do(\&_create_update_core, $c, $mk_self_row) };
    $response->{'success'} = (($success && !$@) ? 1 : 0);
    $c->log->debug($@) if $@ and $c->debug;

    if ($ENV{AUTOCRUD_DEBUG} and $c->debug) {
        $c->model($meta->extra('model'))->result_source->storage->debug(0);
    }
}

sub _create_update_core {
    my ($c, $mk_self_row) = @_;
    my $meta = $c->stash->{cpac}->{tm};
    my $params = $c->req->params;

    if ($ENV{AUTOCRUD_DEBUG} and $c->debug) {
        use Data::Dumper;
        $c->log->debug( Dumper $params );
    }

    my $self_row = $mk_self_row->($c);
    my $proxy_updates = {};
    my $update = {};

    COL: foreach my $col (@{$meta->extra('fields')}) {
        my $ci = $meta->f->{$col};
        next COL if $ci->extra('is_reverse') or $ci->extra('masked_by');

        if (not $ci->is_foreign_key) {
            # fix for HTML standard which excludes checkboxes
            $params->{$col} ||= 'false'
                if $ci->data_type and $ci->data_type eq 'boolean';

            # skip auto-inc cols unless they contain data
            next COL unless exists $params->{$col}
                and ($params->{$col} or not $ci->is_auto_increment);

            # only works if user doesn't change the FK val
            if ($ci->extra('is_proxy')) {
                $proxy_updates->{$ci->extra('proxy_field')}
                    ->{$ci->extra('proxy_rel_field')} = $params->{$col};
                next COL;
            }

            # copy simple form data into new row
            $self_row->set_inflated_columns({$col => $params->{$col}});

            next COL;
        }

        # else is foreign key
        my $link = $c->stash->{cpac}->{m}->t->{ $ci->extra('ref_table') };

        # some kind of update to an existing relation
        if (!exists $params->{'checkbox.' . $col}) {
            # someone is messing with the AJAX (tests?)
            next COL if !defined $params->{'combobox.' . $col};

            # user has blanked the field to remove the relation
            if (!length $params->{'combobox.' . $col}) {
                $self_row->set_column($_ => undef)
                    for @{$ci->extra('fields')};
                delete $proxy_updates->{$col};
            }

            # user has cleared or not updated the field
            next COL if $params->{'combobox.' . $col} !~ m/\000/;

            # update to new related record
            # we find the target and pass in the row object to DBIC
            my $finder = _extract_ID($params->{'combobox.' . $col});
            my $found_row = $c->model( $link->extra('model') )->find($finder, {key => 'primary'})
                or $self_row->throw_exception("autocrud: failed to find row for $col");
            $self_row->set_inflated_columns({$col => $found_row});
            delete $proxy_updates->{$col};

            next COL;
        }

        # else new related record to be created
        delete $proxy_updates->{$col};
        my $new_related = {};

        foreach my $fcol (@{$link->extra('fields')}) {
            my $fci = $link->f->{$fcol};
            next if $fci->extra('is_reverse') or $fci->extra('masked_by');

            # basic fields in the related record
            if (exists $params->{"$col.$fcol"}) {
                # fix for HTML standard which excludes checkboxes
                $params->{"$col.$fcol"} ||= 'false'
                    if $fci->data_type and $fci->data_type eq 'boolean';

                # skip auto-inc cols unless they contain data
                next unless exists $params->{"$col.$fcol"}
                    and ($params->{"$col.$fcol"} or not $fci->is_auto_increment);

                $new_related->{$fcol} = $params->{"$col.$fcol"};
            }
            # any foreign keys (belongs_to) in the related record
            # we find the target and pass the row object to DBIC
            elsif (exists $params->{"combobox.$col.$fcol"}) {
                next unless length $params->{"combobox.$col.$fcol"};

                my $finder = _extract_ID($params->{"combobox.$col.$fcol"});
                my $link_link = $c->stash->{cpac}->{m}->t->{ $fci->extra('ref_table') };
                $new_related->{$fcol} = 
                    $c->model( $link_link->extra('model') )->find($finder, {key => 'primary'})
                    or $self_row->throw_exception("autocrud: failed to find row for $fcol");
            }
        }

        my $new_col = $c->model( $link->extra('model') )->create($new_related)
            or $self_row->throw_exception("autocrud: failed to create row for $col");
        $self_row->set_inflated_columns({$col => $new_col});
    }

    foreach my $rel (keys %$proxy_updates) {
        next unless scalar keys %{$proxy_updates->{$rel}};
        foreach my $f (keys %{$proxy_updates->{$rel}}) {
            $self_row->$rel->set_inflated_columns({
                $f => $proxy_updates->{$rel}->{$f}
            });
        }
        $self_row->result_source->schema->txn_do(
            sub { $self_row->$rel->update }
        ); # save it
    }

    if ($ENV{AUTOCRUD_DEBUG} and $c->debug) {
        use Data::Dumper;
        $c->log->debug( Dumper $params );
    }

    return $self_row->result_source->schema->txn_do(sub {
        $self_row->in_storage ? $self_row->update : $self_row->insert
    });
}

sub delete {
    my ($self, $c) = @_;
    my $meta = $c->stash->{cpac}->{tm};
    my $response = $c->stash->{json_data} = {success => 0};

    return unless $c->req->params->{key};
    my $filter = _extract_ID($c->req->params->{key});

    if ($ENV{AUTOCRUD_DEBUG} and $c->debug) {
        $c->model($meta->extra('model'))->result_source->storage->debug(1);
    }
    my $row = eval { $c->model($meta->extra('model'))->find($filter) };

    if (blessed $row
        and eval { $row->result_source->schema->txn_do(sub { $row->delete }) }) {
        $response->{'success'} = 1;
    }

    if ($ENV{AUTOCRUD_DEBUG} and $c->debug) {
        $c->model($meta->extra('model'))->result_source->storage->debug(0);
    }
    return $self;
}

sub list_stringified {
    my ($self, $c) = @_;
    my $meta = $c->stash->{cpac}->{tm};
    my $response = $c->stash->{json_data} = {};

    my $page  = $c->req->params->{'page'}   || 1;
    my $limit = $c->req->params->{'limit'}  || 5;
    my $query = $c->req->params->{'query'}  || '';
    my $fk    = $c->req->params->{'fkname'} || '';

    # sanity check foreign key, and set up string part search
    $fk =~ s/\s//g; $fk =~ s/^[^.]*\.//;
    my $query_re = ($query ? qr/\Q$query\E/i : qr/./);

    if (!$fk
        or !exists $meta->f->{$fk}
        or not ($meta->f->{$fk}->is_foreign_key
            or $meta->f->{$fk}->extra('is_reverse'))) {

        $c->stash->{json_data} = {total => 0, rows => []};
        return $self;
    }
    
    my $rs = $c->model($meta->extra('model'))
                ->result_source->related_source($fk)->resultset;
    my @data = ();

    # first try a simple and quick primary key search
    if (my $single_result = eval{ $rs->find($query) }) {
        @data = ({
            dbid => _create_ID($single_result),
            stringified => _stringify($single_result),
        });
    }
    else {
        # do the full text search
        my @results =  map  { { dbid => _create_ID($_), stringified => _stringify($_) } }
                       grep { _stringify($_) =~ m/$query_re/ } $rs->all;
        @data = sort { $a->{stringified} cmp $b->{stringified} } @results;
    }

    my $pg = Data::Page->new;
    $pg->total_entries(scalar @data);
    $pg->entries_per_page($limit);
    $pg->current_page($page);

    $response->{rows} = [ $pg->splice(\@data) ];
    $response->{total} = $pg->total_entries;

    if ($ENV{AUTOCRUD_DEBUG} and $c->debug) {
        use Data::Dumper;
        $c->log->debug( Dumper $response->{rows} );
    }

    return $self;
}

1;

__END__
