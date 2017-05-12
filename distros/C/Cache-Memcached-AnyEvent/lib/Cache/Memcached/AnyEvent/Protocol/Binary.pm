package Cache::Memcached::AnyEvent::Protocol::Binary;
use strict;
use base 'Cache::Memcached::AnyEvent::Protocol';
use bytes;
use constant HEADER_SIZE => 24;
use constant HAS_64BIT => do {
    no strict;
    require Config;
    $Config{use64bitint} || $Config{use64bitall};
};

#   General format of a packet:
#
#     Byte/     0       |       1       |       2       |       3       |
#        /              |               |               |               |
#       |0 1 2 3 4 5 6 7|0 1 2 3 4 5 6 7|0 1 2 3 4 5 6 7|0 1 2 3 4 5 6 7|
#       +---------------+---------------+---------------+---------------+
#      0/ HEADER                                                        /
#       /                                                               /
#       /                                                               /
#       /                                                               /
#       +---------------+---------------+---------------+---------------+
#     16/ COMMAND-SPECIFIC EXTRAS (as needed)                           /
#      +/  (note length in th extras length header field)               /
#       +---------------+---------------+---------------+---------------+
#      m/ Key (as needed)                                               /
#      +/  (note length in key length header field)                     /
#       +---------------+---------------+---------------+---------------+
#      n/ Value (as needed)                                             /
#      +/  (note length is total body length header field, minus        /
#      +/   sum of the extras and key length body fields)               /
#       +---------------+---------------+---------------+---------------+
#      Total 16 bytes
#
#   Request header:
#
#     Byte/     0       |       1       |       2       |       3       |
#        /              |               |               |               |
#       |0 1 2 3 4 5 6 7|0 1 2 3 4 5 6 7|0 1 2 3 4 5 6 7|0 1 2 3 4 5 6 7|
#       +---------------+---------------+---------------+---------------+
#      0| Magic         | Opcode        | Key length                    |
#       +---------------+---------------+---------------+---------------+
#      4| Extras length | Data type     | Reserved                      |
#       +---------------+---------------+---------------+---------------+
#      8| Total body length                                             |
#       +---------------+---------------+---------------+---------------+
#     12| Opaque                                                        |
#       +---------------+---------------+---------------+---------------+
#     16| CAS                                                           |
#       |                                                               |
#       +---------------+---------------+---------------+---------------+
#       Total 24 bytes
#
#   Response header:
#
#     Byte/     0       |       1       |       2       |       3       |
#        /              |               |               |               |
#       |0 1 2 3 4 5 6 7|0 1 2 3 4 5 6 7|0 1 2 3 4 5 6 7|0 1 2 3 4 5 6 7|
#       +---------------+---------------+---------------+---------------+
#      0| Magic         | Opcode        | Status                        |
#       +---------------+---------------+---------------+---------------+
#      4| Extras length | Data type     | Reserved                      |
#       +---------------+---------------+---------------+---------------+
#      8| Total body length                                             |
#       +---------------+---------------+---------------+---------------+
#     12| Opaque                                                        |
#       +---------------+---------------+---------------+---------------+
#     16| CAS                                                           |
#       |                                                               |
#       +---------------+---------------+---------------+---------------+
#       Total 24 bytes
#
#   Header fields:
#   Magic               Magic number.
#   Opcode              Command code.
#   Key length          Length in bytes of the text key that follows the
#                       command extras.
#   Status              Status of the response (non-zero on error).
#   Extras length       Length in bytes of the command extras.
#   Data type           Reserved for future use (Sean is using this
#                       soon).
#   Reserved            Really reserved for future use (up for grabs).
#   Total body length   Length in bytes of extra + key + value.
#   Opaque              Will be copied back to you in the response.
#   CAS                 Data version check.

# Constants
use constant +{
#    Magic numbers
    REQ_MAGIC       => 0x80,
    RES_MAGIC       => 0x81,

#    Status Codes
#    0x0000  No error
#    0x0001  Key not found
#    0x0002  Key exists
#    0x0003  Value too large
#    0x0004  Invalid arguments
#    0x0005  Item not stored
#    0x0006  Incr/Decr on non-numeric value.
    ST_SUCCESS      => 0x0000,
    ST_NOT_FOUND    => 0x0001,
    ST_EXISTS       => 0x0002,
    ST_TOO_LARGE    => 0x0003,
    ST_INVALID      => 0x0004,
    ST_NOT_STORED   => 0x0005,
    ST_NON_NUMERIC  => 0x0006,

#    Opcodes
    MEMD_GET        => 0x00,
    MEMD_SET        => 0x01,
    MEMD_ADD        => 0x02,
    MEMD_REPLACE    => 0x03,
    MEMD_DELETE     => 0x04,
    MEMD_INCREMENT  => 0x05,
    MEMD_DECREMENT  => 0x06,
    MEMD_QUIT       => 0x07,
    MEMD_FLUSH      => 0x08,
    MEMD_GETQ       => 0x09,
    MEMD_NOOP       => 0x0A,
    MEMD_VERSION    => 0x0B,
    MEMD_GETK       => 0x0C,
    MEMD_GETKQ      => 0x0D,
    MEMD_APPEND     => 0x0E,
    MEMD_PREPEND    => 0x0F,
    MEMD_STAT       => 0x10,
    MEMD_SETQ       => 0x11,
    MEMD_ADDQ       => 0x12,
    MEMD_REPLACEQ   => 0x13,
    MEMD_DELETEQ    => 0x14,
    MEMD_INCREMENTQ => 0x15,
    MEMD_DECREMENTQ => 0x16,
    MEMD_QUITQ      => 0x17,
    MEMD_FLUSHQ     => 0x18,
    MEMD_APPENDQ    => 0x19,
    MEMD_PREPENDQ   => 0x1A,
    RAW_BYTES       => 0x00,
};

my $OPAQUE;
BEGIN {
    $OPAQUE = 0xffffffff;
}

# binary protocol read type
AnyEvent::Handle::register_read_type memcached_bin => sub {
    my ($self, $cb) = @_;

    my %state = ( waiting_header => 1 );
    sub {
        return unless $_[0]{rbuf};

        my $rbuf_ref = \$_[0]{rbuf};
        if ($state{waiting_header}) {
            return if length $$rbuf_ref < HEADER_SIZE;

            my $header = substr $$rbuf_ref, 0, HEADER_SIZE, '';
            my ($i1, $i2, $i3, $i4, $i5, $i6) = unpack('N6', $header);
            $state{magic}             = $i1 >> 24;
            $state{opcode}            = ($i1 & 0x00ff0000) >> 16;
            $state{key_length}        = ($i1 & 0x0000ffff);
            $state{extra_length}      = ($i2 & 0xff000000) >> 24;
            $state{data_type}         = ($i2 & 0x00ff0000) >> 8;
            $state{status}            = ($i2 & 0x0000ffff);
            $state{total_body_length} = $i3;
            $state{opaque}            = $i4;

            if (HAS_64BIT) {
                $state{cas} = $i5 << 32 + $i6;
            } else {
                warn "overflow on CAS" if ($i5 || 0) != 0;
                $state{cas} = $i6;
            }

            delete $state{waiting_header};
        }

        if ($state{total_body_length}) {
            return if length $$rbuf_ref < $state{total_body_length};

            $state{extra} = substr $$rbuf_ref, 0, $state{extra_length}, '';
            $state{key} = substr $$rbuf_ref, 0, $state{key_length}, '';


            my $value_len = $state{total_body_length} - ($state{key_length} + $state{extra_length});
            $state{value} = substr $$rbuf_ref, 0, $value_len, '';
        }

        $cb->( \%state );
        undef %state;
        1;
    }
};

sub prepare_handle {
    my ($self, $fh) = @_;
    binmode($fh);
}

AnyEvent::Handle::register_write_type memcached_bin => sub {
    my ($self, $opcode, $key, $extras, $body, $cas, $data_type, $reserved ) = @_;
    my $key_length = defined $key ? length($key) : 0;
    # first 4 bytes (long)
    my $i1 = 0;
    $i1 ^= REQ_MAGIC << 24;
    $i1 ^= $opcode << 16;
    $i1 ^= $key_length;

    # second 4 bytes
    my $i2 = 0;
    my $extra_length = 
        ($opcode != MEMD_PREPEND && $opcode != MEMD_APPEND && defined $extras) ?
        length($extras) :
        0
    ;
    if ($extra_length) {
        $i2 ^= $extra_length << 24;
    }
    # $data_type and $reserved are not used currently

    # third 4 bytes
    my $body_length  = defined $body ? length($body) : 0;
    my $i3 = $body_length + $key_length + $extra_length;

    # this is the opaque value, which will be returned with the response
    my $i4 = $OPAQUE;
    if ($OPAQUE == 0xffffffff) {
        $OPAQUE = 0;
    } else {
        $OPAQUE++;
    }

    # CAS is 64 bit, which is troublesome on 32 bit architectures.
    # we will NOT allow 64 bit CAS on 32 bit machines for now.
    # better handling by binary-adept people are welcome
    $cas ||= 0;
    my ($i5, $i6);
    if (HAS_64BIT) {
        no warnings;
        $i5 = 0xffffffff00000000 & $cas;
        $i6 = 0x00000000ffffffff & $cas;
    } else {
        $i5 = 0x00000000;
        $i6 = $cas;
    }

    my $message = pack( 'N6', $i1, $i2, $i3, $i4, $i5, $i6 );
    if (length($message) > HEADER_SIZE) {
        Carp::confess "header size assertion failed";
    }

    if ($extra_length) {
        $message .= $extras;
    }
    if ($key_length) {
        $message .= pack('a*', $key);
    }
    if ($body_length) {
        $message .= pack('a*', $body);
    }

    return $message;
};

sub _status_str {
    my $status = shift;
    my %strings = (
        ST_SUCCESS() => "Success",
        ST_NOT_FOUND() => "Not found",
        ST_EXISTS() => "Exists",
        ST_TOO_LARGE() => "Too Large",
        ST_INVALID() => "Invalid Arguments",
        ST_NOT_STORED() => "Not Stored",
        ST_NON_NUMERIC() => "Incr/Decr on non-numeric variables"
    );
    return $strings{$status};
}

# Generate setters
{
    my $generator = sub {
        my ($cmd, $opcode) = @_;

        sub {
            my ($self, $memcached, $key, $value, $expires, $noreply, $cb) = @_;
            return sub {
                my $guard = shift;
                my $fq_key = $memcached->_prepare_key( $key );
                my $handle = $memcached->_get_handle_for( $key );
                my $length = 0;
                my $flags  = 0;

                if ($memcached->should_serialize($value)) {
                    $memcached->serialize(\$value, \$length, \$flags);
                } else {
                    $length = bytes::length($value);
                }

                # START CHECK_COMPRESSION
                # Don't even check for should_compress if we're not
                # allowed to do so
                if ($memcached->should_compress($length)) {
                    $memcached->compress(\$value, \$length, \$flags);
                }
                # END CHECK_COMPRESSION

                my $extras = pack('N2', $flags, $expires || 0);

                $handle->push_write( memcached_bin => $opcode, $fq_key, $extras, $value );
                $handle->push_read( memcached_bin => sub {
                    undef $guard;
                    $cb->($_[0]->{status} == 0, $_[0]->{value}, $_[0]);
                });
            }
        };
    };

    *add     = $generator->("add", MEMD_ADD);
    *replace = $generator->("replace", MEMD_REPLACE);
    *set     = $generator->("set", MEMD_SET);
    *append  = $generator->("append", MEMD_APPEND);
    *prepend = $generator->("prepend", MEMD_PREPEND);
}

sub delete {
    my ($self, $memcached, $key, $noreply, $cb) = @_;

    return sub {
        my $guard = shift;
        my $fq_key = $memcached->_prepare_key($key);
        my $handle = $memcached->_get_handle_for($key);

        $handle->push_write( memcached_bin => MEMD_DELETE, $fq_key );
        $handle->push_read( memcached_bin => sub {
            undef $guard;
            $cb->(@_);
        } );
    }
}

sub get {
    my ($self, $memcached, $key, $cb) = @_;

    return sub {
        my $guard = shift;
        my $fq_key = $memcached->_prepare_key( $key );
        my $handle = $memcached->_get_handle_for( $key );
        $handle->push_write(memcached_bin => MEMD_GETK, $fq_key);
        $handle->push_read(memcached_bin => sub {
            my $msg = shift;
            my ($flags, $exptime) = unpack('N2', $msg->{extra});
            if (exists $msg->{key} && exists $msg->{value}) {
                my $value = $msg->{value};
                $memcached->deserialize(\$flags, \$value);
                $cb->($value);
            } else {
                $cb->();
            }
            
            undef $guard;
        });
    }
}

sub get_multi {
    my ($self, $memcached, $keys, $cb) = @_;

    return sub {
        my $guard = shift;
        # organize the keys by handle
        my %handle2keys;

        if (! @$keys) {
            undef $guard;
            $cb->({});
            return;
        }

        foreach my $key (@$keys) {
            my $fq_key = $memcached->_prepare_key( $key );
            my $handle = $memcached->_get_handle_for( $key );
            my $list = $handle2keys{ $handle };
            if (! $list) {
                $list = $handle2keys{$handle} = [ $handle ];
            }
            push @$list, $fq_key;
        }

        my %rv;
        my $cv = AE::cv {
            undef $guard;
            $cb->( \%rv );
        };

        foreach my $list (values %handle2keys) {
            my ($handle, @keys) = @$list;
            foreach my $key ( @keys ) {
                $handle->push_write(memcached_bin => MEMD_GETK, $key);
                $cv->begin;
                $handle->push_read(memcached_bin => sub {
                    my $msg = shift;
    
                    my ($flags, $exptime) = unpack('N2', $msg->{extra});
                    if (exists $msg->{key} && exists $msg->{value}) {
                        my $value = $msg->{value};
                        $memcached->normalize_key(\$key);
                        $memcached->deserialize(\$flags, \$value);
                        $rv{ $key } = $value;
                    }
                    $cv->end;
                });
            }
        }
    }
}
    
{
    my $generator = sub {
        my ($opcode) = @_;
        return sub {
            my ($self, $memcached, $key, $value, $initial, $cb) = @_;

            return sub {
                my $guard = shift;
                $value ||= 1;
                my $expires = defined $initial ? 0 : 0xffffffff;
                $initial ||= 0;
                my $fq_key = $memcached->_prepare_key( $key );
                my $handle = $memcached->_get_handle_for($key);
                my $extras;
                if (HAS_64BIT) {
                    $extras = pack('Q2L', $value, $initial, $expires );
                } else {
                    $extras = pack('N5', 0, $value, 0, $initial, $expires );
                }

                $handle->push_write(memcached_bin => 
                    $opcode, $fq_key, $extras, undef, undef, undef, undef);
                $handle->push_read(memcached_bin => sub {
                   undef $guard;
                    my $value;
                    if (HAS_64BIT) {
                        $value = unpack('Q', $_[0]->{value});
                    } else {
                        (undef, $value) = unpack('N2', $_[0]->{value});
                    }
   
                    $cb->($_[0]->{status} == 0 ? $value : undef, $_[0]);
                });
            }
        }
    };

    *incr = $generator->(MEMD_INCREMENT);
    *decr = $generator->(MEMD_DECREMENT);
};

sub version {
    my ($self, $memcached, $cb) = @_;

    return sub {
        my $guard = shift;
        my %ret;
        my $cv = AE::cv { $cb->( \%ret ); undef %ret };
        while (my ($host_port, $handle) = each %{ $memcached->{_server_handles} }) {
            $handle->push_write(memcached_bin => MEMD_VERSION);
            $cv->begin;
            $handle->push_read(memcached_bin => sub {
                my $msg = shift;
                undef $guard;
                my $value = unpack('a*', $msg->{value});

                $ret{ $host_port } = $value;
                $cv->end;
            });
        }
    }
}
        
sub flush_all {
    my ($self, $memcached, $delay, $noreply, $cb) = @_;

    return sub {
        my $guard = shift;
        my $cv = AE::cv {
            undef $guard;
            $cb->(1);
        };

        while (my ($host_port, $handle) = each %{ $memcached->{_server_handles} }) {
            $cv->begin;
            $handle->push_write(memcached_bin => MEMD_FLUSH);
            $handle->push_read(memcached_bin => sub { $cv->send });
        }
    }
}

1;

__END__

=head1 NAME

Cache::Memcached::AnyEvent::Protocol::Binary - Implements Memcached Binary Protocol

=head1 SYNOPSIS

    use Cache::Memcached::AnyEvent;
    my $memd = Cache::Memcached::AnyEvent->new({
        ...
        protocol_class => 'Binary'
    });

=head1 METHODS

=head2 add

=head2 append

=head2 decr

=head2 delete

=head2 flush_all

=head2 get

=head2 get_multi

=head2 incr

=head2 prepare_handle

=head2 prepend

=head2 replace

=head2 set

=head2 stats

=head2 version

=cut

