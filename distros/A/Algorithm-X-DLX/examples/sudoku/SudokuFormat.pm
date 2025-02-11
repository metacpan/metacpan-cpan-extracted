package SudokuFormat;

use strict;
use warnings;
use Carp qw(croak);
use List::Util qw(first);
use Scalar::Util qw(weaken);

sub new {
    my ($class, $type_or_format, $input) = @_;
    my $self = {};
    
    if ($input && !ref($input)) {
       $self->{template} = $input;
    }

    if (ref($type_or_format) eq 'SudokuType') {
        my $type = $type_or_format;
        $self->{type} = $type;
        $self->{template} ||= default_template($type);

    } else {
        my $format = $type_or_format;
        my $type = SudokuType::guess($format);
        $self->{type} = $type;
        $self->{template} ||= $format;
    }

    $self->{labels} = choose_labels($self->{template});
    
    # Validate cells
    my $cells = 0;
    foreach my $c (split //, $self->{template}) {
        if (is_cell($c, $self)) {
            $cells++;
        }
    }
    
    if ($cells != $self->{type}->size()) {
        croak "Invalid number of cells";
    }

    bless $self, $class;
    return $self;
}

sub compact {
    my ($class, $type) = @_;

    my $line = '.' x $type->n() . "\n";
    my $result = '';
    for (my $y = 0; $y < $type->n(); ++$y) {
        $result .= $line;
    }
    
    my $self = { type => $type, template => $result, labels => choose_labels($result) };
    weaken($self->{type});

    return bless $self, $class;
}

sub oneline {
    my ($class, $type) = @_;

    my $result = '.' x $type->size() . "\n";
    my $self = { type => $type, template => $result, labels => choose_labels($result) };
    weaken($self->{type});

    return bless $self, $class;
}

sub with_labels {
    my ($self, $str) = @_;
    my @labels = choose_labels_n($str, scalar split //, $self->{type}->n());
    
    my %new_self = %{$self};
    @new_self{qw(labels)} = @labels; 
   
    return bless \%new_self, ref($self);
}

sub count_cells {
    my $str = shift() or return 0;
    my $count = 0;

    foreach my $c (split //, $str) {
        if (is_valid_label($c) || is_empty($c)) {
            ++$count;
        }
    }
    
    return $count;
}

sub is_cell {
    my ($c, $self) = @_;

    return is_empty($c) || index($self->{labels}, $c) != -1;
}

sub value {
    my ($c, $self) = @_;
    
    my $pos = index($self->{labels}, $c);
    
    return ($pos == -1) ? 0 : ($pos + 1);
}

sub label {
    my ($i, $self) = @_;

    croak "Index out of bounds" if ($i > length($self->{labels}));
    
    return ($i == 0) ? '.' : substr($self->{labels}, $i - 1, 1);
}

sub labels {
    my ($self) = @_;
    
    return $self->{labels};
}

sub get_values {
    my ($str, $self) = @_;
    
    my @labels = choose_labels($str);
    my @values;

    foreach my $c (split //, $str) {
        my $pos = index(join('', @labels), $c);
        
        if ($pos != -1) {
            push @values, ($pos + 1);
        } elsif (is_empty($c)) {
            push @values, 0;
        }
    }
    
    return \@values;
}

sub to_string {
    my ($self, @values) = @_;

    my $value_size = scalar(@values);
    my $type_size = $self->type->size();
    croak "to_string(): wrong number of values ($value_size vs. $type_size)" if $value_size != $type_size;
    
    my @result_chars = split //, $self->{template};
    
    my $j = 0;
    for (my $i=0; $i < @result_chars; ++$i) {
        if (is_cell($result_chars[$i], $self)) {
            croak "Logic error" if (@values <= $j);
            $result_chars[$i] = label($values[$j], $self);
            $j++;
        }
    }        

    croak "Logic error" if (@values != $j);
        
    return join('', @result_chars);
}

sub type {
   return shift->{type};
}

sub is_empty {
   my $c = shift;
   return $c eq '.' || $c eq '0';
}

sub is_valid_label {
   return index(valid_labels(), shift) != -1;
}

sub is_valid_cell {
    my $c = shift;
    return is_valid_label($c) || is_empty($c);
}

sub valid_labels {
   return '123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz';
}

sub choose_labels {
    my ($str) = @_;
    
    my $size = 0;
    foreach my $c (split //, $str) {
        if (is_valid_cell($c)) {
            $size++;
        }
    }
    
    my $n = 0;
    while (($n + 1) * ($n + 1) <= $size) {
        $n++;
    }

    if ($n * $n != $size) {
        croak ":(";
    }
    
    return choose_labels_n($str, $n);
}

sub choose_labels_n {
    my ($str, $n) = @_;
    
    my %used;
    
    foreach my $c (split //, $str) {
        if (is_valid_label($c)) {
            $used{$c}++;
        }
    }

    if (scalar(keys %used) > $n) {
        croak "Too many different labels";
    }

    my ($has_digit, $has_upper, $has_lower) = (0, 0, 0);
    
    foreach my $c (keys %used) {
        if ($c =~ /\d/) { 
            $has_digit = 1; 
        } elsif ($c =~ /[A-Z]/) { 
            $has_upper = 1; 
        } elsif ($c =~ /[a-z]/) { 
            $has_lower = 1; 
        }
    }
    my @valid_labels = split //, valid_labels();

    foreach my $c (@valid_labels) {
        last if scalar(keys %used) >= $n;
        next if exists $used{$c};

        if (($c =~ /\d/ && $has_digit)
            || ($c =~ /[a-z]/ && $has_lower)
            || ($c =~ /[A-Z]/ && $has_upper)) {
            $used{$c} = 0;
        }
    }

    foreach my $c (@valid_labels) {
        last if scalar(keys %used) >= $n;
        
        if (!exists($used{$c})) {
            $used{$c} = 0;
        }
    }

    if (scalar(keys %used) < $n) {
        croak "Sudoku too large, not enough labels";
    }

    return join('', sort keys %used);
}

sub default_template {
    my ($type) = @_;
    
    # Step 1: empty
    my @lines;
    my $n = $type->n();
    my $header = '+' . ('-' x ($n * 2 - 1)) . '+';
    my $empty = '|' . (' ' x ($n * 2 - 1)) . '|';

    push @lines, $header;
    push @lines, ($empty) x (2 * $n - 1);
    push @lines, $header;

    for my $y (0 .. $n - 1) {
        for my $x (0 .. $n - 1) {
            substr($lines[2 * $y + 1], 2 * $x + 1, 1) = '.';
        }
    }

    # Step 2: add vertical lines
    my $set = sub {
        my ($x, $y, $c) = @_;
        if (substr($lines[$y], $x, 1) eq ' ') {
            substr($lines[$y], $x, 1) = $c;
        } elsif (substr($lines[$y], $x, 1) ne $c) {
            substr($lines[$y], $x, 1) = '+';
        }
    };

    for my $y (0 .. $n - 1) {
        for my $x (0 .. $n - 2) {
            if ($type->region_xy($x, $y) != $type->region_xy($x + 1, $y)) {
                for my $dy (0 .. 2) {
                    $set->(2 * $x + 2, 2 * $y + $dy, '|');
                }
            }
        }
    }

    # Step 3: add horizontal lines
    for my $y (0 .. $n - 2) {
        for my $x (0 .. $n - 1) {
            if ($type->region_xy($x, $y) != $type->region_xy($x, $y + 1)) {
                for my $dx (0 .. 2) {
                    $set->(2 * $x + $dx, 2 * $y + 2, '-');
                }
            }
        }
    }

    # Step 4: collapse uninteresting rows and columns
    my @keep_row = (0) x @lines;
    my @keep_col = (0) x length($lines[0]);

    for my $y (0 .. $#lines) {
        for my $x (0 .. length($lines[0]) - 1) {
            my $c = substr($lines[$y], $x, 1);
            if ($c ne ' ' && $c ne '|') {
                $keep_row[$y] = 1;
            }
            if ($c ne ' ' && $c ne '-') {
                $keep_col[$x] = 1;
            }
        }
    }

    my $result = '';
    
    for my $y (0 .. $#lines) {
        next unless $keep_row[$y];
        
        for my $x (0 .. $#keep_col) {
            if ($keep_col[$x]) {
                # Append character to result
                $result .= substr($lines[$y], $x, 1);
            }
        }
        $result .= "\n";
    }

    return $result;
}

1;

