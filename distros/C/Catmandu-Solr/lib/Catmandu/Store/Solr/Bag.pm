package Catmandu::Store::Solr::Bag;

use Catmandu::Sane;
use Catmandu::Util qw(:is);
use Carp qw(confess);
use Catmandu::Hits;
use Catmandu::Store::Solr::Searcher;
use Catmandu::Store::Solr::CQL;
use Catmandu::Error;
use Moo;
use MooX::Aliases;

our $VERSION = "0.0302";

with 'Catmandu::Bag';
with 'Catmandu::CQLSearchable';
with 'Catmandu::Buffer';

has cql_mapping => (is => 'ro');

has bag_key => (is => 'lazy', alias => 'bag_field');

sub _build_bag_key {
    $_[0]->store->bag_key;
}

sub generator {
    my ($self) = @_;
    my $store     = $self->store;
    my $name      = $self->name;
    my $limit     = $self->buffer_size;
    my $bag_field = $self->bag_field;
    my $query  = qq/$bag_field:"$name"/;
    sub {
        state $start = 0;
        state $hits;
        unless ($hits && @$hits) {
            $hits = $store->solr->search($query, {
                start => $start,
                rows => $limit,
                defType => "lucene",
                facet      => "false",
                spellcheck => "false"
            })->content->{response}{docs};
            $start += $limit;
        }
        my $hit = shift(@$hits) || return;
        $self->map_fields($hit);
        $hit;
    };
}

sub count {
    my ($self) = @_;
    my $name      = $self->name;
    my $bag_field = $self->bag_field;
    my $res = $self->store->solr->search(
        qq/$bag_field:"$name"/,
        {
            rows       => 0,
            facet      => "false",
            spellcheck => "false",
            defType    => "lucene",
        }
    );
    $res->content->{response}{numFound};
}

sub get {
    my ($self, $id) = @_;
    my $name      = $self->name;
    my $id_field  = $self->id_field;
    my $bag_field = $self->bag_field;
    my $res  = $self->store->solr->search(
        qq/$bag_field:"$name" AND $id_field:"$id"/,
        {
            rows       => 1,
            facet      => "false",
            spellcheck => "false",
            defType    => "lucene",
        }
    );
    my $hit = $res->content->{response}{docs}->[0] || return;
    $self->map_fields($hit);
    $hit;
}

sub add {
    my ($self, $data) = @_;

    my $bag_field = $self->bag_field;

    my @fields = (WebService::Solr::Field->new($bag_field => $self->name));

    for my $key (keys %$data) {
        next if $key eq $bag_field;
        my $val = $data->{$key};
        if (is_array_ref($val)) {
            is_value($_) && push @fields,
              WebService::Solr::Field->new($key => $_)
              foreach @$val;
        }
        elsif (is_value($val)) {
            push @fields, WebService::Solr::Field->new($key => $val);
        }
    }

    $self->buffer_add(WebService::Solr::Document->new(@fields));

    if ($self->buffer_is_full) {
        $self->commit;
    }
}

sub delete {
    my ($self, $id) = @_;
    my $name = $self->name;
    my $id_field  = $self->id_field;
    my $bag_field = $self->bag_field;
    $self->store->solr->delete_by_query(qq/$bag_field:"$name" AND $id_field:"$id"/);
}

sub delete_all {
    my ($self) = @_;
    my $name = $self->name;
    my $bag_field = $self->bag_field;
    $self->store->solr->delete_by_query(qq/$bag_field:"$name"/);
}
sub delete_by_query {
    my ($self, %args) = @_;
    my $name      = $self->name;
    my $bag_field = $self->bag_field;
    $self->store->solr->delete_by_query(qq/$bag_field:"$name" AND ($args{query})/);
}

sub commit {
    my ($self) = @_;
    my $solr = $self->store->solr;
    my $err;
    if ($self->buffer_used) {
        eval { $solr->add($self->buffer) } or push @{ $err ||= [] }, $@;
        $self->clear_buffer;
    }
    unless($self->store->{_tx}){
        eval { $solr->commit } or push @{ $err ||= [] }, $@;
    }

    if(defined $err && $self->store->on_error eq 'throw'){
        Catmandu::Error->throw($err->[0]);
    }
}

sub search {
    my ($self, %args) = @_;

    my $query = delete $args{query};
    my $start = delete $args{start};
    my $limit = delete $args{limit};
    my $bag   = delete $args{reify};

    my $name      = $self->name;
    my $id_field  = $self->id_field;
    my $bag_field = $self->bag_field;

    my $bag_fq = qq/{!type=lucene}$bag_field:"$name"/;

    if ( $args{fq} ) {
        if (is_array_ref( $args{fq})) {
            $args{fq} = [ $bag_fq , @{ $args{fq} } ];
        }
        else {
            $args{fq} = [$bag_fq, $args{fq}];
        }
    } else {
        $args{fq} = $bag_fq;
    }

    my $res = $self->store->solr->search($query, {%args, start => $start, rows => $limit});

    my $set = $res->content->{response}{docs};

    if ($bag) {
        $set = [map { $bag->get($_->{$id_field}) } @$set];
    } else {
        $self->map_fields($_) for (@$set);
    }

    my $hits = Catmandu::Hits->new({
        limit => $limit,
        start => $start,
        total => $res->content->{response}{numFound},
        hits  => $set,
    });

    if ($res->facet_counts) {
        $hits->{facets} = $res->facet_counts;
    }

    if ($res->spellcheck) {
        $hits->{spellcheck} = $res->spellcheck;
    }
    if ( $res->content->{highlighting} ) {
        $hits->{highlighting} = $res->content->{highlighting};
    }

    $hits;
}

sub searcher {
    my ($self, %args) = @_;
    Catmandu::Store::Solr::Searcher->new(%args, bag => $self);
}

sub translate_sru_sortkeys {
    my ($self, $sortkeys) = @_;
    join(',', grep { defined $_ } map { $self->_translate_sru_sortkey($_) } split /\s+/, $sortkeys);
}
sub _translate_sru_sortkey {
    my ($self, $sortkey) = @_;
    my ($field, $schema, $asc) = split /,/, $sortkey;
    $field || return;
    if (my $map = $self->cql_mapping) {
        $field = lc $field;
        $field =~ s/(?<=[^_])_(?=[^_])//g if $map->{strip_separating_underscores};
        $map = $map->{indexes} || return;
        $map = $map->{$field}  || return;
        $map->{sort} || return;
        if (ref $map->{sort} && $map->{sort}{field}) {
            $field = $map->{sort}{field};
        } elsif (ref $map->{field}) {
            $field = $map->{field}->[0];
        } elsif ($map->{field}) {
            $field = $map->{field};
        }
    }
    $asc //= 1;
    "${field} ".($asc ? "asc" : "desc");
}
sub translate_cql_query {
    my($self,$query) = @_;
    Catmandu::Store::Solr::CQL->new(mapping => $self->cql_mapping)->parse($query);
}

sub normalize_query {
    $_[1] || "{!type=lucene}*:*";
}

sub map_fields {
    my ($self, $item) = @_;
    delete $item->{$self->bag_field};
}

=head1 SEE ALSO

L<Catmandu::Bag>, L<Catmandu::Searchable>

=cut

1;
