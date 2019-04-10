package Catmandu::MARC;

use Catmandu::Sane;
use Catmandu::Util;
use Catmandu::Exporter::MARC::XML;
use MARC::Spec::Parser;
use List::Util;
use Memoize;
use Carp;
use Moo;

with 'MooX::Singleton';

memoize('compile_marc_path');
memoize('parse_marc_spec');
memoize('_get_index_range');

our $VERSION = '1.251';

sub marc_map {
    my $self      = $_[0];

    # $_[2] : marc_path
    my $context        = ref($_[2]) ?
                            $_[2] :
                            $self->compile_marc_path($_[2], subfield_wildcard => 1);

    confess "invalid marc path" unless $context;

    # $_[1] : data record
    my $record         = $_[1]->{'record'};

    return wantarray ? () : undef unless (defined $record && ref($record) eq 'ARRAY');

    # $_[3] : opts
    my $split          = $_[3]->{'-split'} // 0;
    my $join_char      = $_[3]->{'-join'}  // '';
    my $pluck          = $_[3]->{'-pluck'} // 0;
    my $value_set      = $_[3]->{'-value'} // undef;
    my $nested_arrays  = $_[3]->{'-nested_arrays'} // 0;
    my $append         = $_[3]->{'-force_array'} // undef;

    # Do an implicit split for nested_arrays , except when no-implicit-split is set
    if ($nested_arrays == 1) {
        $split = 1 unless $_[3]->{'-no-implicit-split'};
    }

    my $vals;

    for my $field (@$record) {
        next if (
            ($context->{is_regex_field} == 0 && $field->[0] ne $context->{field} )
            ||
            (defined $context->{ind1} && (!defined $field->[1] || $field->[1] ne $context->{ind1}))
            ||
            (defined $context->{ind2} && (!defined $field->[2] || $field->[2] ne $context->{ind2}))
            ||
            ($context->{is_regex_field} == 1 && $field->[0] !~ $context->{field_regex} )
        );

        my $v;

        if ($value_set) {
            for (my $i = 3; $i < @{$field}; $i += 2) {
                my $subfield_regex = $context->{subfield_regex};
                if ($field->[$i] =~ $subfield_regex) {
                    $v = $value_set;
                    last;
                }
            }
        }
        else {
            $v = [];

            if ($pluck) {
                # Treat the subfield as a hash index
                my $_h = {};
                for (my $i = $context->{start}; $i < @{$field}; $i += 2) {
                    push @{ $_h->{ $field->[$i] } } , $field->[$i + 1];
                }
                my $subfield = $context->{subfield};
                $subfield =~ s{[^a-zA-Z0-9]}{}g;
                for my $c (split('',$subfield)) {
                    my $val = $_h->{$c} // [undef];
                    push @$v , @{ $val } ;
                }
            }
            else {
                for (my $i = $context->{start}; $i < @{$field}; $i += 2) {
                    my $subfield_regex = $context->{subfield_regex};
                    if ($field->[$i] =~ $subfield_regex) {
                        push(@$v, $field->[$i + 1]);
                    }
                }
            }

            if (@$v) {
                if (!$split) {
                    my @defined_values = grep {defined($_)} @$v;
                    $v = join $join_char, @defined_values;
                }

                if (defined(my $off = $context->{from})) {
                    if (ref $v eq 'ARRAY') {
                        my @defined_values = grep {defined($_)} @$v;
                        $v = join $join_char, @defined_values;
                    }
                    my $len = $context->{len};
                    if (length(${v}) > $off) {
                        $v = substr($v, $off, $len);
                    } else {
                        $v = undef;
                    }
                }
            }
            else {
                $v = undef;
            }
        }

        if (defined $v) {
            if ($split) {
                $v = [ $v ] unless (defined($v) && ref($v) eq 'ARRAY');
                if (defined($vals) && ref($vals) eq 'ARRAY') {
                    # With the nested arrays option a split will
                    # always return an array of array of values.
                    # This was the old behavior of Inline marc_map functions
                    if ($nested_arrays == 1) {
                        push @$vals , $v;
                    }
                    else {
                        push @$vals , @$v;
                    }
                }
                else {
                    if ($nested_arrays == 1) {
                        $vals = [$v];
                    }
                    else {
                        $vals = [ @$v ];
                    }
                }
            }
            else {
                push @$vals , $v;
            }
        }
    }

    if ($split && defined $vals) {
        $vals = [ $vals ];
    }
    elsif ($append) {
        # we got a $append
    }
    elsif (defined $vals) {
        $vals = join $join_char , @$vals;
    }
    else {
        # no result
    }

    $vals;
}

sub marc_add {
    my ($self,$data,$marc_path,@subfields) = @_;

    my %subfields  = @subfields;
    my $marc       = $data->{'record'} // [];

    if ($marc_path =~ /^\w{3}$/) {
        my @field = ();
        push @field , $marc_path;
        push @field , $subfields{ind1} // ' ';
        push @field , $subfields{ind2} // ' ';


        for (my $i = 0 ; $i < @subfields ; $i += 2) {
            my $code  = $subfields[$i];
            next unless length $code == 1;
            my $value = $subfields[$i+1];

            if ($value =~ /^\$\.(\S+)$/) {
                my $path = $1;
                $value = Catmandu::Util::data_at($path,$data);
            }

            if (Catmandu::Util::is_array_ref $value) {
                for (@$value) {
                    push @field , $code;
                    push @field , $_;
                }
            }
            elsif (Catmandu::Util::is_hash_ref $value) {
                for (keys %$value) {
                    push @field , $code;
                    push @field , $value->{$_};
                }
            }
            elsif (Catmandu::Util::is_value($value) && length($value) > 0) {
                push @field , $code;
                push @field , $value;
            }
        }

        push @{ $marc } , \@field if @field > 3;
    }

    $data->{'record'} = $marc;

    $data;
}

sub marc_append {
    my ($self,$data,$marc_path,$value) = @_;
    my $record = $data->{'record'};

    return $data unless defined $record;

    if ($value =~ /^\$\.(\S+)/) {
        my $path = $1;
        $value = Catmandu::Util::data_at($path,$data);
    }

    if (Catmandu::Util::is_array_ref $value) {
        $value = $value->[-1];
    }
    elsif (Catmandu::Util::is_hash_ref $value) {
        my $last;
        for (keys %$value) {
            $last = $value->{$_};
        }
        $value = $last;
    }

    my $context = $self->compile_marc_path($marc_path);

    confess "invalid marc path" unless $context;

    for my $field (@$record) {
        my ($tag, $ind1, $ind2, @subfields) = @$field;

        if ($context->{is_regex_field}) {
            next unless $tag =~ $context->{field_regex};
        }
        else {
            next unless $tag eq $context->{field};
        }

        if (defined $context->{ind1}) {
            if (!defined $ind1 || $ind1 ne $context->{ind1}) {
                next;
            }
        }
        if (defined $context->{ind2}) {
            if (!defined $ind2 || $ind2 ne $context->{ind2}) {
                next;
            }
        }

        if ($context->{subfield}) {
            for (my $i = 0; $i < @subfields; $i += 2) {
                if ($subfields[$i] =~ $context->{subfield}) {
                    $field->[$i + 4] .= $value;
                }
            }
        }
        else {
            $field->[-1] .= $value;
        }
    }

    $data;
}

sub marc_replace_all {
    my ($self,$data,$marc_path,$regex,$value) = @_;
    my $record = $data->{'record'};

    return $data unless defined $record;

    if ($value =~ /^\$\.(\S+)/) {
        my $path = $1;
        $value = Catmandu::Util::data_at($path,$data);
    }

    if (Catmandu::Util::is_array_ref $value) {
        $value = $value->[-1];
    }
    elsif (Catmandu::Util::is_hash_ref $value) {
        my $last;
        for (keys %$value) {
            $last = $value->{$_};
        }
        $value = $last;
    }

    my $context = $self->compile_marc_path($marc_path, subfield_wildcard => 1);

    confess "invalid marc path" unless $context;

    for my $field (@$record) {
        my ($tag, $ind1, $ind2, @subfields) = @$field;

        if ($context->{is_regex_field}) {
            next unless $tag =~ $context->{field_regex};
        }
        else {
            next unless $tag eq $context->{field};
        }

        if (defined $context->{ind1}) {
            if (!defined $ind1 || $ind1 ne $context->{ind1}) {
                next;
            }
        }
        if (defined $context->{ind2}) {
            if (!defined $ind2 || $ind2 ne $context->{ind2}) {
                next;
            }
        }

        for (my $i = 0; $i < @subfields; $i += 2) {
            if ($subfields[$i] =~ $context->{subfield}) {
                # Trick to double eval the right hand side
                $field->[$i + 4] =~ s{$regex}{"\"$value\""}eeg;
            }
        }
    }

    $data;
}

sub marc_set {
    my ($self,$data,$marc_path,$value,%opts) = @_;
    my $record = $data->{'record'};

    return $data unless defined $record;

    if ($value =~ /^\$\.(\S+)/) {
        my $path = $1;
        $value = Catmandu::Util::data_at($path,$data);
    }

    if (Catmandu::Util::is_array_ref $value) {
        $value = $value->[-1];
    }
    elsif (Catmandu::Util::is_hash_ref $value) {
        my $last;
        for (keys %$value) {
            $last = $value->{$_};
        }
        $value = $last;
    }

    my $context = $self->compile_marc_path($marc_path, subfield_default => 1);

    confess "invalid marc path" unless $context;

    for my $field (@$record) {
        my ($tag, $ind1, $ind2, @subfields) = @$field;

        if ($context->{is_regex_field}) {
            next unless $tag =~ $context->{field_regex};
        }
        else {
            next unless $tag eq $context->{field};
        }

        if (defined $context->{ind1}) {
            if (!defined $ind1 || $ind1 ne $context->{ind1}) {
                next;
            }
        }
        if (defined $context->{ind2}) {
            if (!defined $ind2 || $ind2 ne $context->{ind2}) {
                next;
            }
        }

        my $found = 0;
        for (my $i = 0; $i < @subfields; $i += 2) {
            if ($subfields[$i] =~ $context->{subfield}) {
                if (defined $context->{from}) {
                    substr($field->[$i + 4], $context->{from}, $context->{len}) = $value;
                }
                else {
                    $field->[$i + 4] = $value;
                }
                $found = 1;
            }
        }

        if ($found == 0) {
            push(@$field,$context->{subfield},$value);
        }
    }

    $data;
}

sub marc_remove {
    my ($self,$data, $marc_path,%opts) = @_;
    my $record = $data->{'record'};

    my $new_record;

    my $context = $self->compile_marc_path($marc_path);

    confess "invalid marc path" unless $context;

    for my $field (@$record) {
        my $field_size = int(@$field);

        if (
            ($context->{is_regex_field} == 0 && $field->[0] eq $context->{field})
            ||
            ($context->{is_regex_field} == 1 && $field->[0] =~ $context->{field_regex})
            ) {

            my $ind_match = undef;

            if (defined $context->{ind1} && defined $context->{ind2}) {
                $ind_match = 1 if (defined $field->[1] && $field->[1] eq $context->{ind1} &&
                                   defined $field->[2] && $field->[2] eq $context->{ind2});
            }
            elsif (defined $context->{ind1}) {
                $ind_match = 1 if (defined $field->[1] && $field->[1] eq $context->{ind1});
            }
            elsif (defined $context->{ind2}) {
                $ind_match = 1 if (defined $field->[2] && $field->[2] eq $context->{ind2});
            }
            else {
                $ind_match = 1;
            }

            if ($ind_match && ! defined $context->{subfield_regex}) {
                next;
            }

            if (defined $context->{subfield_regex}) {
                my $subfield_regex = $context->{subfield_regex};
                my $new_subf = [];
                for (my $i = $context->{start}; $i < $field_size; $i += 2) {
                    unless ($field->[$i] =~ $subfield_regex) {
                        push @$new_subf , $field->[$i];
                        push @$new_subf , $field->[$i+1];
                    }
                }

                splice @$field , $context->{start} , int(@$field), @$new_subf if $ind_match;
            }
        }

        push @$new_record , $field;
    }

    $data->{'record'} = $new_record;

    return $data;
}

sub marc_spec {
    my $self      = $_[0];

    # $_[1] : data record
    my $data      = $_[1];
    my $record    = $data->{'record'};

    # $_[2] : spec
    my ($ms, $spec);
    if( ref $_[2] ) {
        $ms       = $_[2];
        $spec     = $ms->to_string()
    } else {
        $ms       = $self->parse_marc_spec( $_[2] ); # memoized
        $spec     = $_[2];
    }

    my $EMPTY = q{};
    # $_[3] : opts
    my $split         = $_[3]->{'-split'} // 0;
    my $join_char     = $_[3]->{'-join'}  // $EMPTY;
    my $pluck         = $_[3]->{'-pluck'} // 0;
    my $value_set     = $_[3]->{'-value'} // undef;
    my $invert        = $_[3]->{'-invert'} // 0;
    my $nested_arrays = $_[3]->{'-nested_arrays'} // 0;
    my $append        = $_[3]->{'-force_array'} // 0;

    if ($nested_arrays) {
        $split = 1
    }

    # filter by tag
    my @fields     = ();
    my $field_spec = $ms->field;
    my $tag_spec   = $field_spec->tag;

    @fields = grep { $_->[0] =~ /$tag_spec/ } @{ $record };
    return unless @fields;

    # calculate char start
    my $chst = sub {
        my ($sp) = @_;
        my $char_start;
        if ( $sp->has_char_start ) {
            $char_start = ( '#' eq $sp->char_start )
              ? $sp->char_length * -1
              : $sp->char_start;
        }
        return $char_start;
    };

    # vars we need only for subfields
    my (@sf_spec, $invert_level, $codes, $invert_chars);
    if ( $ms->has_subfields ) {
        # set the order of subfields
        @sf_spec = map { $_ } @{ $ms->subfields };
        unless ( $pluck ) {
            @sf_spec = sort { $a->code cmp $b->code } @sf_spec;
        }

        # set invert level default
        $invert_level = 4;
        if ( $invert ) {
            $codes  = '[^';
            $codes .= join $EMPTY, map { $_->code } @sf_spec;
            $codes .= ']';
        }

        $invert_chars = sub {
            my ( $str, $start, $length ) = @_;
            for ( substr $str, $start, $length ) {
                $_ = $EMPTY;
            }
            return $str;
        };
    }
    else {
        # return $value_set ASAP
        return $value_set if defined $value_set;
    }

    # vars we need for fields and subfields
    my ($referred, $char_start, $prev_tag, $index_range);
    my $current_tag = $EMPTY;
    my $tag_index = 0;
    my $index_start = $field_spec->index_start;
    my $index_end   = $field_spec->index_end;

    my $to_referred = sub {
        my ( @values ) = @_;
        if($nested_arrays) {
            push @{$referred}, \@values;
        } elsif($split) {
            push @{$referred}, @values;
        } else {
            push @{$referred}, join $join_char, @values;
        }
    };

    if(  defined $field_spec->index_start ) {
        $index_range =
          _get_index_range( $field_spec->index_start, $field_spec->index_end, $#fields );
    }

    # iterate over fields
    for my $field (@fields) {
        $prev_tag    = $current_tag;
        $current_tag = $field->[0];

        $tag_index   = ( $prev_tag eq $current_tag and defined $tag_index)
            ? ++$tag_index
            : 0; #: $field_spec->index_start;

        # filter by index
        if ( defined $index_range ) {
            next unless ( Catmandu::Util::array_includes( $index_range, $tag_index ) );
        }

        # filter field by subspec
        if( $field_spec->has_subspecs) {
            my $valid = $self->_it_subspecs( $data, $current_tag, $field_spec->subspecs, $tag_index );
            next unless $valid;
        }

        my @subfields = ();

        if ( $ms->has_subfields ) {    # now we dealing with subfields
            for my $sf (@sf_spec) {
                # set invert level
                if ( $invert && !$sf->has_subspecs) {
                    if ( -1 == $sf->index_length && !$sf->has_char_start ) {
                        next if ( $invert_level == 3 );    # skip subfield spec it's already covered
                        $invert_level = 3;
                    }
                    elsif ( $sf->has_char_start ) {
                        $invert_level = 1;
                    }
                    else {
                        $invert_level = 2;
                    }
                }

                my @subfield = ();
                my $code     = ( $invert_level == 3 ) ? $codes : $sf->code;
                $code        = qr/$code/;
                for ( my $i = 3 ; $i < @{$field} ; $i += 2 ) {
                    if ( $field->[$i] =~ /$code/ ) {
                        push @subfield, $field->[ $i + 1 ];
                    }
                }

                if ( $invert_level == 3 ) { # no index or charpos
                    if (@subfield) {
                        push @subfields, @subfield;
                    }

                    if ( $referred && $value_set ) { # return $value_set ASAP
                        return $value_set;
                    }

                    next;
                }

                next unless (@subfield);

                # filter by index
                if ( defined $sf->index_start ) {
                    my $sf_range =
                        _get_index_range( $sf->index_start, $sf->index_end, $#subfield );

                    if ( $invert_level == 2 ) {    # inverted
                        @subfield = map {
                            Catmandu::Util::array_includes( $sf_range, $_ )
                              ? ()
                              : $subfield[$_];
                        } 0 .. $#subfield;
                    }
                    else {    # without invert
                        @subfield =
                          map {
                            defined $subfield[$_]
                            ? $subfield[$_]
                            : ();
                        } @{$sf_range};
                    }
                    next unless (@subfield);
                }

                # return $value_set ASAP
                return $value_set if $value_set;

                # filter subfield by subspec
                if( $sf->has_subspecs) {
                    my $valid = $self->_it_subspecs( $data, $field_spec->tag, $sf->subspecs, $tag_index);
                    next unless $valid;
                }

                # get substring
                $char_start = $chst->($sf);
                if ( defined $char_start ) {
                    if ( $invert_level == 1 ) {    # inverted
                        @subfield =
                          map {
                            $invert_chars->( $_, $char_start, $sf->char_length );
                        } @subfield;
                    }
                    else {
                        @subfield =
                          map {
                            substr $_, $char_start, $sf->char_length;
                        } @subfield;
                    }
                }
                next unless @subfield;
                push @subfields, @subfield;
            } # end of subfield iteration
            $to_referred->(@subfields) if @subfields;
        } # end of subfield handling
        elsif($ms->has_indicator){
            # filter field by subspec
            if( $ms->indicator->has_subspecs) {
                my $valid = $self->_it_subspecs( $data, $current_tag, $ms->indicator->subspecs, $tag_index );
                next unless $valid;
            }
            my @indicators = ();
            push @indicators, $field->[$ms->indicator->position]
                if defined $field->[$ms->indicator->position];
            $to_referred->(@indicators);
        }
        else { # no particular subfields requested
            my @contents = ();
            for ( my $i = 4 ; $i < @{$field} ; $i += 2 ) {
                # get substring
                $char_start    = $chst->($field_spec);
                my $content    = ( defined $char_start )
                    ? substr $field->[$i], $char_start, $field_spec->char_length
                    : $field->[$i];
                push @contents, $content;
            }
            next unless (@contents);
            $to_referred->(@contents);
        } # end of field handling
    } # end of field iteration
    return unless ($referred);

    if ($append) {
        return [$referred] if $split;
        return $referred;
    } elsif ($split) {
        return [$referred];
    }

    return join $join_char, @{$referred};
}

sub _it_subspecs {
    my ( $self, $data, $tag, $subspecs, $tag_index ) = @_;

    my $set_index = sub {
        my ( $subspec ) = @_;
        foreach my $side ( ('left', 'right') ) {
            next if ( ref $subspec->$side eq 'MARC::Spec::Comparisonstring' );
            # only set new index if subspec field tag equals spec field tag!!
            my $spec_tag = $subspec->$side->field->tag;
            next unless ( $tag =~ /$spec_tag/ );
            $subspec->$side->field->set_index_start_end( $tag_index );
        }
    };

    my $valid = 1;
    foreach my $subspec ( @{$subspecs} ) {
        if( ref $subspec eq 'ARRAY' ) { # chained subSpecs (OR)
            foreach my $or_subspec ( @{$subspec} ) {
                $set_index->( $or_subspec );
                $valid = $self->_validate_subspec( $or_subspec, $data, $tag );
                # at least one of them is true (OR)
                last if $valid;
            }
        }
        else { # repeated SubSpecs (AND)
            $set_index->( $subspec );
            $valid = $self->_validate_subspec( $subspec, $data, $tag );
            # all of them have to be true (AND)
            last unless $valid;
        }
    }
    return $valid;
}

sub _validate_subspec {
    my ( $self, $subspec, $data, $tag ) = @_;
    my ($left_subterm, $right_subterm);

    if('!' ne $subspec->operator && '?' ne $subspec->operator) {
        if ( ref $subspec->left ne 'MARC::Spec::Comparisonstring' ) {
            my $new_spec = $subspec->left->to_string();
            $new_spec =~ s/^\.\.\./$tag/;
            $left_subterm = $self->marc_spec(
                    $data,
                    $new_spec,
                    { '-split' => 1 }
                ); # split should result in an array ref
            return 0 unless defined $left_subterm;
        }
        else {
            push @{$left_subterm}, $subspec->left->comparable;
        }
    }

    if ( ref $subspec->right ne 'MARC::Spec::Comparisonstring' ) {
        my $new_spec = $subspec->right->to_string();
        $new_spec =~ s/^\.\.\./$tag/;
        $right_subterm = $self->marc_spec(
                $data,
                $new_spec,
                { '-split' => 1 }
            ); # split should result in an array ref
        unless( defined $right_subterm ) {
            $right_subterm = [];
        }
    }
    else {
        push @{$right_subterm}, $subspec->right->comparable;
    }

    if($subspec->operator eq '?') {
        return (@{$right_subterm}) ? 1 : 0;
    }

    if($subspec->operator eq '!') {
        return (@{$right_subterm}) ? 0 : 1;
    }

    if($subspec->operator eq '=') {
        foreach my $v ( @{$left_subterm->[0]} ) {
            return 1 if List::Util::any {$v eq $_} @{$right_subterm};
        }
    }

    if($subspec->operator eq '!=') {
        foreach my $v ( @{$left_subterm->[0]} ) {
            return 0 if List::Util::any {$v eq $_} @{$right_subterm};
        }
        return 1;
    }

    if($subspec->operator eq '~') {
        foreach my $v ( @{$left_subterm->[0]} ) {
            return 1 if List::Util::any {$v =~ /$_/} @{$right_subterm};
        }
    }

    if($subspec->operator eq '!~') {
        foreach my $v ( @{$left_subterm->[0]} ) {
            return 0 if List::Util::any {$v =~ /$_/} @{$right_subterm};
        }
        return 1;
    }

    return 0;
}

sub parse_marc_spec {
    my ( $self, $marc_spec ) = @_;
    return MARC::Spec::Parser->new( $marc_spec )->marcspec;
}

sub _get_index_range {
    my ( $index_start, $index_end, $last_index ) = @_;

    if ( '#' eq $index_start ) {
        if ( '#' eq $index_end or 0 == $index_end ) { return [$last_index]; }
        $index_start = $last_index;
        $index_end   = $last_index - $index_end;
        if ( 0 > $index_end ) { $index_end = 0; }
    }
    else {
        if ( $last_index < $index_start ) {
            return [$index_start];
        }    # this will result to no hits
    }

    if ( '#' eq $index_end or $index_end > $last_index ) {
        $index_end = $last_index;
    }

    return ( $index_start <= $index_end )
      ? [ $index_start .. $index_end ]
      : [ $index_end .. $index_start ];
}

sub marc_xml {
    my ($self,$data,%opts) = @_;

    if ($opts{reverse}) {
        my $record = Catmandu->import_from_string($data,'MARC', type=>'XML');
        return $record->[0]->{record} if $record;
        return undef;
    }
    else {
        my $xml;
        my $exporter = Catmandu::Exporter::MARC::XML->new(file => \$xml , xml_declaration => 0 , collection => 0);
        $exporter->add({record => $data});
        $exporter->commit;

        return $xml;
    }
}

sub marc_record_to_json {
    my ($self,$data,%opts) = @_;

    if (my $marc = delete $data->{'record'}) {
        for my $field (@$marc) {
            my ($tag, $ind1, $ind2, @subfields) = @$field;

            if ($tag eq 'LDR') {
               shift @subfields;
               $data->{leader} = join "", @subfields;
            }
            elsif ($tag eq 'FMT' || substr($tag, 0, 2) eq '00') {
               shift @subfields;
               push @{$data->{fields} ||= []} , { $tag => join "" , @subfields };
            }
            else {
               my @sf;
               my $start = !defined($subfields[0]) || $subfields[0] eq '_' ? 2 : 0;
               for (my $i = $start; $i < @subfields; $i += 2) {
                   push @sf, { $subfields[$i] => $subfields[$i+1] };
               }
               push @{$data->{fields} ||= []} , { $tag => {
                   subfields => \@sf,
                   ind1 => $ind1,
                   ind2 => $ind2 } };
            }
        }
    }

    $data;
}

sub marc_json_to_record {
    my ($self,$data,%opts) = @_;

    my $record = [];

    if (Catmandu::Util::is_string($data->{leader})) {
        push @$record , [ 'LDR', undef, undef, '_', $data->{leader} ],
    }

    if (Catmandu::Util::is_array_ref($data->{fields})) {
        for my $field (@{$data->{fields}}) {
            next unless Catmandu::Util::is_hash_ref($field);

            my ($tag) = keys %$field;
            my $val   = $field->{$tag};

            if ($tag eq 'FMT' || substr($tag, 0, 2) eq '00') {
               push @$record , [ $tag, undef, undef, '_', $val ],
            }
            elsif (Catmandu::Util::is_hash_ref($val)) {
               my $ind1 = $val->{ind1};
               my $ind2 = $val->{ind2};
               next unless Catmandu::Util::is_array_ref($val->{subfields});

               my $sfs = [ '_' , ''];
               for my $sf (@{ $val->{subfields} }) {
                   next unless Catmandu::Util::is_hash_ref($sf);

                   my ($code) = keys %$sf;
                   my $sval   = $sf->{$code};

                   push @$sfs , [ $code , $sval];
               }

               push @$record , [ $tag , $ind1 , $ind2 , @$sfs];
            }
        }
    }

    if (@$record > 0) {
      delete $data->{fields};
      delete $data->{leader};
      $data->{'record'} = $record;
    }

    $data;
}

sub marc_decode_dollar_subfields {
    my ($self,$data,%opts) = @_;
    my $old_record = $data->{'record'};
    my $new_record = [];

    for my $field (@$old_record) {
        my ($tag,$ind1,$ind2,@subfields) = @$field;

        my $fixed_field = [$tag,$ind1,$ind2];

        for (my $i = 0 ; $i < @subfields ; $i += 2) {
            my $code  = $subfields[$i];
            my $value = $subfields[$i+1];

            # If a subfield contains fields coded like: data$xmore$yevenmore
            # chunks = (data,x,y,evenmore)
            my @chunks = split( /\$([a-z])/, $value );

            my $real_value = shift @chunks;

            push @$fixed_field , ( $code, $real_value);

            while (@chunks) {
                push  @$fixed_field , ( splice @chunks, 0, 2 );
            }
        }

        push @$new_record , $fixed_field;
    }

    $data->{'record'} = $new_record;

    $data;
}

sub compile_marc_path {
    my ($self,$marc_path,%opts) = @_;

    my ($field,$field_regex,$ind1,$ind2,
        $subfield,$subfield_regex,$from,$to,$len,$is_regex_field);

    my $MARC_PATH_REGEX = qr/(\S{1,3})(\[([^,])?,?([^,])?\])?([\$_a-z0-9^-]+)?(\/([0-9]+)(-([0-9]+))?)?/;
    if ($marc_path =~ $MARC_PATH_REGEX) {
        $field          = $1;
        $ind1           = $3;
        $ind2           = $4;
        $subfield       = $5;
        $field = "0" x (3 - length($field)) . $field; # fixing 020 treated as 20 bug
        if (defined($subfield)) {
            $subfield =~ s{\$}{}g;
            unless ($subfield =~ /^[a-zA-Z0-9]$/) {
                $subfield = "[$subfield]";
            }
        }
        elsif ($opts{subfield_default}) {
            $subfield = $field =~ /^0|LDR|FMT/ ? '_' : 'a';
        }
        elsif ($opts{subfield_wildcard}) {
            $subfield = '[a-z0-9_]';
        }
        if (defined($subfield)) {
            $subfield_regex = qr/^(?:${subfield})$/;
        }
        $from           = $7;
        $to             = $9;
        $len = defined $to ? $to - $from + 1 : 1;
    }
    else {
        return undef;
    }

    if ($field =~ /[\*\.]/) {
        $field_regex    = $field;
        $field_regex    =~ s/[\*\.]/(?:[A-Z0-9])/g;
        $is_regex_field = 1;
        $field_regex    = qr/^$field_regex$/;
    }
    else {
        $is_regex_field = 0;
    }

    return {
        field           => $field ,
        field_regex     => $field_regex ,
        is_regex_field  => $is_regex_field ,
        subfield        => $subfield ,
        subfield_regex  => $subfield_regex ,
        ind1            => $ind1 ,
        ind2            => $ind2 ,
        start           => 3,
        from            => $from ,
        to              => $to ,
        len             => $len
    };
}

sub marc_copy {
    my $self       = $_[0];
    my $data       = $_[1];
    my $marc_path  = $_[2];
    my $marc_value = $_[3];
    my $is_cut     = $_[4];

    # $_[2] : marc_path
    my $context = ref($marc_path) ? $marc_path : $self->compile_marc_path($_[2], subfield_wildcard => 0);

    confess "invalid marc path" unless $context;

    # $_[1] : data record
    my $record         = $data->{'record'};

    return wantarray ? () : undef unless (defined $record && ref($record) eq 'ARRAY');

    # When is_cut is on, we need to create a new record containing the remaining fields
    my @new_record = ();

    my $fields = [];

    for my $field (@$record) {
        my ($tag, $ind1, $ind2, @subfields) = @$field;

        if (
            ($context->{is_regex_field} == 0 && $tag ne $context->{field} )
            ||
            ($context->{is_regex_field} == 1 && $tag !~ $context->{field_regex} )
        ) {
            push @new_record , $field if $is_cut;
            next;
        }

        if (defined $context->{ind1}) {
            if (!defined $ind1 || $ind1 ne $context->{ind1}) {
                push @new_record , $field if $is_cut;
                next;
            }
        }
        if (defined $context->{ind2}) {
            if (!defined $ind2 || $ind2 ne $context->{ind2}) {
                push @new_record , $field if $is_cut;
                next;
            }
        }

        if ($context->{subfield}) {
            my $found = 0;
            for (my $i = 0; $i < @subfields; $i += 2) {
                if ($subfields[$i] =~ $context->{subfield}) {
                    if (defined($marc_value)) {
                        $found = 1 if $subfields[$i+1] =~ /$marc_value/;
                    }
                    else {
                        $found = 1;
                    }
                }
            }

            unless ($found) {
                push @new_record , $field if $is_cut;
                next;
            }
        }
        else {
            if (defined($marc_value)) {
                my @sf = ();
                for (my $i = 0; $i < @subfields; $i += 2) {
                    push @sf , $subfields[$i+1];
                }

                my $string = join "", @sf;

                unless ($string =~ /$marc_value/) {
                    push @new_record , $field if $is_cut;
                    next;
                }
            }
        }

        my $f = {};
        $f->{tag} = $field->[0];

        # indicator 1
        if(defined $field->[1]) {
            $f->{ind1} = $field->[1];
        } else {
            $f->{ind1} = undef;
        }

        # indicator 2
        if(defined $field->[2]) {
            $f->{ind2} = $field->[2];
        } else {
            $f->{ind2} = undef;
        }

        # fixed fields
        if($field->[3] eq '_') {
            $f->{content} = $field->[4];
            push(@$fields, $f);
            next;
        }

        # subfields
        for (my $i = $context->{start}; $i < @{$field}; $i += 2) {
            push(@{$f->{subfields}}, { $field->[$i] => $field->[$i + 1] });
        }

        push(@$fields, $f);
    }

    if ($is_cut) {
        $data->{record} = \@new_record;
    }

    [$fields];
}

sub marc_paste {
    my $self       = $_[0];
    my $data       = $_[1];
    my $json_path  = $_[2];
    my $marc_path  = $_[3];
    my $marc_value = $_[4];

    my $value = Catmandu::Util::data_at($json_path,$data);

    return $data unless Catmandu::Util::is_array_ref($value) || Catmandu::Util::is_hash_ref($value);

    $value = [$value] unless Catmandu::Util::is_array_ref($value);

    my @new_parts;

    for my $part (@$value) {
        return $data unless
                    Catmandu::Util::is_hash_ref($part) &&
                    exists $part->{tag}  &&
                    exists $part->{ind1} &&
                    exists $part->{ind2} &&
                    ( exists $part->{content} || exists $part->{subfields} );

        my $tag       = $part->{tag};
        my $ind1      = $part->{ind1} // ' ';
        my $ind2      = $part->{ind2} // ' ';
        my $content   = $part->{content};
        my $subfields = $part->{subfields};

        if (defined($content)) {
            push @new_parts , [ $tag , $ind1 , $ind2 , '_' , $content ];
        }
        elsif (defined($subfields) && Catmandu::Util::is_array_ref($subfields)) {
            my @tmp = ( $tag , $ind1 , $ind2 );

            for my $sf (@$subfields) {
                while (my ($key, $value) = each %$sf) {
                    push @tmp, $key , $value;
                }
            }

            push @new_parts , [ @tmp ];
        }
        else {
            # Illegal input
            return $data;
        }
    }

    if (defined($marc_path)) {
        my $context = $self->compile_marc_path($marc_path, subfield_wildcard => 0);

        confess "invalid marc path" unless $context;

        my @record      = @{$data->{record}};
        my $found_match = undef;

        my $field_position = -1;

        for my $field (@record) {
            $field_position++;
            my ($tag, $ind1, $ind2, @subfields) = @$field;

            if ($context->{is_regex_field}) {
                next unless $tag =~ $context->{field_regex};
            }
            else {
                next unless $tag eq $context->{field};
            }

            if (defined $context->{ind1}) {
                if (!defined $ind1 || $ind1 ne $context->{ind1}) {
                    next;
                }
            }
            if (defined $context->{ind2}) {
                if (!defined $ind2 || $ind2 ne $context->{ind2}) {
                    next;
                }
            }

            if ($context->{subfield}) {
                for (my $i = 0; $i < @subfields; $i += 2) {
                    if ($subfields[$i] =~ $context->{subfield}) {
                        if (defined($marc_value)) {
                            $found_match = $field_position if $subfields[$i+1] =~ /$marc_value/;
                        }
                        else {
                            $found_match = $field_position;
                        }
                    }
                }
            } else {
                if (defined($marc_value)) {
                    my @sf = ();
                    for (my $i = 0; $i < @subfields; $i += 2) {
                        push @sf , $subfields[$i+1];
                    }

                    my $string = join "", @sf;

                    if ($string =~ /$marc_value/) {
                        $found_match = $field_position;
                    }
                    else {
                        # don't match anything
                    }
                }
                else {
                    $found_match = $field_position;
                }
            }
        }

        if (defined $found_match) {
            my @new_record = (
                @record[0..$found_match] ,
                @new_parts ,
                @record[$found_match+1..$#record]
            );
            $data->{record} = \@new_record;
        }
    }
    else {
        push @{$data->{record}} , @new_parts;
    }

    $data;
}

1;

__END__

=head1 NAME

Catmandu::MARC - Catmandu modules for working with MARC data

=begin markdown

# STATUS

[![Build Status](https://travis-ci.org/LibreCat/Catmandu-MARC.svg?branch=master)](https://travis-ci.org/LibreCat/Catmandu-MARC)
[![Coverage](https://coveralls.io/repos/LibreCat/Catmandu-MARC/badge.png?branch=master)](https://coveralls.io/r/LibreCat/Catmandu-MARC)
[![CPANTS kwalitee](http://cpants.cpanauthors.org/dist/Catmandu-MARC.png)](http://cpants.cpanauthors.org/dist/Catmandu-MARC)

=end markdown

=head1 SYNOPSIS

 # On the command line

 $ catmandu convert MARC to JSON < data.mrc

 $ catmandu convert MARC --type MiJ to YAML < data.marc_in_json

 $ catmandu convert MARC --fix "marc_map(245,title)" < data.mrc

 $ catmandu convert MARC --fix myfixes.txt < data.mrc

 myfixes:

 marc_map("245a", title)
 marc_map("5**", note.$append)
 marc_map('710','my.authors.$append')
 marc_map('008_/35-35','my.language')
 remove_field(record)
 add_field(my.funny.field,'test123')

 $ catmandu import MARC --fix myfixes.txt to ElasticSearch --index_name 'catmandu' < data.marc

 # In perl
 use Catmandu;

 my $importer = Catmandu->importer('MARC', file => 'data.mrc' );
 my $fixer    = Catmandu->fixer('myfixes.txt');
 my $store    = Catmandu->store('ElasticSearch', index_name => 'catmandu');

 $store->add_many(
 	$fixer->fix($importer)
 );

=head1 MODULES

=over

=item * L<Catmandu::MARC::Tutorial>

=item * L<Catmandu::Importer::MARC>

=item * L<Catmandu::Exporter::MARC>

=item * L<Catmandu::Fix::marc_map>

=item * L<Catmandu::Fix::marc_spec>

=item * L<Catmandu::Fix::marc_add>

=item * L<Catmandu::Fix::marc_append>

=item * L<Catmandu::Fix::marc_replace_all>

=item * L<Catmandu::Fix::marc_remove>

=item * L<Catmandu::Fix::marc_xml>

=item * L<Catmandu::Fix::marc_in_json>

=item * L<Catmandu::Fix::marc_decode_dollar_subfields>

=item * L<Catmandu::Fix::marc_set>

=item * L<Catmandu::Fix::marc_copy>

=item * L<Catmandu::Fix::marc_cut>

=item * L<Catmandu::Fix::marc_paste>

=item * L<Catmandu::Fix::Bind::marc_each>

=item * L<Catmandu::Fix::Condition::marc_match>

=item * L<Catmandu::Fix::Condition::marc_has>

=item * L<Catmandu::Fix::Condition::marc_has_many>

=item * L<Catmandu::Fix::Condition::marc_spec_has>

=item * L<Catmandu::Fix::Inline::marc_map>

=item * L<Catmandu::Fix::Inline::marc_add>

=item * L<Catmandu::Fix::Inline::marc_remove>

=back

=head1 DESCRIPTION

With Catmandu, LibreCat tools abstract digital library and research services as data
warehouse processes. As stores we reuse MongoDB or ElasticSearch providing us with
developer friendly APIs. Catmandu works with international library standards such as
MARC, MODS and Dublin Core, protocols such as OAI-PMH, SRU and open repositories such
as DSpace and Fedora. And, of course, we speak the evolving Semantic Web.

Follow us on L<http://librecat.org> and read an introduction into Catmandu data
processing at L<https://github.com/LibreCat/Catmandu/wiki>.

=head1 SEE ALSO

L<Catmandu>,
L<Catmandu::Importer>,
L<Catmandu::Fix>,
L<Catmandu::Store>,
L<MARC::Spec>

=head1 AUTHOR

Patrick Hochstenbach, C<< <patrick.hochstenbach at ugent.be> >>

=head1 CONTRIBUTORS

=over

=item * Nicolas Steenlant, C<< <nicolas.steenlant at ugent.be> >>

=item * Nicolas Franck, C<< <nicolas.franck at ugent.be> >>

=item * Johann Rolschewski, C<< jorol at cpan.org >>

=item * Chris Cormack

=item * Robin Sheat

=item * Carsten Klee, C<< klee at cpan.org >>

=back

=head1 LICENSE AND COPYRIGHT

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
