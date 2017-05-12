use strict;
use warnings;
use Data::ParseBinary::Core;

package Data::ParseBinary::Enum;
our @ISA = qw{Data::ParseBinary::Adapter};
# TODO: implement as macro in terms of SymmetricMapping (macro)
#   that is implemented as MappingAdapter

sub _init {
    my ($self, @params) = @_;
    my $decode = {};
    my $encode = {};
    $self->{have_default} = 0;
    $self->{default_action} = undef;
    while (@params) {
        my $key = shift @params;
        my $value = shift @params;
        if ($key eq '_default_') {
            $self->{have_default} = 1;
            $self->{default_action} = $value;
            if (ref $value) {
                if ($value != $Data::ParseBinary::BaseConstruct::DefaultPass) {
                    die "Enum Error: got invalid value as default";
                }
            } elsif (exists $encode->{$value}) {
                die "Enum Error: $value should not be defined as regular case";
            } else {
                $self->{default_value} = shift @params;
            }
            next;
        }
        $encode->{$key} = $value;
        $decode->{$value} = $key;
    }
    $self->{encode} = $encode;
    $self->{decode} = $decode;
}

sub _decode {
    my ($self, $value) = @_;
    if (exists $self->{decode}->{$value}) {
        return $self->{decode}->{$value};
    }
    if ($self->{have_default}) {
        if (ref($self->{default_action}) and $self->{default_action} == $Data::ParseBinary::BaseConstruct::DefaultPass) {
            return $value;
        }
        return $self->{default_action};
    }
    die "Enum: unrecognized value $value, and no default defined";
}

sub _encode {
    my ($self, $tvalue) = @_;
    if (exists $self->{encode}->{$tvalue}) {
        return $self->{encode}->{$tvalue};
    }
    if ($self->{have_default}) {
        if (ref($self->{default_action}) and $self->{default_action} == $Data::ParseBinary::BaseConstruct::DefaultPass) {
            return $tvalue;
        }
        return $self->{default_value};
    }
    die "Enum: unrecognized value $tvalue";
}

package Data::ParseBinary::FlagsEnum;
our @ISA = qw{Data::ParseBinary::Adapter};

sub _init {
    my ($self, @mapping) = @_;
    my @pairs;
    die "FlagsEnum: Mapping should be even" if @mapping % 2 == 1;
    while (@mapping) {
        my $name = shift @mapping;
        my $value = shift @mapping;
        push @pairs, [$name, $value];
    }
    $self->{pairs} = \@pairs;
}

sub _decode {
    my ($self, $value) = @_;
    my $hash = {};
    foreach my $rec (@{ $self->{pairs} }) {
        $hash->{$rec->[0]} = 1 if $value & $rec->[1];
    }
    return $hash;
}

sub _encode {
    my ($self, $tvalue) = @_;
    my $value = 0;
    foreach my $rec (@{ $self->{pairs} }) {
        if (exists $tvalue->{$rec->[0]} and $tvalue->{$rec->[0]}) {
            $value |= $rec->[1];
        }
    }
    return $value;
}

package Data::ParseBinary::ExtractingAdapter;
our @ISA = qw{Data::ParseBinary::Adapter};

sub _init {
    my ($self, $sub_name) = @_;
    $self->{sub_name} = $sub_name;
}

sub _decode {
    my ($self, $value) = @_;
    return $value->{$self->{sub_name}};
}

sub _encode {
    my ($self, $tvalue) = @_;
    return {$self->{sub_name} => $tvalue};
}

package Data::ParseBinary::IndexingAdapter;
our @ISA = qw{Data::ParseBinary::Adapter};

sub _init {
    my ($self, $index) = @_;
    $self->{index} = $index || 0;
}

sub _decode {
    my ($self, $value) = @_;
    return $value->[$self->{index}];
}

sub _encode {
    my ($self, $tvalue) = @_;
    return [ ('') x $self->{index}, $tvalue ];
}

package Data::ParseBinary::JoinAdapter;
our @ISA = qw{Data::ParseBinary::Adapter};

sub _decode {
    my ($self, $value) = @_;
    return join '', @$value;
}

sub _encode {
    my ($self, $tvalue) = @_;
    return [split '', $tvalue];
}

package Data::ParseBinary::ConstAdapter;
our @ISA = qw{Data::ParseBinary::Adapter};

sub _init {
    my ($self, $value) = @_;
    $self->{value} = $value;
}

sub _decode {
    my ($self, $value) = @_;
    if (not $value eq $self->{value}) {
        die "Const Error: expected $self->{value} got $value";
    }
    return $value;
}

sub _encode {
    my ($self, $tvalue) = @_;
    if (not defined $self->_get_name()) {
        # if we don't have a name, then just use the value
        return $self->{value};
    }
    if (defined $tvalue and $tvalue eq $self->{value}) {
        return $self->{value};
    }
    die "Const Error: expected $self->{value} got ". (defined $tvalue ? $tvalue : "undef");
}


package Data::ParseBinary::LengthValueAdapter;
our @ISA = qw{Data::ParseBinary::Adapter};

sub _decode {
    my ($self, $value) = @_;
    return $value->[1];
}

sub _encode {
    my ($self, $tvalue) = @_;
    return [length($tvalue), $tvalue];
}

package Data::ParseBinary::PaddedStringAdapter;
our @ISA = qw{Data::ParseBinary::Adapter};

sub _init {
    my ($self, %params) = @_;
    if (not defined $params{length}) {
        die "PaddedStringAdapter: you must specify length";
    }
    $self->{length} = $params{length};
    $self->{encoding} = $params{encoding};
    $self->{padchar} = defined $params{padchar} ? $params{padchar} : "\x00";
    $self->{paddir} = $params{paddir} || "right";
    $self->{trimdir} = $params{trimdir} || "right";
    if (not grep($_ eq $self->{paddir}, qw{right left center})) {
        die "PaddedStringAdapter: paddir should be one of {right left center}";
    }
    if (not grep($_ eq $self->{trimdir}, qw{right left})) {
        die "PaddedStringAdapter: trimdir should be one of {right left}";
    }
}

sub _decode {
    my ($self, $value) = @_;
    my $tvalue = $value;
    my $char = $self->{padchar};
    if ($self->{paddir} eq 'right' or $self->{paddir} eq 'center') {
        $tvalue =~ s/$char*\z//;
    } elsif ($self->{paddir} eq 'left' or $self->{paddir} eq 'center') {
        $tvalue =~ s/\A$char*//;
    }
    return $tvalue;
}

sub _encode {
    my ($self, $tvalue) = @_;
    my $value = $tvalue;
    
    if (length($value) < $self->{length}) {
        my $add = $self->{length} - length($value);
        my $char = $self->{padchar};
        if ($self->{paddir} eq 'right') {
            $value .= $char x $add;
        } elsif ($self->{paddir} eq 'left') {
            $value = ($char x $add) . $value;
        } elsif ($self->{paddir} eq 'center') {
            my $add_left = $add / 2;
            my $add_right = $add_left + ($add % 2 == 0 ? 0 : 1);
            $value = ($char x $add_left) . $value . ($char x $add_right);
        }
    }
    if (length($value) > $self->{length}) {
        my $remove = length($value) - $self->{length};
        if ($self->{trimdir} eq 'right') {
            substr($value, $self->{length}, $remove, '');
        } elsif ($self->{trimdir} eq 'left') {
            substr($value, 0, $remove, '');
        }
    }
    return $value;
}

#package Data::ParseBinary::StringAdapter;
#our @ISA = qw{Data::ParseBinary::Adapter};
#
#sub _init {
#    my ($self, $encoding) = @_;
#    $self->{encoding} = $encoding;
#}
#
#sub _decode {
#    my ($self, $value) = @_;
#    my $tvalue;
#    if ($self->{encoding}) {
#        die "TODO: Should implement different encodings";
#    } else {
#        $tvalue = $value;
#    }
#    return $tvalue;
#}
#
#sub _encode {
#    my ($self, $tvalue) = @_;
#    my $value;
#    if ($self->{encoding}) {
#        die "TODO: Should implement different encodings";
#    } else {
#        $value = $tvalue;
#    }
#    return $value;
#}

package Data::ParseBinary::CStringAdapter;
our @ISA = qw{Data::ParseBinary::Adapter};

sub _init {
    my ($self, $terminators) = @_;
    $self->{regex} = qr/[$terminators]*\z/;
    $self->{terminator} = substr($terminators, 0, 1);
}

sub _decode {
    my ($self, $value) = @_;
    $value =~ s/$self->{regex}//;
    return $value;
}

sub _encode {
    my ($self, $tvalue) = @_;
    return $tvalue . $self->{terminator};
}

package Data::ParseBinary::LamdaValidator;
our @ISA = qw{Data::ParseBinary::Validator};

sub _init {
    my ($self, @params) = @_;
    $self->{coderef} = shift @params;
}

sub _validate {
    my ($self, $value) = @_;
    return $self->{coderef}->($value);
}

package Data::ParseBinary::FirstUnitAndTheRestAdapter;
our @ISA = qw{Data::ParseBinary::Adapter};
# this adapter move from a length of bytes, to one unit and the rest
# as an array

sub _init {
    my ($self, $unit_length, $first_name, $the_rest) = @_;
    $first_name ||= 'FirstUnit';
    $the_rest ||= 'TheRest';
    $self->{unit_length} = $unit_length;
    $self->{first_name} = $first_name;
    $self->{the_rest} = $the_rest;
}

sub _decode {
    my ($self, $value) = @_;
    $value = join('', $value->{$self->{first_name}}, @{ $value->{$self->{the_rest}} } );
    return $value;
}

sub _encode {
    my ($self, $tvalue) = @_;
    my $u_len = $self->{unit_length};
    die "Length of input should be dividable by unit_length" unless length($tvalue) % $u_len == 0;
    my @units = map substr($tvalue, $_*$u_len, $u_len), 0..(length($tvalue) / $u_len - 1);
    my $first = shift @units;
    my $value = { $self->{first_name} => $first, $self->{the_rest} => \@units };
    return $value;
}

package Data::ParseBinary::CharacterEncodingAdapter;
our @ISA = qw{Data::ParseBinary::Adapter};

sub _init {
    my ($self, $encoding) = @_;
    $self->{encoding} = $encoding;
    require Encode;
}

sub _decode {
    my ($self, $octets) = @_;
    my $string = Encode::decode($self->{encoding}, $octets);
    return $string;
}

sub _encode {
    my ($self, $string) = @_;
    my $octets = Encode::encode($self->{encoding}, $string);
    return $octets;
}

package Data::ParseBinary::ExtendedNumberAdapter;
our @ISA = qw{Data::ParseBinary::Adapter};

sub _init {
    my ($self, $is_signed, $is_bigendian) = @_;
    $self->{is_signed} = $is_signed;
    $self->{is_bigendian} = $is_bigendian;
    require Math::BigInt;
}

sub _decode {
    my ($self, $value) = @_;
    if (not $self->{is_bigendian}) {
        $value = join '', reverse split '', $value;
    }
    my $is_negative;
    if ($self->{is_signed}) {
        my $first_char = ord($value);
        if ($first_char > 127) {
            $value = ~$value;
            $is_negative = 1;
        }
    }
    
    my $hexed = unpack "H*", $value;
    my $number = Math::BigInt->new("0x$hexed");
    if ($is_negative) {
        $number->binc()->bneg();
    }
    return $number;
}

sub _encode {
    my ($self, $number) = @_;
    $number = Math::BigInt->new($number);

    my $is_negative;
    if ($self->{is_signed}) {
        if ($number->sign() eq '-') {
            $is_negative = 1;
            $number->binc()->babs();
        }
    } else {
        if ($number->sign() eq '-') {
            die "Was given a negative number for unsigned integer";
        }
    }
    
    my $hexed = $number->as_hex();
    substr($hexed, 0, 2, '');
    my $packed = pack "H*", ("0"x(16-length($hexed))).$hexed;
    if ($is_negative) {
        $packed = ~$packed;
    }
    if (not $self->{is_bigendian}) {
        $packed = join '', reverse split '', $packed;
    }
    return $packed;
}



1;