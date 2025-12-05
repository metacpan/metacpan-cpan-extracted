package Data::TOON::Encoder;
use 5.014;
use strict;
use warnings;

sub new {
    my ($class, %opts) = @_;
    return bless {
        indent     => $opts{indent}     || 2,
        delimiter  => $opts{delimiter}  || ',',
        strict     => $opts{strict}     // 1,
        depth      => 0,
        max_depth  => $opts{max_depth}  // 100,
        seen       => {},  # Track object references for circular detection
        column_priority => $opts{column_priority} || [],  # Column names to prioritize
    }, $class;
}

sub encode {
    my ($self, $data) = @_;
    
    $self->{depth} = 0;
    $self->{seen} = {};  # Reset seen references
    my $result = $self->_encode_value($data);
    
    return $result;
}

sub _encode_value {
    my ($self, $value) = @_;
    
    return undef unless defined $value;
    
    my $ref = ref $value;
    
    if ($ref eq 'HASH') {
        # Check for circular reference
        my $ref_addr = "$value";  # Stringify reference to get address
        if ($self->{seen}->{$ref_addr}) {
            die "Circular reference detected\n";
        }
        $self->{seen}->{$ref_addr} = 1;
        
        # Check max depth
        if ($self->{depth} > $self->{max_depth}) {
            die "Maximum nesting depth exceeded (max: $self->{max_depth})\n";
        }
        
        return $self->_encode_object($value);
    } elsif ($ref eq 'ARRAY') {
        # Check for circular reference
        my $ref_addr = "$value";
        if ($self->{seen}->{$ref_addr}) {
            die "Circular reference detected\n";
        }
        $self->{seen}->{$ref_addr} = 1;
        
        # Check max depth
        if ($self->{depth} > $self->{max_depth}) {
            die "Maximum nesting depth exceeded (max: $self->{max_depth})\n";
        }
        
        return $self->_encode_array($value);
    } else {
        return $self->_encode_primitive($value);
    }
}

sub _encode_object {
    my ($self, $obj) = @_;
    
    # Check max depth - allow one level deep
    if ($self->{depth} >= $self->{max_depth}) {
        die "Maximum nesting depth exceeded (max: $self->{max_depth})\n";
    }
    
    my @lines;
    foreach my $key ($self->_sort_fields(keys %$obj)) {
        my $value = $obj->{$key};
        my $indent = ' ' x ($self->{depth} * $self->{indent});
        
        my $ref = ref $value;
        
        if ($ref eq 'ARRAY') {
            push @lines, $self->_encode_object_with_array($indent, $key, $value);
        } elsif ($ref eq 'HASH') {
            push @lines, $indent . "$key:";
            local $self->{depth} = $self->{depth} + 1;
            push @lines, $self->_encode_object($value);
        } else {
            my $encoded = $self->_encode_primitive($value);
            push @lines, "$indent$key: $encoded";
        }
    }
    
    return join "\n", @lines;
}

sub _encode_object_with_array {
    my ($self, $indent, $key, $array) = @_;
    
    return undef unless ref $array eq 'ARRAY';
    
    my @lines;
    my $array_len = scalar(@$array);
    
    # Check if array contains only objects (for potential tabular format)
    my $all_objects = 1;
    foreach my $item (@$array) {
        if (ref $item ne 'HASH') {
            $all_objects = 0;
            last;
        }
    }
    
    if ($all_objects && $array_len > 0) {
        # Check if tabular format is possible
        # Requires: all objects have same keys and all values are primitives
        my $first = $array->[0];
        my @first_keys = sort keys %$first;
        my $can_tabular = 1;
        
        # Check all objects have same keys and all values are primitives
        foreach my $obj (@$array) {
            my @obj_keys = sort keys %$obj;
            
            # Different key set = can't use tabular
            if (@obj_keys != @first_keys) {
                $can_tabular = 0;
                last;
            }
            
            for (my $i = 0; $i < @first_keys; $i++) {
                if ($first_keys[$i] ne $obj_keys[$i]) {
                    $can_tabular = 0;
                    last;
                }
            }
            
            if (!$can_tabular) {
                last;
            }
            
            # Check all values are primitives
            foreach my $val (values %$obj) {
                if (ref $val) {
                    $can_tabular = 0;
                    last;
                }
            }
            
            if (!$can_tabular) {
                last;
            }
        }
        
        if ($can_tabular) {
            # Tabular format: extract field names from first object
            my @fields = $self->_sort_fields(keys %$first);
            
            # Add delimiter indicator in bracket
            my $delim_indicator = '';
            if ($self->{delimiter} eq "\t") {
                $delim_indicator = "\t";
            } elsif ($self->{delimiter} eq '|') {
                $delim_indicator = '|';
            }
            
            my $field_list = join($self->{delimiter}, @fields);
            my $header = $indent . $key . '[' . $array_len . $delim_indicator . ']{' . $field_list . '}:';
            push @lines, $header;
            
            local $self->{depth} = $self->{depth} + 1;
            my $row_indent = ' ' x ($self->{depth} * $self->{indent});
            
            foreach my $obj (@$array) {
                my @values = map { $self->_encode_primitive($obj->{$_}) } @fields;
                push @lines, $row_indent . join($self->{delimiter}, @values);
            }
        } else {
            # List format: use - items
            my $header = $indent . $key . '[' . $array_len . ']:';
            push @lines, $header;
            
            local $self->{depth} = $self->{depth} + 1;
            my $item_indent = ' ' x ($self->{depth} * $self->{indent});
            my $field_indent = ' ' x (($self->{depth} + 1) * $self->{indent});
            
            foreach my $obj (@$array) {
                # First field on hyphen line, remaining fields at depth+2
                my @keys = $self->_sort_fields(keys %$obj);
                if (@keys > 0) {
                    # First key with hyphen at current depth
                    my $first_key = $keys[0];
                    local $self->{depth} = $self->{depth} + 1;
                    my $first_val = $self->_encode_value($obj->{$first_key});
                    push @lines, $item_indent . "- $first_key: $first_val";
                    
                    # Remaining keys at depth+2 (one deeper)
                    for (my $i = 1; $i < @keys; $i++) {
                        my $k = $keys[$i];
                        my $v = $self->_encode_value($obj->{$k});
                        push @lines, $field_indent . "$k: $v";
                    }
                } else {
                    # Empty object
                    push @lines, $item_indent . "-";
                }
            }
        }
    } else {
        # List format: mixed types or not objects
        my $header = $indent . $key . '[' . $array_len . ']:';
        push @lines, $header;
        
        local $self->{depth} = $self->{depth} + 1;
        my $item_indent = ' ' x ($self->{depth} * $self->{indent});
        
        foreach my $item (@$array) {
            my $encoded = $self->_encode_value($item);
            push @lines, $item_indent . "- $encoded" if defined $encoded;
        }
    }
    
    return join "\n", @lines;
}

sub _encode_array {
    my ($self, $array) = @_;
    
    # Check if all primitives
    my $all_primitives = 1;
    foreach my $item (@$array) {
        if (ref $item) {
            $all_primitives = 0;
            last;
        }
    }
    
    my $array_len = scalar(@$array);
    
    if ($all_primitives) {
        # Primitive array: inline format with delimiter indicator
        my @values = map { $self->_encode_primitive($_) } @$array;
        my $delim_indicator = '';
        if ($self->{delimiter} eq "\t") {
            $delim_indicator = "\t";
        } elsif ($self->{delimiter} eq '|') {
            $delim_indicator = '|';
        }
        return '[' . $array_len . $delim_indicator . ']: ' . join($self->{delimiter}, @values);
    } else {
        # Mixed/object array: list format
        my @lines = ('[' . $array_len . ']:');
        
        local $self->{depth} = $self->{depth} + 1;
        foreach my $item (@$array) {
            my $encoded = $self->_encode_value($item);
            push @lines, "  - $encoded" if defined $encoded;
        }
        
        return join "\n", @lines;
    }
}

sub _encode_primitive {
    my ($self, $value) = @_;
    
    return 'null' if !defined $value;
    
    # Check if it's numeric (but not a boolean-like string)
    if ($value =~ /^[+-]?\d+(?:\.\d+)?$/ && $value !~ /^(true|false|null)$/i) {
        # Canonical form: normalize numbers
        my $normalized = $self->_canonicalize_number($value);
        return $normalized;
    }
    
    # Check if needs quoting
    if ($self->_needs_quoting($value)) {
        return '"' . $self->_escape_string($value) . '"';
    }
    
    return $value;
}

sub _canonicalize_number {
    my ($self, $num) = @_;
    
    # -0 becomes 0
    if ($num == 0) {
        return '0';
    }
    
    # Convert to numeric form to normalize
    my $n = 0 + $num;
    
    # Remove trailing zeros from decimals
    if ($n =~ /\./) {
        $n =~ s/0+$//;
        $n =~ s/\.$//;
    }
    
    return "$n";
}

sub _needs_quoting {
    my ($self, $value) = @_;
    
    return 1 if $value eq '';
    return 1 if $value =~ /^\s/;
    return 1 if $value =~ /\s$/;
    return 1 if $value eq 'true' || $value eq 'false' || $value eq 'null';
    return 1 if $value =~ /^-?\d+(?:\.\d+)?(?:e[+-]?\d+)?$/i;
    return 1 if $value =~ /^0\d+$/;
    return 1 if $value =~ /[:"\\\[\]{}-]/;
    return 1 if $value =~ /[\r\n\t]/;
    return 1 if $value =~ /$self->{delimiter}/;
    return 1 if $value =~ /^-/;
    
    return 0;
}

sub _escape_string {
    my ($self, $str) = @_;
    
    $str =~ s/\\/\\\\/g;
    $str =~ s/"/\\"/g;
    $str =~ s/\n/\\n/g;
    $str =~ s/\r/\\r/g;
    $str =~ s/\t/\\t/g;
    
    return $str;
}

sub _sort_fields {
    my ($self, @fields) = @_;
    
    # If no priority specified, use alphabetical sort (backward compatibility)
    return sort @fields unless @{$self->{column_priority}};
    
    my %priority;
    my $index = 0;
    foreach my $col (@{$self->{column_priority}}) {
        $priority{$col} = $index++;
    }
    
    # Sort: priority columns first (by priority order), then remaining columns alphabetically
    return sort {
        my $a_priority = exists $priority{$a} ? $priority{$a} : 999999;
        my $b_priority = exists $priority{$b} ? $priority{$b} : 999999;
        
        if ($a_priority != $b_priority) {
            return $a_priority <=> $b_priority;
        }
        return $a cmp $b;
    } @fields;
}

1;


