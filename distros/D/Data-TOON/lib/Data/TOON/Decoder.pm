package Data::TOON::Decoder;
use 5.014;
use strict;
use warnings;

sub new {
    my ($class, %opts) = @_;
    return bless {
        strict => $opts{strict} // 1,
        lines => [],
        pos => 0,
        max_depth => $opts{max_depth} // 100,  # Prevent DoS from deep nesting
        current_depth => 0,
    }, $class;
}

sub decode {
    my ($self, $toon_text) = @_;
    
    # Split into lines and remove trailing newlines
    my @lines = split /\r?\n/, $toon_text;
    pop @lines if @lines && $lines[-1] eq '';
    
    $self->{lines} = \@lines;
    $self->{pos} = 0;
    
    # Determine root form and decode
    return $self->_decode_root();
}

sub _decode_root {
    my ($self) = @_;
    
    # Initialize position
    $self->{pos} = 0;
    
    # Find first non-empty line at depth 0
    my @non_empty = ();
    foreach my $line (@{$self->{lines}}) {
        next if !defined $line || $line =~ /^\s*$/;
        next if $self->_get_depth($line) != 0;
        push @non_empty, $line;
    }
    
    # Empty document → empty object
    return {} if !@non_empty;
    
    my $first = $non_empty[0];
    
    # Check if first line is a root array header: [N], [N|], [N\t]
    if ($first =~ /^\s*\[(\d+)([\t|]?)?\]\s*:\s*(.*)$/) {
        # Root array header
        my $count = $1;
        my $delimiter = $2 ? $2 : ',';
        my $rest = $3;
        
        # Inline values
        if ($rest) {
            my @values = split /\Q$delimiter\E/, $rest;
            return [map { $self->_parse_primitive($_) } @values];
        }
        
        # Or read list items below
        $self->{pos} = 0;
        my @items;
        while ($self->{pos} < @{$self->{lines}}) {
            my $line = $self->{lines}->[$self->{pos}];
            
            if (!$line || $line =~ /^\s*$/) {
                $self->{pos}++;
                next;
            }
            
            my $depth = $self->_get_depth($line);
            if ($depth == 0) {
                # Still at root - check if it's the header
                if ($line =~ /^\[/) {
                    $self->{pos}++;
                    next;  # Skip header
                }
            } elsif ($depth > 0) {
                my $trimmed = $line;
                $trimmed =~ s/^\s+//;
                if ($trimmed =~ /^-/) {
                    # List item
                    $self->{pos}++;
                    $trimmed =~ s/^-\s+//;
                    push @items, $self->_parse_primitive($trimmed);
                    next;
                }
            } else {
                last;
            }
            $self->{pos}++;
        }
        return \@items if @items;
        return [];
    }
    
    # Check if first non-empty line is an array header with key (has [N]{...}: pattern)
    if ($first =~ /^\w+\[/) {
        # Object with array field - use object mode
        return $self->_decode_object(0);
    }
    
    # Single line and it's a primitive (no colon = not key-value)
    if (@non_empty == 1 && $first !~ /:/) {
        return $self->_parse_primitive($first);
    }
    
    # Otherwise, decode as object with depth 0
    return $self->_decode_object(0);
}

sub _decode_object {
    my ($self, $target_depth) = @_;
    $target_depth //= 0;
    
    # Check max depth to prevent DoS
    if ($target_depth > $self->{max_depth}) {
        die "Maximum nesting depth exceeded (max: $self->{max_depth})\n";
    }
    
    my $obj = {};
    
    while ($self->{pos} < @{$self->{lines}}) {
        my $line = $self->{lines}->[$self->{pos}];
        
        # Skip empty lines
        if (!$line || $line =~ /^\s*$/) {
            $self->{pos}++;
            next;
        }
        
        my $depth = $self->_get_depth($line);
        
        # If depth is less than or equal to target, we're done with this object
        if ($depth < $target_depth) {
            last;
        }
        
        # If depth is greater than target (but not target+1), skip (shouldn't happen in well-formed TOON)
        if ($depth > $target_depth + 1) {
            $self->{pos}++;
            next;
        }
        
        # If depth is greater than target, it's a child of a nested key
        if ($depth > $target_depth) {
            last;
        }
        
        $self->{pos}++;
        
        # Parse key-value line
        my $trimmed = $line;
        $trimmed =~ s/^\s+//;
        
        # Match patterns like:
        # key: value
        # key[N]: ...
        # key[N]{fields}: ...
        # key: (empty - nested object)
        if ($trimmed =~ /^(\w+)(\[[^\]]*\])?(\{[^}]*\})?\s*:\s*(.*)$/) {
            my ($key, $bracket, $fields, $rest) = ($1, $2, $3, $4);
            
            # If there's a bracket segment, it's an array
            if ($bracket) {
                $obj->{$key} = $self->_decode_array_value($bracket, $fields, $rest);
            } elsif (!$rest || $rest =~ /^\s*$/) {
                # Empty value after colon = nested object
                $obj->{$key} = $self->_decode_object($target_depth + 1);
            } else {
                # Primitive value
                $obj->{$key} = $self->_parse_primitive($rest);
            }
        }
    }
    
    return $obj;
}

sub _decode_array_value {
    my ($self, $bracket_part, $fields_part, $rest) = @_;
    
    # Parse bracket part: [N] or [N\t] or [N|]
    my $delimiter = ',';  # default
    if ($bracket_part =~ /^\[(\d+)([\t|])?\]/) {
        my $count = $1;
        if (defined $2) {
            $delimiter = $2;
        }
        
        if ($fields_part) {
            # Tabular format: extract field names and parse rows
            my $fields_str = $fields_part;
            $fields_str =~ s/^{|}$//g;
            my @fields = split /\Q$delimiter\E/, $fields_str;
            
            my @rows;
            while ($self->{pos} < @{$self->{lines}}) {
                my $line = $self->{lines}->[$self->{pos}];
                
                if (!$line || $line =~ /^\s*$/) {
                    $self->{pos}++;
                    next;
                }
                
                my $depth = $self->_get_depth($line);
                if ($depth <= 0) {
                    last;
                }
                
                # Check for list items (- prefix)
                my $trimmed = $line;
                $trimmed =~ s/^\s+//;
                if ($trimmed =~ /^-\s/) {
                    last;  # List format starts here
                }
                
                $self->{pos}++;
                
                my @values = split /\Q$delimiter\E/, $trimmed;
                my $obj = {};
                for (my $i = 0; $i < @fields && $i < @values; $i++) {
                    $obj->{$fields[$i]} = $self->_parse_primitive($values[$i]);
                }
                push @rows, $obj;
            }
            return \@rows;
        } else {
            # Check for list format (items starting with -)
            # Peek ahead to see if next line (at depth+1) starts with "-"
            my $has_list_format = 0;
            my $peek_pos = $self->{pos};
            
            while ($peek_pos < @{$self->{lines}}) {
                my $peek_line = $self->{lines}->[$peek_pos];
                
                if (!$peek_line || $peek_line =~ /^\s*$/) {
                    $peek_pos++;
                    next;
                }
                
                my $peek_depth = $self->_get_depth($peek_line);
                if ($peek_depth <= 0) {
                    last;
                }
                
                my $peek_trimmed = $peek_line;
                $peek_trimmed =~ s/^\s+//;
                
                if ($peek_trimmed =~ /^-/) {
                    $has_list_format = 1;
                    last;
                }
                
                # If it's not empty and doesn't start with -, it's inline or not list format
                last;
            }
            
            if ($has_list_format) {
                # Parse list format items (rest of the implementation)
                my @items;
                while ($self->{pos} < @{$self->{lines}}) {
                    my $line = $self->{lines}->[$self->{pos}];
                    
                    if (!$line || $line =~ /^\s*$/) {
                        $self->{pos}++;
                        next;
                    }
                    
                    my $depth = $self->_get_depth($line);
                    if ($depth <= 0) {
                        last;
                    }
                    
                    my $trimmed = $line;
                    $trimmed =~ s/^\s+//;
                    
                    if ($trimmed =~ /^-\s(.*)$/) {
                        $self->{pos}++;
                        my $item_content = $1;
                        
                        # Parse first field or value
                        if ($item_content =~ /^(\w+):\s*(.*)$/) {
                            # Object item: first field on hyphen line
                            my ($first_key, $first_value) = ($1, $2);
                            my $item = {};
                            
                            if ($first_value =~ /^\s*$/) {
                                # Nested object - parse remaining fields at depth+2
                                $item->{$first_key} = $self->_decode_object($depth + 2);
                            } else {
                                # Primitive value
                                $item->{$first_key} = $self->_parse_primitive($first_value);
                                
                                # Parse remaining fields at depth+1
                                while ($self->{pos} < @{$self->{lines}}) {
                                    my $next_line = $self->{lines}->[$self->{pos}];
                                    
                                    if (!$next_line || $next_line =~ /^\s*$/) {
                                        $self->{pos}++;
                                        next;
                                    }
                                    
                                    my $next_depth = $self->_get_depth($next_line);
                                    if ($next_depth < $depth + 1 || $next_depth > $depth + 1) {
                                        last;
                                    }
                                    
                                    my $next_trimmed = $next_line;
                                    $next_trimmed =~ s/^\s+//;
                                    
                                    if ($next_trimmed =~ /^-/) {
                                        # Next list item
                                        last;
                                    }
                                    
                                    if ($next_trimmed =~ /^(\w+):\s*(.*)$/) {
                                        $self->{pos}++;
                                        $item->{$1} = $self->_parse_primitive($2);
                                    } else {
                                        last;
                                    }
                                }
                            }
                            
                            push @items, $item;
                        } else {
                            # Primitive item
                            push @items, $self->_parse_primitive($item_content);
                        }
                    } else {
                        last;
                    }
                }
                return \@items;
            } else {
                # Inline primitive array format: parse inline values with correct delimiter
                my @values = split /\Q$delimiter\E/, $rest;
                my @result = map { $self->_parse_primitive($_) } @values;
                return \@result;
            }
        }
    }
    
    return [];
}
sub _parse_primitive {
    my ($self, $value) = @_;
    
    return undef unless defined $value;
    
    $value =~ s/^\s+|\s+$//g;
    
    # Handle quoted strings
    if ($value =~ /^"(.*)"$/) {
        my $str = $1;
        # Unescape
        $str =~ s/\\"/"/g;
        $str =~ s/\\\\/\\/g;
        $str =~ s/\\n/\n/g;
        $str =~ s/\\r/\r/g;
        $str =~ s/\\t/\t/g;
        return $str;
    }
    
    return undef if $value eq 'null';
    return 1 if $value eq 'true';
    return 0 if $value eq 'false';
    
    # Number parsing with canonical form
    if ($value =~ /^-?\d+(?:\.\d+)?(?:[eE][+-]?\d+)?$/) {
        # Reject leading zeros (except 0 itself and 0.x)
        if ($value =~ /^[+-]?0\d/ && $value !~ /^[+-]?0\./) {
            # Leading zero - treat as string
            return $value;
        }
        
        # Parse and normalize
        my $num = 0 + $value;
        
        # Normalize: -0 → 0, remove trailing zeros
        if ($num == 0) {
            return 0;
        }
        
        # Return normalized number
        if ($num != int($num)) {
            # Float - remove trailing zeros
            my $str = sprintf("%.15g", $num);
            return 0 + $str;
        }
        
        return $num;
    }
    
    return $value;
}

sub _get_depth {
    my ($self, $line) = @_;
    return 0 unless $line;
    my $spaces = length($line) - length($line =~ s/^ +//r);
    return int($spaces / 2);
}

1;
