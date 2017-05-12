package DBIx::XHTML_Table;

use strict;
use warnings;
our $VERSION = '1.49';

use DBI;
use Carp;

# GLOBALS
use vars qw(%ESCAPES $T $N);
($T,$N)  = ("\t","\n");
%ESCAPES = (
    '&' => '&amp;',
    '<' => '&lt;',
    '>' => '&gt;',
    '"' => '&quot;',
);

#################### CONSTRUCTOR ###################################

# see POD for documentation
sub new {
    my $class = shift;
    my $self  = {
        null_value => '&nbsp;',
    };
    bless $self, $class;

    # last arg might be GTCH (global table config hash)
    $self->{'global'} = pop if ref $_[$#_] eq 'HASH';

    # note: disconnected handles aren't caught :(

    if (UNIVERSAL::isa($_[0],'DBI::db')) {
        # use supplied db handle
        $self->{'dbh'}        = $_[0];
        $self->{'keep_alive'} = 1;
    } 
    elsif (ref($_[0]) eq 'ARRAY') {
        # go ahead and accept a pre-built 2d array ref
        $self->_do_black_magic(@_);
    }
    else {
        # create my own db handle
        eval { $self->{'dbh'} = DBI->connect(@_) };
        carp $@ and return undef if $@;
    }

    return $self;
}

#################### OBJECT METHODS ################################

sub exec_query {
    my ($self,$sql,$vars) = @_;

    carp "can't call exec_query(): do database handle" unless $self->{'dbh'};

    eval {
        $self->{'sth'} = (UNIVERSAL::isa($sql,'DBI::st'))
            ? $sql
            : $self->{'dbh'}->prepare($sql)
        ;
        $self->{'sth'}->execute(@$vars);
    };
    carp $@ and return undef if $@;

    # store the results
    $self->{'fields_arry'} = [ @{$self->{'sth'}->{'NAME'}} ];
    $self->{'fields_hash'} = $self->_reset_fields_hash();
    $self->{'rows'}        = $self->{'sth'}->fetchall_arrayref();
    carp "can't call exec_query(): no data was returned from query" unless @{$self->{'rows'}};

    if (exists $self->{'pk'}) {
        # remove the primary key info from the arry and hash
        $self->{'pk_index'} = delete $self->{'fields_hash'}->{$self->{'pk'}};
        splice(@{$self->{'fields_arry'}},$self->{'pk_index'},1) if defined $self->{'pk_index'};
    }

    return $self;
}

sub output {
    my ($self,$config,$no_ws) = @_;
    carp "can't call output(): no data" and return '' unless $self->{'rows'};

    # have to deprecate old arguments ...
    if ($no_ws) {
        carp "scalar arguments to output() are deprecated, use hash reference";
        $N = $T = '';
    }
    if ($config and not ref $config) {
        carp "scalar arguments to output() are deprecated, use hash reference";
        $self->{'no_head'} = $config;
    }
    elsif ($config) {
        $self->{'no_head'}    = $config->{'no_head'};
        $self->{'no_ucfirst'} = $config->{'no_ucfirst'};
        $N = $T = ''         if $config->{'no_indent'};
        if ($config->{'no_whitespace'}) {
            carp "no_whitespace attrib deprecated, use no_indent";
            $N = $T = '';
        }
    }

    return $self->_build_table();
}

sub modify {
    my ($self,$tag,$attribs,$cols) = @_;
    $tag = lc $tag;

    # apply attributes to specified columns
    if (ref $attribs eq 'HASH') {
        $cols = 'global' unless defined( $cols) && length( $cols );
        $cols = $self->_refinate($cols);

        while (my($attr,$val) = each %$attribs) {
            $self->{lc $_}->{$tag}->{$attr} = $val for @$cols;
        }
    }
    # or handle a special case (e.g. <caption>)
    else {
        # cols is really attribs now, attribs is just a scalar
        $self->{'global'}->{$tag} = $attribs;

        # there is only one caption - no need to rotate attribs
        if (ref $cols->{'style'} eq 'HASH') {
            $cols->{'style'} = join('; ',map { "$_: ".$cols->{'style'}->{$_} } sort keys %{$cols->{'style'}}) . ';';
        }

        $self->{'global'}->{$tag."_attribs"} = $cols;
    }

    return $self;
}

sub map_cell {
    my ($self,$sub,$cols) = @_;

    carp "map_cell() is being ignored - no data" and return $self unless $self->{'rows'};

    $cols = $self->_refinate($cols);
    for (@$cols) {
        my $key;
        if (defined $self->{'fields_hash'}->{$_}) {
            $key = $_;
        } elsif( defined $self->{'fields_hash'}->{lc $_}) {
            $key = lc $_;
        } else {
            SEARCH: for my $k (sort keys %{ $self->{'fields_hash'} }) {
                if (lc( $k ) eq lc( $_ )) {
                    $key = $k;
                    last SEARCH;
                }
            }
        }
        next unless $key;
        $self->{'map_cell'}->{$key} = $sub;
    }
    return $self;
}

sub map_head {
    my ($self,$sub,$cols) = @_;

    carp "map_head() is being ignored - no data" and return $self unless $self->{'rows'};

    $cols = $self->_refinate($cols);
    for (@$cols) {
        my $key;
        if (defined $self->{'fields_hash'}->{$_}) {
            $key = $_;
        } elsif( defined $self->{'fields_hash'}->{lc $_}) {
            $key = lc $_;
        } else {
            SEARCH: for my $k (sort keys %{ $self->{'fields_hash'} }) {
                if (lc( $k ) eq lc( $_ )) {
                    $key = $k;
                    last SEARCH;
                }
            }
        }
        next unless $key;
        $self->{'map_head'}->{$key} = $sub;
    }

    return $self;
}

sub add_col_tag {
    my ($self,$attribs) = @_;
    $self->{'global'}->{'colgroup'} = {} unless $self->{'colgroups'};
    push @{$self->{'colgroups'}}, $attribs;

    return $self;
}

sub calc_totals {
    my ($self,$cols,$mask) = @_;
    return undef unless $self->{'rows'};

    $self->{'totals_mask'} = $mask;
    $cols = $self->_refinate($cols);

    my @indexes;
    for (@$cols) {
        my $index;
        if (exists $self->{'fields_hash'}->{$_}) {
            $index = $self->{'fields_hash'}->{$_};    
        } elsif (exists $self->{'fields_hash'}->{lc $_}) {
            $index = $self->{'fields_hash'}->{lc $_};    
        } else {
            SEARCH: for my $k (sort keys %{ $self->{'fields_hash'} }) {
                if (lc( $k ) eq lc( $_ )) {
                    $index = $self->{'fields_hash'}->{$k};
                    last SEARCH;
                }
            }
        }
        push @indexes, $index;
    }

    $self->{'totals'} = $self->_total_chunk($self->{'rows'},\@indexes);

    return $self;
}

sub calc_subtotals {
    my ($self,$cols,$mask,$nodups) = @_;
    return undef unless $self->{'rows'};

    $self->{'subtotals_mask'} = $mask;
    $cols = $self->_refinate($cols);

    my @indexes;
    for (@$cols) {
        my $index;
        if (exists $self->{'fields_hash'}->{$_}) {
            $index = $self->{'fields_hash'}->{$_};    
        } elsif (exists $self->{'fields_hash'}->{lc $_}) {
            $index = $self->{'fields_hash'}->{lc $_};    
        } else {
            SEARCH: for my $k (sort keys %{ $self->{'fields_hash'} }) {
                if (lc( $k ) eq lc( $_ )) {
                    $index = $self->{'fields_hash'}->{$k};
                    last SEARCH;
                }
            }
        }
        push @indexes, $index;
    }

    my $beg = 0;
    foreach my $end (@{$self->{'body_breaks'}}) {
        my $chunk = ([@{$self->{'rows'}}[$beg..$end]]);
        push @{$self->{'sub_totals'}}, $self->_total_chunk($chunk,\@indexes);
        $beg = $end + 1;
    }

    return $self;
}

sub set_row_colors {
    my ($self,$colors,$myattrib) = @_;

    return $self unless ref $colors eq 'ARRAY';
    return $self unless $#$colors >= 1;

    my $ref = ($myattrib)
         ? { $myattrib => [@$colors] }
         : { style => {background => [@$colors]} }
    ;

    $self->modify(tr => $ref, 'body');

    # maybe that should be global?
    #$self->modify(tr => $ref);

    return $self;
}

sub set_col_colors {
    my ($self,$colors,$myattrib) = @_;

    return $self unless ref $colors eq 'ARRAY';
    return $self unless $#$colors >= 1;

    my $cols = $self->_refinate();

    # trick #1: truncate colors to cols
    $#$colors = $#$cols if $#$colors > $#$cols;

    # trick #2: keep adding colors
    #unless ($#$cols % 2 and $#$colors % 2) {
        my $temp = [@$colors];
        push(@$colors,_rotate($temp)) until $#$colors == $#$cols;
    #}

    my $ref = ($myattrib)
         ? { $myattrib => [@$colors] }
         : { style => {background => [@$colors]} }
    ;

    $self->modify(td => $ref, $_) for @$cols;

    return $self;
}

sub set_group {
    my ($self,$group,$nodup,$value) = @_;
    $self->{'nodup'} = $value || $self->{'null_value'} if $nodup;

    my $index;
    if ($group =~ /^\d+$/) {
        $index = $group;
    } elsif (exists $self->{'fields_hash'}->{$group}) {
        $index = $self->{'fields_hash'}->{$group};    
        $self->{'group'} = $group;
    } elsif (exists $self->{'fields_hash'}->{lc $group}) {
        $index = $self->{'fields_hash'}->{lc $group};    
        $self->{'group'} = lc $group;
    } else {
        SEARCH: for my $k (sort keys %{ $self->{'fields_hash'} }) {
            if (lc( $k ) eq lc( $group )) {
                $index = $self->{'fields_hash'}->{$k};
                $self->{'group'} = $k;
                last SEARCH;
            }
        }
    }

    # initialize the first 'repetition'
    my $rep = $self->{'rows'}->[0]->[$index];

    # loop through the whole rows array, storing
    # the points at which a new group starts
    for my $i (0..$self->get_row_count - 1) {
        my $new = $self->{'rows'}->[$i]->[$index];
        push @{$self->{'body_breaks'}}, $i - 1 unless ($rep eq $new);
        $rep = $new;
    }

    push @{$self->{'body_breaks'}}, $self->get_row_count - 1;

    return $self;
}

sub set_pk {
    my $self = shift;
    my $pk   = shift || 'id';
    $pk = $pk =~ /^\d+$/ ? $self->_lookup_name($pk) || $pk : $pk;
    carp "can't call set_pk(): too late to set primary key" if exists $self->{'rows'};
    $self->{'pk'} = $pk;

    return $self;
}

sub set_null_value {
    my ($self,$value) = @_;
    $self->{'null_value'} = $value;
    return $self;
}

sub get_col_count {
    my ($self) = @_;
    my $count = scalar @{$self->{'fields_arry'}};
    return $count;
}

sub get_row_count {
    my ($self) = @_;
    my $count = scalar @{$self->{'rows'}};
    return $count;
}

sub get_current_row {
    return shift->{'current_row'};
}

sub get_current_col {
    return shift->{'current_col'};
}

sub reset {
    my ($self) = @_;
}

sub add_cols {
    my ($self,$config) = @_;
    $config = [$config] unless ref $config eq 'ARRAY';

    foreach (@$config) {
        next unless ref $_ eq 'HASH';
        my ($name,$data,$pos) = @$_{(qw(name data before))};
        my $max_pos = $self->get_col_count();

        $pos  = $self->_lookup_index(ucfirst $pos || '') || $max_pos unless defined $pos && $pos =~ /^\d+$/;
        $pos  = $max_pos if $pos > $max_pos;
        $data = [$data] unless ref $data eq 'ARRAY';

        splice(@{$self->{'fields_arry'}},$pos,0,$name);
        $self->_reset_fields_hash();
        splice(@$_,$pos,0,_rotate($data)) for (@{$self->{rows}});
    }

    return $self;
}

sub drop_cols {
    my ($self,$cols) = @_;
    $cols = $self->_refinate($cols);

    foreach my $col (@$cols) {
        my $index = delete $self->{'fields_hash'}->{$col};
        splice(@{$self->{'fields_arry'}},$index,1);
        $self->_reset_fields_hash();
        splice(@$_,$index,1) for (@{$self->{'rows'}});
    }

    return $self;
}

###################### DEPRECATED ##################################

sub get_table { 
    carp "get_table() is deprecated. Use output() instead";
    output(@_);
}

sub modify_tag {
    carp "modify_tag() is deprecated. Use modify() instead";
    modify(@_);
}

sub map_col { 
    carp "map_col() is deprecated. Use map_cell() instead";
    map_cell(@_);
}

#################### UNDER THE HOOD ################################

# repeat: it only looks complicated

sub _build_table {
    my ($self)  = @_;
    my $attribs = $self->{'global'}->{'table'};

    my ($head,$body,$foot);
    $head = $self->_build_head;
    $body = $self->{'rows'}   ?  $self->_build_body : '';
    $foot = $self->{'totals'} ?  $self->_build_foot : '';

    # w3c says tfoot comes before tbody ...
    my $cdata = $head . $foot . $body;

    return _tag_it('table', $attribs, $cdata) . $N;
}

sub _build_head {
    my ($self) = @_;
    my ($attribs,$cdata,$caption);
    my $output = '';

    # build the <caption> tag if applicable
    if ($caption = $self->{'global'}->{'caption'}) {
        $attribs = $self->{'global'}->{'caption_attribs'};
        $cdata   = $self->{'encode_cells'} ? $self->_xml_encode($caption) : $caption;
        $output .= $N.$T . _tag_it('caption', $attribs, $cdata);
    }

    # build the <colgroup> tags if applicable
    if ($attribs = $self->{'global'}->{'colgroup'}) {
        $cdata   = $self->_build_head_colgroups();
        $output .= $N.$T . _tag_it('colgroup', $attribs, $cdata);
    }

    # go ahead and stop if they don't want the head
    return "$output\n" if $self->{'no_head'};

    # prepare <tr> tag info
    my $tr_attribs = _merge_attribs(
        $self->{'head'}->{'tr'}, $self->{'global'}->{'tr'}
    );
    my $tr_cdata   = $self->_build_head_row();

    # prepare the <thead> tag info
    $attribs = $self->{'head'}->{'thead'} || $self->{'global'}->{'thead'};
    $cdata   = $N.$T . _tag_it('tr', $tr_attribs, $tr_cdata) . $N.$T;

    # add the <thead> tag to the output
    $output .= $N.$T . _tag_it('thead', $attribs, $cdata) . $N;
}

sub _build_head_colgroups {
    my ($self) = @_;
    my (@cols,$output);

    return unless $self->{'colgroups'};
    return undef unless @cols = @{$self->{'colgroups'}};

    foreach (@cols) {
        $output .= $N.$T.$T . _tag_it('col', $_);
    }
    $output .= $N.$T;

    return $output;
}

sub _build_head_row {
    my ($self) = @_;
    my $output = $N;
    my @copy   = @{$self->{'fields_arry'}};

    foreach my $field (@copy) {
        my $attribs = _merge_attribs(
            $self->{$field}->{'th'}   || $self->{'head'}->{'th'},
            $self->{'global'}->{'th'} || $self->{'head'}->{'th'},
        );

        if (my $sub = $self->{'map_head'}->{$field}) {
            $field = $sub->($field);
        }
        elsif (!$self->{'no_ucfirst'}) {
            $field = ucfirst( lc( $field ) );
        }

        # bug 21761 "Special XML characters should be expressed as entities"
        $field = $self->_xml_encode( $field ) if $self->{'encode_cells'};

        $output .= $T.$T . _tag_it('th', $attribs, $field) . $N;
    }

    return $output . $T;
}

sub _build_body {

    my ($self)   = @_;
    my $beg      = 0;
    my $output;

    # if a group was not set via set_group(), then use the entire 2-d array
    my @indicies = exists $self->{'body_breaks'}
        ? @{$self->{'body_breaks'}}
        : ($self->get_row_count - 1);

    # the skinny here is to grab a slice of the rows, one for each group
    foreach my $end (@indicies) {
        my $body_group = $self->_build_body_group([@{$self->{'rows'}}[$beg..$end]]) || '';
        my $attribs    = $self->{'global'}->{'tbody'} || $self->{'body'}->{'tbody'};
        my $cdata      = $N . $body_group . $T;

        $output .= $T . _tag_it('tbody',$attribs,$cdata) . $N;
        $beg = $end + 1;
    }
    return $output;
}

sub _build_body_group {

    my ($self,$chunk) = @_;
    my ($output,$cdata);
    my $attribs = _merge_attribs(
        $self->{'body'}->{'tr'}, $self->{'global'}->{'tr'}
    );
    my $pk_col = '';

    # build the rows
    for my $i (0..$#$chunk) {
        my @row  = @{$chunk->[$i]};
        $pk_col  = splice(@row,$self->{'pk_index'},1) if defined $self->{'pk_index'};
        $cdata   = $self->_build_body_row(\@row, ($i and $self->{'nodup'} or 0), $pk_col);
        $output .= $T . _tag_it('tr',$attribs,$cdata) . $N;
    }

    # build the subtotal row if applicable
    if (my $subtotals = shift @{$self->{'sub_totals'}}) {
        $cdata   = $self->_build_body_subtotal($subtotals);
        $output .= $T . _tag_it('tr',$attribs,$cdata) . $N;
    }

    return $output;
}

sub _build_body_row {
    my ($self,$row,$nodup,$pk) = @_;

    my $group  = $self->{'group'};
    my $index  = $self->_lookup_index($group) if $group;
    my $output = $N;

    $self->{'current_row'} = $pk;

    for (0..$#$row) {
        my $name    = $self->_lookup_name($_);
        my $attribs = _merge_attribs(
            $self->{$name}->{'td'}    || $self->{'body'}->{'td'}, 
            $self->{'global'}->{'td'} || $self->{'body'}->{'td'},
        );

        # suppress warnings AND keep 0 from becoming &nbsp;
        $row->[$_] = '' unless defined($row->[$_]);

        # bug 21761 "Special XML characters should be expressed as entities"
        $row->[$_] = $self->_xml_encode( $row->[$_] ) if $self->{'encode_cells'};

        my $cdata = ($row->[$_] =~ /^\s+$/) 
            ? $self->{'null_value'}
            : $row->[$_] 
        ;

        $self->{'current_col'} = $name;

        $cdata = ($nodup and $index == $_)
            ? $self->{'nodup'}
            : _map_it($self->{'map_cell'}->{$name},$cdata)
        ;

        $output .= $T.$T . _tag_it('td', $attribs, $cdata) . $N;
    }
    return $output . $T;
}

sub _build_body_subtotal {
    my ($self,$row) = @_;
    my $output = $N;

    return '' unless $row;

    for (0..$#$row) {
        my $name    = $self->_lookup_name($_);
        my $sum     = ($row->[$_]);
        my $attribs = _merge_attribs(
            $self->{$name}->{'th'}    || $self->{'body'}->{'th'},
            $self->{'global'}->{'th'} || $self->{'body'}->{'th'},
        );

        # use sprintf if mask was supplied
        if ($self->{'subtotals_mask'} and defined $sum) {
            $sum = sprintf($self->{'subtotals_mask'},$sum);
        }
        else {
            $sum = (defined $sum) ? $sum : $self->{'null_value'};
        }

        $output .= $T.$T . _tag_it('th', $attribs, $sum) . $N;
    }
    return $output . $T;
}

sub _build_foot {
    my ($self) = @_;

    my $tr_attribs = _merge_attribs(
        # notice that foot is 1st and global 2nd - different than rest
        $self->{'foot'}->{'tr'}, $self->{'global'}->{'tr'}
    );
    my $tr_cdata   = $self->_build_foot_row();

    my $attribs = $self->{'foot'}->{'tfoot'} || $self->{'global'}->{'tfoot'};
    my $cdata   = $N.$T . _tag_it('tr', $tr_attribs, $tr_cdata) . $N.$T;

    return $T . _tag_it('tfoot',$attribs,$cdata) . $N;
}

sub _build_foot_row {
    my ($self) = @_;

    my $output = $N;
    my $row    = $self->{'totals'};

    for (0..$#$row) {
        my $name    = $self->_lookup_name($_);
        my $attribs = _merge_attribs(
            $self->{$name}->{'th'}    || $self->{'foot'}->{'th'},
            $self->{'global'}->{'th'} || $self->{'foot'}->{'th'},
        );
        my $sum     = ($row->[$_]);

        # use sprintf if mask was supplied
        if ($self->{'totals_mask'} and defined $sum) {
            $sum = sprintf($self->{'totals_mask'},$sum)
        }
        else {
            $sum = defined $sum ? $sum : $self->{'null_value'};
        }

        $output .= $T.$T . _tag_it('th', $attribs, $sum) . $N;
    }
    return $output . $T;
}

# builds a tag and it's enclosed data
sub _tag_it {
    my ($name,$attribs,$cdata) = @_;
    my $text = "<\L$name\E";

    # build the attributes if any - skip blank vals
    for my $k (sort keys %{$attribs}) {
        my $v = $attribs->{$k};
        if (ref $v eq 'HASH') {
            $v = join('; ', map { 
                my $attrib = $_;
                my $value  = (ref $v->{$_} eq 'ARRAY') 
                    ? _rotate($v->{$_}) 
                    : $v->{$_};
                join(': ',$attrib,$value||'');
            } sort keys %$v) . ';';
        }
        $v = _rotate($v) if (ref $v eq 'ARRAY');
        $text .= qq| \L$k\E="$v"| unless $v =~ /^$/;
    }
    $text .= (defined $cdata) ? ">$cdata</\L$name\E>" : '/>';
}

# used by map_cell() and map_head()
sub _map_it {
    my ($sub,$datum) = @_;
    return $datum unless $sub;
    return $datum = $sub->($datum);
}

# used by calc_totals() and calc_subtotals()
sub _total_chunk {
    my ($self,$chunk,$indexes) = @_;
    my %totals;

    foreach my $row (@$chunk) {
        foreach (@$indexes) {
            $totals{$_} += $row->[$_] if $row->[$_] =~ /^[-0-9\.]+$/;
        }    
    }

    return [ map { defined $totals{$_} ? $totals{$_} : undef } (0 .. $self->get_col_count() - 1) ];
}

# uses %ESCAPES to convert the '4 Horsemen' of XML
# big thanks to Matt Sergeant 
sub _xml_encode {
    my ($self,$str) = @_;
    $str =~ s/([&<>"])/$ESCAPES{$1}/ge;
    return $str;
}

# returns value of and moves first element to last
sub _rotate {
    my $ref  = shift;
    my $next = shift @$ref;
    push @$ref, $next;
    return $next;
}

# always returns an array ref
sub _refinate {
    my ($self,$ref) = @_;
    $ref = undef if ref($ref) eq 'ARRAY' && scalar( @$ref ) < 1;
    $ref = [@{$self->{'fields_arry'}}] unless defined $ref;
    $ref = [$ref] unless ref $ref eq 'ARRAY';
    return [map {$_ =~ /^\d+$/ ? $self->_lookup_name($_) || $_ : $_} @$ref];
}

sub _merge_attribs {
    my ($hash1,$hash2) = @_;

    return $hash1 unless $hash2;
    return $hash2 unless $hash1;

    return {%$hash2,%$hash1};
}

sub _lookup_name {
    my ($self,$index) = @_;
    return $self->{'fields_arry'}->[$index];
}

sub _lookup_index {
    my ($self,$name) = @_;
    return $self->{'fields_hash'}->{$name};
}

sub _reset_fields_hash {
    my $self = shift;
    my $i    = 0;
    $self->{fields_hash} = { map { $_ => $i++ } @{$self->{fields_arry}} };
}

# assigns a non-DBI supplied data table (2D array ref)
sub _do_black_magic {
    my ($self,$ref,$headers) = @_;
    croak "bad data" unless ref( $ref->[0] ) eq 'ARRAY';
    $self->{'fields_arry'} = $headers ? [@$headers] : [ @{ shift @$ref } ];
    $self->{'fields_hash'} = $self->_reset_fields_hash();
    $self->{'rows'}        = $ref;
}

# disconnect database handle if i created it
sub DESTROY {
    my ($self) = @_;
    unless ($self->{'keep_alive'}) {
        $self->{'dbh'}->disconnect if defined $self->{'dbh'};
    }
}

1;
__END__

=head1 NAME

DBIx::XHTML_Table - SQL query result set to XHTML table.

=head1 SYNOPSIS

  use DBIx::XHTML_Table;

  # database credentials - fill in the blanks
  my ($data_source,$usr,$pass) = ();

  my $table = DBIx::XHTML_Table->new($data_source,$usr,$pass);

  $table->exec_query("
      select foo from bar
      where baz='qux'
      order by foo
  ");

  print $table->output();

  # stackable method calls:
  print DBIx::XHTML_Table
    ->new($data_source,$usr,$pass)
    ->exec_query('select foo,baz from bar')
    ->output();

  # and much more - read on ...

=head1 DESCRIPTION

B<DBIx::XHTML_Table> is a DBI extension that creates an HTML
table from a database query result set. It was created to fill
the gap between fetching data from a database and transforming
that data into a web browser renderable table. DBIx::XHTML_Table is
intended for programmers who want the responsibility of presenting
(decorating) data, easily. This module is meant to be used in situations
where the concern for presentation and logic seperation is overkill.
Providing logic or editable data is beyond the scope of this module,
but it is capable of doing such.

=head1 CODE FREEZE

For the most part, no new functionality will be added to this module.
Only bug fixes and documentation corrections/additions. All new efforts
will be directed towards the rewrite of this distribution, B<DBIx::HTML>.

This distribution features a more flexible interface with fewer methods and
logically named argument parameters. At the core is an HTML attribute generator:

=over 4

=item * L<Tie::Hash::Attribute>

=back

Which is used by an HTML tag generator:

=over 4

=item * L<HTML::AutoTag>

=back

Which is used by an HTML table generator:

=over 4

=item * L<Spreadsheet::HTML>

=back

Which is finally wrapped by a DBI extension:

=over 4

=item * L<DBIx::HTML>

=back

=head1 WEBSITE

More documentation (tutorial, cookbook, FAQ, etc.) can be found at

  http://www.unlocalhost.com/XHTML_Table/

=head1 GITHUB

  https://github.com/jeffa/DBIx-XHTML_Table

=head1 CONSTRUCTOR

=over 4

=item B<style_1>

  $obj_ref = new DBIx::XHTML_Table(@credentials[,$attribs])
 
Note - all optional arguments are denoted inside brackets.

The constructor will simply pass the credentials to the DBI::connect
method - read the DBI documentation as well as the docs for your
corresponding DBI driver module (DBD::Oracle, DBD::Sybase,
DBD::mysql, etc).

  # MySQL example
  my $table = DBIx::XHTML_Table->new(
    'DBI:mysql:database:host',   # datasource
    'user',                      # user name
    'password',                  # user password
  ) or die "couldn't connect to database";

The last argument, $attribs, is an optional hash reference
and should not be confused with the DBI::connect method's
similar 'attributes' hash reference.'

  # valid example for last argument
  my $attribs = {
    table => {
      border      => 1,
      cellspacing => 0,
      rules       => 'groups',
    },
    caption => 'Example',
    td => {
      style => 'text-align: right',
    },
  };

  my $table = DBIx::XHTML_Table->new(
      $data_source,$user,$pass,$attribs
  ) or die "couldn't connect to database";

But it is still experimental and unpleasantly limiting.
The purpose of $table_attribs is to bypass having to
call modify() multiple times. However, if you find
yourself calling modify() more than 4 or 5 times,
then DBIx::XHTML_Table might be the wrong tool. I recommend
HTML::Template or Template-Toolkit, both available at CPAN.

=item B<style_2>

  $obj_ref = new DBIx::XHTML_Table($DBH[,$attribs])

The first style will result in the database handle being created
and destroyed 'behind the scenes'. If you need to keep the database
connection open after the XHTML_Table object is destroyed, then
create one yourself and pass it to the constructor:

  my $dbh = DBI->connect(
    $data_source,$usr,$passwd,
    {RaiseError => 1},
  );

  my $table = DBIx::XHTML_Table->new($dbh);
    # do stuff
  $dbh->disconnect;

You can also use any class that isa() DBI::db object, such
as Apache::DBI or DBIx::Password objects:

  my $dbh   = DBIx::Password->connect($user);
  my $table = DBIx::XHTML_Table->new($dbh);

=item B<style_3>

  $obj_ref = new DBIx::XHTML_Table($rows[,$headers])

The final style allows you to bypass a database altogether if need
be. Simply pass a LoL (list of lists) such as the one passed back
from the DBI method C<selectall_arrayref()>. The first row will be
treated as the table heading. You are responsible for supplying the
column names. Here is one way to create a table after modifying the
result set from a database query:

  my $dbh  = DBI->connect($dsource,$usr,$passwd);
  my $sth = $dbh->prepare('select foo,baz from bar');
  $sth->execute();

  # order is essential here
  my $headers = $sth->{'NAME'};
  my $rows    = $sth->fetchall_arrayref();

  # do something to $rows

  my $table = DBIx::XHTML_Table->new($rows,$headers);

If $headers is not supplied, then the first row from the
first argument will be shifted off and used instead.
While obtaining the data from a database is the entire
point of this module, there is nothing stopping you from
simply hard coding it:

  my $rows = [
     [ qw(Head1 Head2 Head3) ],
     [ qw(foo bar baz)       ],
     [ qw(one two three)     ],
     [ qw(un deux trois)     ]
  ];

  my $table = DBIx::XHTML_Table->new($rows);

And that is why $headers is optional.

=back

=head1 OBJECT METHODS

=over 4

=item B<exec_query>

  $table->exec_query($sql[,$bind_vars])

Pass the query off to the database with hopes that data will be 
returned. The first argument is scalar that contains the SQL
code, the optional second argument can either be a scalar for one
bind variable or an array reference for multiple bind vars:

  $table->exec_query('
      select bar,baz from foo
      where bar = ?
      and   baz = ?
  ',[$foo,$bar]);

exec_query() also accepts a prepared DBI::st handle:

  my $sth = $dbh->prepare('
      select bar,baz from foo
      where bar = ?
      and   baz = ?
  ');

  $table->exec_query($sth,[$foo,$bar]);

Consult the DBI documentation for more details on bind vars.

After the query successfully executes, the results will be
stored interally as a 2-D array. The XHTML table tags will
not be generated until the output() method is invoked.

=item B<output>

  $scalar = $table->output([$attribs])

Renders and returns the XHTML table. The only argument is
an optional hash reference that can contain any combination
of the following keys, set to a true value. Most of the
time you will not want to use this argument, but there are
three times when you will:

  # 1 - do not display a thead section
  print $table->output({ no_head => 1 });

This will cause the thead section to be suppressed, but
not the caption if you set one. The
column foots can be suppressed by not calculating totals, and
the body can be suppressed by an appropriate SQL query. The
caption and colgroup cols can be suppressed by not modifying
them. The column titles are the only section that has to be
specifically 'told' not to generate, and this is where you do that.

  # 2 - do not format the headers with ucfirst
  print $table->output({ no_ucfirst => 1 });

This allows you to bypass the automatic upper casing of the first
word in each of the column names in the table header. If you just
wish to have them displayed as all lower case, then use this
option, if you wish to use some other case, use map_head()

  # 3 - 'squash' the output HTML table
  print $table->output({ no_indent => 1 });

This will result in the output having no text aligning whitespace,
that is no newline(\n) and tab(\t) characters. Useful for squashing
the total number of bytes resulting from large return sets.

You can combine these attributes, but there is no reason to use
no_ucfirst in conjunction with no_head.

Note: versions prior to 0.98 used a two argument form:

  $scalar = $table->output([$sans_title,$sans_whitespace])

You can still use this form to suppress titles and whitespace,
but warnings will be generated.

HTML encoding of table cells is turned off by default, but can
be turned on via:

  $table->{encode_cells} = 1;

=item B<get_table>

  $scalar = $table->get_table([ {attribs} ])

Deprecated - use output() instead.

=item B<modify>

  $table->modify($tag,$attribs[,$cols])

This method will store a 'memo' of what attributes you have assigned
to various tags within the table. When the table is rendered, these
memos will be used to create attributes. The first argument is the
name of the tag you wish to modify the attributes of. You can supply
any tag name you want without fear of halting the program, but the
only tag names that are handled are <table> <caption> <thead> <tfoot>
<tbody> <colgroup> <col> <tr> <th> and <td>. The tag name will be
converted to lowercase, so you can practice safe case insensitivity.

The next argument is a reference to a hash that contains the
attributes you wish to apply to the tag. For example, this
sets the attributes for the <table> tag:

  $table->modify('table',{
     border => '2',
     width  => '100%'
  });

  # a more Perl-ish way
  $table->modify(table => {
     border => 2,
     width  => '100%',
  });

  # you can even specify CSS styles
  $table->modify(td => {
     style => 'color: blue; text-align: center',
  });

  # there is more than one way to do it
  $table->modify(td => {
     style => {
        color        => 'blue',
        'text-align' => 'center',
     }
  });

Each key in the hash ref will be lower-cased, and each value will be 
surrounded in quotes. Note that typos in attribute names will not
be caught by this module. Any attribute can be used, valid XHTML
attributes tend be more effective. And yes, JavaScript works too.

You can even use an array reference as the key values:

  $table->modify(td => {
     bgcolor => [qw(red purple blue green yellow orange)],
  }),

As the table is rendered row by row, column by column, the
elements of the array reference will be 'rotated'
across the <td> tags, causing different effects depending
upon the number of elements supplied and the number of
columns and rows in the table. The following is the preferred
XHTML way with CSS styles:

  $table->modify(th => {
     style => {
        background => ['#cccccc','#aaaaaa'],
     }
  });

See the set_row_color() and set_col_color() methods for more info.

The last argument to modify() is optional and can either be a scalar
representing a single column or area, or an array reference
containing multilple columns or areas. The columns will be
the corresponding names of the columns from the SQL query,
or their anticipated index number, starting at zero.
The areas are one of three values: HEAD, BODY, or FOOT.
The columns and areas you specify are case insensitive.

  # just modify the titles
  $table->modify(th => {
     bgcolor => '#bacaba',
  }, 'head');

  # only <td> tags in column FOO will be set
  $table->modify(td => {
     style => 'text-align: center'
  },'foo');

  # <td> tags for the second and third columns (indexes 1 and 2)
  $table->modify(td => {
     style => 'text-align: right'
  },[1,2]);

You cannot currently mix areas and columns in the same method call.
That is, you cannot set a specific column in the 'head' area,
but not the 'body' area. This _might_ change in the future, but
such specific needs are a symptom of needing a more powerful tool.

As of Version 1.10, multiple calls to modfiy() are inheritable.
For example, if you set an attribute for all <td> tags and set
another attribute for a specific column, that specific column
will inherit both attributes:

  $table->modify(td => {foo => 'bar'});
  $table->modify(td => {baz => 'qux'},'Salary');

In the preceding code, all <td> tags will have the attribute
'foo = "bar"', and the <td> tags for the 'Salary' column will
have the attributes 'foo = "bar"' and 'baz = "qux"'. Should
you not this behavior, you can 'erase' the unwanted attribute
by setting the value of an attribute to the empty string:

  $table->modify(td => {foo => 'bar'});
  $table->modify(td => {foo =>'', baz => 'qux'},'Salary');

Note the use of the empty string and not undef or 0. Setting
the value to undef will work, but will issue a warning if you
have warnings turned on. Setting the value to 0 will set the
value of the attribute to 0, not remove it.

A final caveat is setting the <caption> tag. This one breaks
the signature convention:

  $table->modify(tag => $value, $attrib);

Since there is only one <caption> allowed in an XHTML table,
there is no reason to bind it to a column or an area:

  # with attributes
  $table->modify(
     caption => 'A Table Of Contents',
     { align => 'bottom' }
  );

  # without attributes
  $table->modify(caption => 'A Table Of Contents');

The only tag that cannot be modified by modify() is the <col>
tag. Use add_col_tag() instead.

=item B<modify_tag>

  $table->modify_tag($tag,$attribs[,$cols])

Deprecated, use the easier to type modify() instead.

=item B<add_col_tag>

  $table->add_col_tag($cols)

Add a new <col> tag and attributes. The only argument is reference
to a hash that contains the attributes for this <col> tag. Multiple
<col> tags require multiple calls to this method. The <colgroup> tag
pair will be automatically generated if at least one <col> tag is
added.

Advice: use <col> and <colgroup> tags wisely, don't do this:

  # bad
  for (0..39) {
    $table->add_col_tag({
       foo => 'bar',
    });
  }

When this will suffice:

  # good
  $table->modify(colgroup => {
     span => 40,
     foo  => 'bar',
  });

You should also consider using <col> tags to set the attributes
of <td> and <th> instead of the <td> and <th> tags themselves,
especially if it is for the entire table. Notice the use of the
get_col_count() method in this example to span the entire table:

  $table->add_col_tag({
     span  => $table->get_col_count(),
     style => 'text-align: center',
  });

=item B<map_cell>

  $table->map_cell($subroutine[,$cols])

Map a supplied subroutine to all the <td> tag's cdata for
the specified columns.  The first argument is a reference to a
subroutine. This subroutine should shift off a single scalar at
the beginning, munge it in some fasion, and then return it.
The second argument is the column (scalar) or columns (reference
to a list of scalars) to apply this subroutine to. Example: 

  # uppercase the data in column DEPARTMENT
  $table->map_cell( sub { return uc shift }, 'department');

  # uppercase the data in the fifth column
  $table->map_cell( sub { return uc shift }, 4);

One temptation that needs to be addressed is using this method to
color the cdata inside a <td> tag pair. For example:

  # don't be tempted to do this
  $table->map_cell(sub {
    return qq|<font color="red">| . shift . qq|</font>|;
  }, [qw(first_name last_name)]);

  # when CSS styles will work
  $table->modify(td => {
    style => 'color: red',
  }, [qw(first_name last_name)]);

Note that the get_current_row() and get_current_col()
can be used inside the sub reference. See set_pk() below
for an example.

All columns are used if none are specified, and you can
specify index number(s) as well as name(s).  Also,
exec_query() must be called and data must be returned
from the database prior to calling this method, otherwise
the call back will be ignored and a warning will be generated.
This is true for map_head() as well.

=item B<map_col>

  $table->map_col($subroutine[,$cols])

Deprecated - use map_cell() instead.

=item B<map_head>

  $table->map_head($subroutine[,$cols])

Just like map_cell() except it modifies only column headers, 
i.e. the <th> data located inside the <thead> section. The
immediate application is to change capitalization of the column
headers, which are defaulted to ucfirst:

  $table->map_head(sub { uc shift });

Instead of using map_head() to lower case the column headers,
just specify that you don't want default capitalization with
output():

  $table->output({ no_ucfirst => 1 });

=item B<set_row_colors>

  $table->set_row_colors($colors[,$attrib_name]);

This method will produce horizontal stripes.
This first argument is an array reference that contains
the colors to use. Each row will get a color from the
list - when the last color in the list is reached,
then the rotation will start over at the beginning.
This will continue until all <tr> tags have been
generated. If you don't supply an array reference with
at least 2 colors then this method will return without
telling you.

set_row_colors() by default will use CSS styles to
color the rows.  The optional second argument is a single
scalar that can be used to specify another attribute
instead of the CSS style 'color'. For example, you
could use 'class' or even deprecated HTML attributes
such as 'bgcolor' or 'width'.

This method is just a more convenient way to do the
same thing with the modify() modify.

See http://www.unlocalhost.com/XHTML_Table/cookbook.html#5
for more information on coloring the table.

=item B<set_col_colors>

  $table->set_col_colors($colors[,$attrib_name]);

This method will produce vertical stripes.
The first argument is an array reference to arrays just
like set_row_colors(). 

Unlike set_row_colors()  however, this module is more
than just a convenient way to do the same with the modify() method.
The problem arises when you supply an odd number of
colors for an even number of columns, vice versa, or
both odd. The result will be a checkerboard. Not very
readable for anything except board games. By using
set_col_colors() instead, the result will always be
vertical stripes.

set_col_colors() by default will use CSS styles to
color the rows.  The optional second argument is a single
scalar that can be used to specify another attribute
instead of the CSS style 'color'. For example, you
could use 'class' or even deprecated HTML attributes
such as 'bgcolor' or 'width'.

See http://www.unlocalhost.com/XHTML_Table/cookbook.html#5
for more information on coloring the table.

=item B<set_null_value>

  $table->set_null_value($new_null_value)

Change the default null_value (&nbsp;) to something else.  
Any column that is undefined will have this value 
substituted instead.

=item B<set_pk>

  $table->set_pk([$primary_key]);

This method must be called before exec_query() in order to work!

Note that the single argument to this method, $primary_key, is optional.
If you do not specify a primary key, then 'id' will be used.

This is highly specialized method - the need is when you want to select
the primary key along with the columns you want to display, but you
don't want to display it as well. The value will be accessible via the
get_current_row() method. This is useful as a a callback via the map_cell()
method.  Consider the following:

  $table->map_cell(sub { 
    my $datum = shift;
    my $row   = $table->get_current_row();
    my $col   = $table->get_current_col();
    return qq|<input type="text" name="$row:$col" value="$datum">|;
  });

This will render a "poor man's" spreadsheet, provided that set_pk() was
called with the proper primary key before exec_query() was called.
Now each input has a name that can be split to reveal which row and
column the value belongs to.

Big thanks to Jim Cromie for the idea.

=item B<set_group>

  $table->set_group($column[,$no_dups,$replace_with])

Assign one column as the main column. Every time a new row is
encountered for this column, a <tbody> tag is written. An optional
second argument that contains a defined, non-zero value will cause duplicates
to be permanantly eliminated for this row. An optional third argument
specifies what value to replace for duplicates, default is &nbsp;

  # replace duplicates with the global 'null_value'
  $table->set_group('Branch',1);

  # replace duplicates with a new value
  $table->set_group('Branch',1,'----');
  
  # or in a more Perl-ish way
  $table->set_group('Branch',nodups=>'----');

Don't assign a column that has a different value each row, choose
one that is a super class to the rest of the data, for example,
pick album over song, since an album consists of songs.

So, what's it good for? If you set a group (via the set_group() method)
and supply the following:

  # well, and you are viewing in IE...
  $table->modify(table => {
    cellspacing => 0,
    rules       => 'groups',
  });

then horizontal lines will only appear at the point where the 'grouped' 
rows change. This had to be implemented in the past with <table>'s
inside of <table>'s. Much nicer! Add this for a nice coloring trick:

  # this works with or without setting a group, by the way
  $table->modify(tbody => {
    bgcolor => [qw(insert rotating colors here)],
  });

=item B<calc_totals>

  $table->calc_totals([$cols,$mask])

Computes totals for specified columns. The first argument is the column
or columns to sum, again a scalar or array reference is the requirement.
If $cols is not specified, all columns will be totaled. Non-numbers will
be ignored, negatives and floating points are supported, but you have to
supply an appropriate sprintf mask, which is the optional second argument,
in order for the sum to be correctly formatted. See the sprintf docs
for further details.  

=item B<calc_subtotals>

  $table->calc_subtotals([$cols,$mask])

Computes subtotals for specified columns. It is mandatory that you
first specify a group via set_group() before you call this method.
Each subtotal is tallied from the rows that have the same value
in the column that you specified to be the group. At this point, only
one subtotal row per group can be calculated and displayed. 

=item B<get_col_count>

  $scalar = $table->get_col_count()

Returns the number of columns in the table.

=item B<get_row_count>

  $scalar = $table->get_row_count()

Returns the numbers of body rows in the table.

=item B<get_current_row>

  $scalar = $table->get_current_row()

Returns the value of the primary key for the current row being processed.
This method is only meaningful inside a map_cell() callback; if you access
it otherwise, you will either receive undef or the value of the primary
key of the last row of data.

=item B<get_current_col>

  $scalar = $table->get_current_col()

Returns the name of the column being processed.
This method is only meaningful inside a map_cell() callback; if you access
it otherwise, you will either receive undef or the the name of the last
column specified in your SQL statement.

=item B<add_cols>

   $table->add_cols(
      { header => '', data => [], before => '' }, { ... }, ... 
   );

Going against the philosophy of only select what you need from the database,
this sub allows you to remove whole columns. 'header' is the name of the new
column, you will have to ucfirst yourself. It is up to you to ensure that
that the size of 'data' is the same as the number of rows in the original
data set. 'before' can be an index or the name of the column. For example,
to add a new column to the beginning:

   $table->add_cols({name=>'New', data=>\@rows, before => 0});

add a new column to the end:

   $table->add_cols({name=>'New', data=>\@rows});

or somewhere in the middle:

   $table->add_cols({name=>'New', data=>\@rows}, before => 'age'});

or combine all three into one call:

   $table->add_cols(
      {name=>'Foo', data=>\@rows, before => 0},
      {name=>'Bar', data=>\@rows},
      {name=>'Baz', data=>\@rows}, before => 'Bar'},
   );

=item B<drop_cols>

   $table->drop_cols([qw(foo bar 5)];

Like add_cols, drop_cols goes against said 'philosophy', but it is here for
the sake of TIMTWOTDI. Simply pass it an array ref that contains either the
name or positions of the columns you want to drop.

=item B<new>

Things with the stuff.

=item B<reset>

Stuff with the things.

=back

=head1 TAG REFERENCE

    TAG        CREATION    BELONGS TO AREA
+------------+----------+--------------------+
| <table>    |   auto   |       ----         |
| <caption>  |  manual  |       ----         |
| <colgroup> |   both   |       ----         |
| <col>*     |  manual  |       ----         |
| <thead>    |   auto   |       head         |
| <tbody>    |   auto   |       body         |
| <tfoot>    |   auto   |       foot         |
| <tr>       |   auto   |  head,body,foot    |
| <td>       |   auto   |       body         |
| <th>       |   auto   |  head,body,foot    |
+------------+-------------------------------+

 * All tags use modify() to set attributes
   except <col>, which uses add_col_tag() instead

=head1 BUGS

If you have found a bug, typo, etc. please visit Best Practical Solution's
CPAN bug tracker at http://rt.cpan.org:

E<lt>http://rt.cpan.org/NoAuth/Bugs.html?Dist=DBIx-XHTML_TableE<gt>

or send mail to E<lt>bug-DBIx-XHTML_Table#rt.cpan.orgE<gt>

(you got this far ... you can figure out how to make that
a valid address ... and note that i won't respond to bugs
sent to my personal address any longer)

=head1 ISSUES

=over 4

=item Problems with 'SELECT *'

Users are recommended to avoid 'select *' and instead
specify the names of the columns. Problems have been reported
using 'select *' with SQLServer7 will cause certain 'text' type 
columns not to display. I have not experienced this problem
personally, and tests with Oracle and MySQL show that they are not
affected by this. SQLServer7 users, please help me confirm this. :)

=item Not specifying <body> tag in CGI scripts

I anticipate this module to be used by CGI scripts, and when
writing my own 'throw-away' scripts, I noticed that Netscape 4
will not display a table that contains XHTML tags IF a <body>
tag is NOT found. Be sure and print one out.

=back

=head1 CREDITS

Briac [OeufMayo] PilprE<eacute> for the name.

Mark [extremely] Mills for patches and suggestions.

Jim Cromie for presenting the whole spreadsheet idea.

Stephen Nelson for documentation/code corrections.

Matt Sergeant for DBIx::XML_RDB.

Aaron [trs80] Johnson for convincing me into writing add and drop cols.

Richard Piacentini and Tim Alexander for recommending DBIx::Password and Apache::DBI compatability and Slaven Rezic for recommending using UNIVERSAL::isa().

Perl Monks for the education.

=head1 SEE ALSO 

DBI

=head1 AUTHOR 

Jeff Anderson

=head1 COPYRIGHT

Copyright 2017 Jeff Anderson.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut
