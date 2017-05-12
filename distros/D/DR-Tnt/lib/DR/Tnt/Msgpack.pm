use utf8;
use strict;
use warnings;

package DR::Tnt::Msgpack;
use base qw(Exporter);
our @EXPORT = qw(msgpack msgunpack msgunpack_check msgunpack_utf8);
use Scalar::Util ();
use Carp;
$Carp::Internal{ (__PACKAGE__) }++;
use feature 'state';
use DR::Tnt::Msgpack::Types ':all';

sub _retstr($$) {
    my ($str, $utf8) = @_;
    utf8::decode $str if $utf8;
    return $str;
}

sub _msgunpack($$);
sub _extract_hash_elements($$$$) {
    my ($str, $len, $size, $utf8) = @_;

    my %o;
    for (my $i = 0; $i < $size; $i++) {
        my ($k, $klen) = _msgunpack(substr($str, $len), $utf8);
        return unless defined $klen;
        $len += $klen;

        my ($v, $vlen) = _msgunpack(substr($str, $len), $utf8);
        return unless defined $vlen;
        $len += $vlen;

        $o{$k} = $v;
    }
    return \%o, $len;
}

sub _extract_array_elements($$$$) {
    my ($str, $len, $size, $utf8) = @_;

    my @o;
    for (my $i = 0; $i < $size; $i++) {
        my ($e, $elen) = _msgunpack(substr($str, $len), $utf8);
        return unless defined $elen;
        $len += $elen;
        push @o => $e;
    }
    return \@o, $len;
}


sub _msgunpack($$) {
    my ($str, $utf8) = @_;

    return unless defined $str and length $str;

    my $tag = unpack 'C', $str;

    # fix uint
    return ($tag, 1) if $tag <= 0x7F;
    
    # fix negative
    return (unpack('c', $str), 1) if $tag >= 0xE0;

    # fix str
    if (($tag & ~0x1F) == 0xA0) {
        my $len = $tag & 0x1F;
        return unless length($str) >= 1 + $len;
        return '', 1 unless $len;
        return (_retstr(unpack("x[C]a$len", $str), $utf8), 1 + $len);
    }

    # fix map
    if (($tag & ~0x0F) == 0x80) {
        my $size = $tag & 0x0F;
        return _extract_hash_elements($str, 1, $size, $utf8);
    }

    # fix array
    if (($tag & ~0x0F) == 0x90) {
        my $size = $tag & 0x0F;
        return _extract_array_elements($str, 1, $size, $utf8);
    }


    state $variant = {
        (0xD0)      => sub {        # int8
            my ($str) = @_;
            return unless length($str) >= 2;
            return (unpack('x[C]c', $str), 2); 
        },
        (0xD1)      => sub {        # int16
            my ($str) = @_;
            return unless length($str) >= 3;
            return (unpack('x[C]s>', $str), 3); 
        },
        (0xD2)      => sub {        # int32
            my ($str) = @_;
            return unless length($str) >= 5;
            return (unpack('x[C]l>', $str), 5); 
        },
        (0xD3)      => sub {        # int64
            my ($str) = @_;
            return unless length($str) >= 9;
            return (unpack('x[C]q>', $str), 9); 
        },


        (0xCC)      => sub {        # uint8
            my ($str) = @_;
            return unless length($str) >= 2;
            return (unpack('x[C]C', $str), 2); 
        },
        (0xCD)      => sub {        # uint16
            my ($str) = @_;
            return unless length($str) >= 3;
            return (unpack('x[C]S>', $str), 3); 
        },
        (0xCE)      => sub {        # uint32
            my ($str) = @_;
            return unless length($str) >= 5;
            return (unpack('x[C]L>', $str), 5); 
        },
        (0xCF)      => sub {        # uint64
            my ($str) = @_;
            return unless length($str) >= 9;
            return (unpack('x[C]Q>', $str), 9); 
        },

        (0xC0)      => sub {        # null
            return (undef, 1);
        },

        (0xC2)      => sub {
            return (mp_false, 1);          # false
        },
        (0xC3)      => sub {
            return (mp_true, 1);          # true
        },

        (0xC4)      => sub {        # bin8
            my ($str) = @_;
            return unless length($str) >= 2;
            my $len = unpack('x[C]C', $str);
            return unless length($str) >= 2 + $len;
            return (unpack("x[C]C/a", $str), 2 + $len);
        },
        (0xC5)      => sub {        # bin16
            my ($str) = @_;
            return unless length($str) >= 3;
            my $len = unpack('x[C]S>', $str);
            return unless length($str) >= 3 + $len;
            return (unpack("x[C]S>/a", $str), 3 + $len);
        },
        (0xC6)      => sub {        # bin32
            my ($str) = @_;
            return unless length($str) >= 5;
            my $len = unpack('x[C]L>', $str);
            return unless length($str) >= 5 + $len;
            return (unpack("x[C]L>/a", $str), 5 + $len);
        },


        (0xD9)      => sub {        # str8
            my ($str, $utf8) = @_;
            return unless length($str) >= 2;
            my ($len) = unpack('x[C]C', $str);
            return unless length($str) >= 2 + $len;
            return (_retstr(unpack("x[C]C/a", $str), $utf8), 2 + $len);
        },
        (0xDA)      => sub {        # str16
            my ($str, $utf8) = @_;
            return unless length($str) >= 3;
            my $len = unpack('x[C]S>', $str);
            return unless length($str) >= 3 + $len;
            return (_retstr(unpack("x[C]S>/a", $str), $utf8), 3 + $len);
        },

        (0xDB)      => sub {        # str32
            my ($str, $utf8) = @_;
            return unless length($str) >= 5;
            my $len = unpack('x[C]L>', $str);
            return unless length($str) >= 5 + $len;
            return (_retstr(unpack("x[C]L>/a", $str), $utf8), 5 + $len);
        },


        (0xDC)      => sub {        #array16
            my ($str, $utf8) = @_;
            return unless length($str) >= 3;
            my $size = unpack('x[C]S>', $str);
            return _extract_array_elements($str, 3, $size, $utf8);
        },
        (0xDD)      => sub {        #array32
            my ($str, $utf8) = @_;
            return unless length($str) >= 5;
            my $size = unpack('x[C]L>', $str);
            return _extract_array_elements($str, 5, $size, $utf8);
        },
        
        (0xDE)      => sub {        #map16
            my ($str, $utf8) = @_;
            return unless length($str) >= 3;
            my $size = unpack('x[C]S>', $str);
            return _extract_hash_elements($str, 3, $size, $utf8);
        },
        (0xDF)      => sub {        #map32
            my ($str, $utf8) = @_;
            return unless length($str) >= 5;
            my $size = unpack('x[C]L>', $str);
            return _extract_hash_elements($str, 5, $size, $utf8);
        },

        (0xCA)      => sub {    # float32
            my ($str, $utf8) = @_;
            return unless length($str) >= 5;
            return (unpack('x[C]f>', $str), 5);
        },
        (0xCB)      => sub {    # float64
            my ($str, $utf8) = @_;
            return unless length($str) >= 9;
            return (unpack('x[C]d>', $str), 9);
        },
    };

    return $variant->{$tag}($str, $utf8) if exists $variant->{$tag};
  

    warn sprintf "%02X", $tag;
    return;




}

sub msgunpack($) {
    my ($str) = @_;
    my ($o, $len) = _msgunpack($str, 0);
    croak 'Input buffer does not contain valid msgpack' unless defined $len;
    return $o;
}

sub msgunpack_utf8($) {
    my ($str) = @_;
    my ($o, $len) = _msgunpack($str, 1);
    croak 'Input buffer does not contain valid msgpack' unless defined $len;
    return $o;
}

sub msgunpack_check($) {
    my ($str) = @_;
    my ($o, $len) = _msgunpack($str, 1);
    return $len // 0;
}

sub msgunpack_safely($) {
    push @_ => 0;
    goto \&_msgunpack;
}

sub msgunpack_safely_utf8($) {
    push @_ => 1;
    goto \&_msgunpack;
}

sub msgpack($);
sub msgpack($) {
    my ($v) = @_;

    if (ref $v) {
        if ('ARRAY' eq ref $v) {
            my $size = @$v;
            my $res;

            if ($size <= 0xF) {
                $res = pack 'C', 0x90 | $size;
            } elsif ($size <= 0xFFFF) {
                $res = pack 'CS>', 0xDC, $size;
            } else {
                $res = pack 'CL>', 0xDD, $size;
            }

            $res .= msgpack($_) for @$v;
            return $res;

        } elsif ('HASH' eq ref $v) {
            my $size = scalar keys %$v;
            
            my $res;

            if ($size <= 0xF) {
                $res = pack 'C', 0x80 | $size;
            } elsif ($size <= 0xFFFF) {
                $res = pack 'CS>', 0xDE, $size;
            } else {
                $res = pack 'CL>', 0xDF, $size;
            }

            while (my ($k, $v) = each %$v) {
                $res .= msgpack($k);
                $res .= msgpack($v);
            }
            return $res;

        } elsif (Scalar::Util::blessed $v) {
            return $v->TO_MSGPACK if $v->can('TO_MSGPACK');
            if ($v->can('TO_JSON')) {
                my $vj = $v->TO_JSON;
                return pack 'C', 0xC3 if "$vj" eq 'true';
                return pack 'C', 0xC2;
            }
            if ('JSON::XS::Boolean' eq ref $v) {
                return pack 'C', 0xC3 if $v;
                return pack 'C', 0xC2;
            }
            if ('Types::Serialiser::Boolean' eq ref $v) {
                return pack 'C', 0xC3 if $v;
                return pack 'C', 0xC2;
            }
            if ('JSON::PP::Boolean' eq ref $v) {
                return pack 'C', 0xC3 if $v;
                return pack 'C', 0xC2;
            }
            croak "Can't msgpack blessed value " . ref $v;
        } else {
            croak "Can't msgpack value " . ref $v;
        }
    } else {
        # numbers
        if (Scalar::Util::looks_like_number $v) {
            if ($v == int $v) {
                if ($v >= 0) {
                    if ($v <= 0x7F) {
                        return pack 'C', $v;
                    } elsif ($v <= 0xFF) {
                        return pack 'CC', 0xCC, $v;
                    } elsif ($v <= 0xFFFF) {
                        return pack 'CS>', 0xCD, $v;
                    } elsif ($v <= 0xFFFF_FFFF) {
                        return pack 'CL>', 0xCE, $v;
                    } else {
                        return pack 'CQ>', 0xCF, $v;
                    }
                }
                if ($v >= - 0x20) {
                    return pack 'c', $v;
                } elsif ($v >= -0x7F - 1) {
                    return pack 'Cc', 0xD0, $v;
                } elsif ($v >= -0x7F_FF - 1) {
                    return pack 'Cs>', 0xD1, $v;
                } elsif ($v >= -0x7FFF_FFFF - 1) {
                    return pack 'Cl>', 0xD2, $v;
                } else {
                    return pack 'Cq>', 0xD3, $v;
                }
            } else {
                return pack 'Cd>', 0xCB, $v;
            }

        } else {
            unless (defined $v) {           # undef
                return pack 'C', 0xC0;
            }
            if (utf8::is_utf8 $v) {
                utf8::encode $v;
            }
            # strings
            if (length($v) <= 0x1F) {
                return pack 'Ca*',
                    (0xA0 | length $v),
                    $v;
            } elsif (length($v) <= 0xFF) {
                return pack 'CCa*',
                    0xD9,
                    length $v,
                    $v;
            } elsif (length($v) <= 0xFFFF) {
                return pack 'CS>a*',
                    0xDA,
                    length $v,
                    $v;
            } else {
                return pack 'CL>a*',
                    0xDB,
                    length $v,
                    $v;
            }

        }
    }
}

=head1 NAME

DR::Tnt::Msgpack - msgpack encoder/decoder.

=head1 SYNOPSIS

    use DR::Tnt::Msgpack;
    use DR::Tnt::Msgpack::Types ':all';  # mp_*

    
    my $blob = msgpack { a => 'b', c => 123, d => [ 3, 4, 5 ] };
    
    my $object = msgunpack $blob;
    my $object = msgunpack_utf8 $blob;
    
    
    my ($object, $len) = msgunpack_safely $blob;
    my ($object, $len) = msgunpack_safely_utf8 $blob;

    if (defined $len) {
        substr $blob, 0, $len, '';
        ...
    }

    if (my $len = msgunpack_check $blob) {
        # $blob contains msgpack with len=$len
    }

=head1 METHODS

=head2 msgpack

    my $blob = msgpack $scalar;
    my $blob = msgpack \%hash;
    my $blob = msgpack \@array;

Pack any perl object to msgpack. Blessed objects have to have C<TO_MSGPACK>
methods.

=head2 msgunpack

Unpack msgpack'ed string to perl object. Throws exception if buffer is invalid.
Booleans are extracted to L<DR::Tnt::Msgpack::Types::Bool>,
see also L<DR::Tnt::Msgpack::Types>.

=head2 msgunpack_utf8

The same as L</msgunpack>. Decode utf8 for each string.

=head2 msgunpack_safely, msgunpack_safely_utf8

Unpack msgpack'ed string to perl object.
Don't throw exception if buffer is invalid.

Return unpacked object and length of unpacked object. If length is C<undef>,
buffer is invalid.

=cut

1;
