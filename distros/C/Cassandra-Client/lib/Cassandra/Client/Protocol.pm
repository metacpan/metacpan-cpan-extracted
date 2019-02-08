package Cassandra::Client::Protocol;
our $AUTHORITY = 'cpan:TVDW';
$Cassandra::Client::Protocol::VERSION = '0.16';
use 5.010;
use strict;
use warnings;

use Encode;

require Exporter;
our @ISA= qw(Exporter);

use Cassandra::Client::Error::Base;
use Cassandra::Client::Error::ReadTimeoutException;
use Cassandra::Client::Error::WriteTimeoutException;
use Cassandra::Client::Error::UnavailableException;

use constant BIGINT_SUPPORTED => eval { unpack('q>', "\0\0\0\0\0\0\0\1") };
use if !BIGINT_SUPPORTED, 'Math::BigInt';

our (@EXPORT_OK, %EXPORT_TAGS);
our (%consistency_lookup, %batch_type_lookup);
BEGIN {
    my %constants= (
        OPCODE_ERROR => 0,
        OPCODE_STARTUP => 1,
        OPCODE_READY => 2,
        OPCODE_AUTHENTICATE => 3,
        OPCODE_OPTIONS => 5,
        OPCODE_SUPPORTED => 6,
        OPCODE_QUERY => 7,
        OPCODE_RESULT => 8,
        OPCODE_PREPARE => 9,
        OPCODE_EXECUTE => 10,
        OPCODE_REGISTER => 11,
        OPCODE_EVENT => 12,
        OPCODE_BATCH => 13,
        OPCODE_AUTH_CHALLENGE => 14,
        OPCODE_AUTH_RESPONSE => 15,
        OPCODE_AUTH_SUCCESS => 16,

        RESULT_VOID => 1,
        RESULT_ROWS => 2,
        RESULT_SET_KEYSPACE => 3,
        RESULT_PREPARED => 4,
        RESULT_SCHEMA_CHANGE => 5,

        CONSISTENCY_ANY => 0,
        CONSISTENCY_ONE => 1,
        CONSISTENCY_TWO => 2,
        CONSISTENCY_THREE => 3,
        CONSISTENCY_QUORUM => 4,
        CONSISTENCY_ALL => 5,
        CONSISTENCY_LOCAL_QUORUM => 6,
        CONSISTENCY_EACH_QUORUM => 7,
        CONSISTENCY_SERIAL => 8,
        CONSISTENCY_LOCAL_SERIAL => 9,
        CONSISTENCY_LOCAL_ONE => 10,

        TYPE_CUSTOM => 0x00,
        TYPE_ASCII => 0x01,
        TYPE_BIGINT => 0x02,
        TYPE_BLOB => 0x03,
        TYPE_BOOLEAN => 0x04,
        TYPE_COUNTER => 0x05,
        TYPE_DECIMAL => 0x06,
        TYPE_DOUBLE => 0x07,
        TYPE_FLOAT => 0x08,
        TYPE_INT => 0x09,
        TYPE_TEXT => 0x0A, # deprecated/removed
        TYPE_TIMESTAMP => 0x0B,
        TYPE_UUID => 0x0C,
        TYPE_VARCHAR => 0x0D,
        TYPE_VARINT => 0x0E,
        TYPE_TIMEUUID => 0x0F,
        TYPE_INET => 0x10,
        TYPE_DATE => 0x11,
        TYPE_TIME => 0x12,
        TYPE_SMALLINT => 0x13,
        TYPE_TINYINT => 0x14,
        TYPE_LIST => 0x20,
        TYPE_MAP => 0x21,
        TYPE_SET => 0x22,
        TYPE_UDT => 0x30,
        TYPE_TUPLE => 0x31,
    );

    @EXPORT_OK= (
        keys %constants,
        qw/
            pack_int                unpack_int
            pack_long
            pack_short              unpack_short
            pack_string             unpack_string
            pack_longstring
            pack_stringlist         unpack_stringlist
            pack_bytes              unpack_bytes
            pack_shortbytes         unpack_shortbytes
            pack_option_type
            pack_stringmap
            pack_stringmultimap     unpack_stringmultimap
                                    unpack_inet
                                    unpack_char

            pack_metadata           unpack_metadata
                                    unpack_errordata
            pack_queryparameters

            %consistency_lookup
            %batch_type_lookup

            BIGINT_SUPPORTED
        /
    );

    %EXPORT_TAGS= (
        constants => [ keys %constants ],
        all => [ @EXPORT_OK ]
    );

    %consistency_lookup= map {
        my $key= $_;
        $key =~ s/CONSISTENCY_//;
        (lc $key) => $constants{$_}
    } grep { /CONSISTENCY/ } keys %constants;

    %batch_type_lookup= (
        logged   => 0,
        unlogged => 1,
        counter  => 2,
    );

    constant->import( { %constants } );
}

# TYPE: int
sub pack_int {
    pack('l>', $_[0])
}

sub unpack_int {
    unpack('l>', substr $_[0], 0, 4, '')
}

# TYPE: long
sub pack_long {
    if (BIGINT_SUPPORTED) {
        return pack('q>', $_[0]);
    } else {
        return bigint_to_bytes($_[0]);
    }
}

# TYPE: short
sub pack_short {
    pack('n', $_[0])
}

sub unpack_short {
    unpack('n', substr $_[0], 0, 2, '')
}

# TYPE: char
sub unpack_char {
    unpack('c', substr $_[0], 0, 1, '')
}

# TYPE: string
sub pack_string {
    if (utf8::is_utf8($_[0])) {
        my $str= $_[0]; # copy
        utf8::encode $str;
        return pack('n/a', $str);
    }

    return pack('n/a', $_[0]);
}

sub unpack_string {
    my $length= &unpack_short;
    if ($length > 0) {
        my $string= substr($_[0], 0, $length, '');
        utf8::decode $string;
        return $string;
    } else {
        return '';
    }
}

# TYPE: longstring
sub pack_longstring {
    if (utf8::is_utf8($_[0])) {
        my $str= $_[0]; # copy
        utf8::encode $str;
        return pack('l>/a', $str);
    }

    return pack('l>/a', $_[0]);
}

# TYPE: stringlist
sub pack_stringlist {
    pack_short(0+@{$_[0]}).join('', map { pack_string($_) } @{$_[0]})
}

sub unpack_stringlist {
    my $count= &unpack_short;
    [ map &unpack_string, 1..$count ]
}

# TYPE: bytes
sub pack_bytes {
    if (utf8::is_utf8($_[0])) {
        warn 'BUG: utf8 data passed to pack_bytes';
        Encode::_utf8_off($_[0]);
    }
    defined $_[0] ? (pack_int(length($_[0])).$_[0]) : pack_int(-1)
}

sub unpack_bytes {
    my $len= &unpack_int;
    if ($len > 0) {
        return substr($_[0], 0, $len, '');

    } elsif ($len < 0) {
        return undef;

    } else {
        return '';
    }
}

# TYPE: shortbytes
sub pack_shortbytes {
    if (utf8::is_utf8($_[0])) {
        warn 'BUG: utf8 data passed to pack_shortbytes';
        Encode::_utf8_off($_[0]);
    }
    defined $_[0] ? (pack_short(length($_[0])).$_[0]) : pack_short(-1)
}

sub unpack_shortbytes {
    my $len= &unpack_short;
    if ($len > 0) {
        return substr($_[0], 0, $len, '');

    } elsif ($len < 0) {
        return undef;

    } else {
        return '';
    }
}

# TYPE: inet
sub unpack_inet {
    my $length= unpack('C', substr($_[0], 0, 1, ''));
    my $tmp_val= substr($_[0], 0, $length, '');

    my $addr;
    if ($length == 4) {
        $addr= join('.', unpack('CCCC', $tmp_val));
    } else {
        $addr= join(':', unpack('(H4)[8]', $tmp_val));
        # Simplify the V6 address
        $addr =~ s/\b0+(\d+)\b/$1/g;
        $addr =~ s/\b0(:0)+\b/:/;
        $addr =~ s/:::/::/;
    }
    return $addr;
}

# TYPE: option_type
sub pack_option_type {
    my ($type)= @_;
    my ($id, @value)= @$type;
    if ($id == TYPE_CUSTOM) {
        return pack_short($id).pack_string($value[0]);
    } elsif ($id < 0x20) {
        return pack_short($id);
    } elsif ($id == TYPE_LIST || $id == TYPE_SET) {
        return pack_short($id).pack_option_type($value[0]);
    } elsif ($id == TYPE_MAP) {
        return pack_short($id).pack_option_type($value[0]).pack_option_type($value[1]);
    } elsif ($id == TYPE_UDT) {
        my $out= pack_short($id).pack_string($value[0]).pack_string($value[1]);
        my @fields= @{$value[2]};
        $out .= pack_short(0+@fields);
        for my $field (@fields) {
            $out .= pack_string($field->[0]).pack_option_type($field->[1]);
        }
        return $out;
    } elsif ($id == TYPE_TUPLE) {
        my @fields= @{$value[0]};
        my $out= pack_short($id).pack_short(0+@fields);
        $out .= pack_option_type($_) for @fields;
        return $out;
    } else {
        die 'Unable to pack_option_type for type '.$id;
    }
}

# TYPE: stringmap
sub pack_stringmap {
    my $pairs= '';
    my $count= 0;
    for my $key (sort keys %{$_[0]}) {
        $pairs .= pack_string($key).pack_string($_[0]{$key});
        $count++;
    }
    return pack_short($count).$pairs;
}

# TYPE: stringmultimap
sub pack_stringmultimap {
    my $pairs= '';
    my $count= 0;
    for my $key (sort keys %{$_[0]}) {
        $pairs .= pack_string($key).pack_stringlist($_[0]{$key});
        $count++;
    }
    return pack_short($count).$pairs;
}

sub unpack_stringmultimap {
    my $count= &unpack_short;
    my $result= {};
    for (1..$count) {
        my $key= &unpack_string;
        $result->{$key}= &unpack_stringlist;
    }
    return $result;
}

# Metadata
sub pack_metadata {
    my ($protoversion, $is_result, $metadata)= @_;
    die "pack_metadata can only encode v4 results" unless $protoversion == 4 and $is_result;
    my $columns= $metadata->{columns};
    my $paging_state= $metadata->{paging_state};

    my $flags= ($columns ? 0 : 4) | (defined($paging_state) ? 2 : 0);

    my $out= pack_int($flags);
    $out .= pack_int($columns ? (0+@$columns) : 0);
    $out .= pack_bytes($paging_state) if $flags & 2;
    unless ($flags & 4) {
        for my $column (@$columns) {
            $out .= pack_string($column->[0]).pack_string($column->[1]);
            $out .= pack_string($column->[2]).pack_option_type($column->[3]);
        }
    }

    return $out;
}

# Query parameters
sub pack_queryparameters {
    my ($consistency, $skip_metadata, $page_size, $paging_state, $timestamp, $row)= @_;

    my $has_row= defined($row) && length($row);
    my $flags= (
        0
        | (($has_row         && 0x01) || 0)
        | (($skip_metadata   && 0x02) || 0)
        | (($page_size       && 0x04) || 0)
        | (($paging_state    && 0x08) || 0)
        | (($timestamp       && 0x20) || 0)
    );

    return (
          pack('nC', $consistency, $flags)
        . ($row || '')
        . ($page_size ? pack('l>', $page_size) : '')
        . ($paging_state ? pack('l>/a', $paging_state) : '')
        . ($timestamp ? (BIGINT_SUPPORTED ? pack('q>', $timestamp) : bigint_to_bytes($timestamp)) : '')
    );
}

sub unpack_errordata {
    my $code= &unpack_int;

    my %error;
    $error{code}= $code;
    $error{message}= &unpack_string;
    $error{is_timeout}= ( $code == 0x1001 || $code == 0x1100 || $code == 0x1200 );

    if ($code == 0x1000) {
        # Unavailable
        $error{cl}= &unpack_short;
        $error{required}= &unpack_int;
        $error{alive}= &unpack_int;
        return Cassandra::Client::Error::UnavailableException->new(%error);
    } elsif ($code == 0x1100) {
        # Write timeout
        $error{cl}= &unpack_short;
        $error{received}= &unpack_int;
        $error{blockfor}= &unpack_int;
        $error{write_type}= &unpack_string;
        return Cassandra::Client::Error::WriteTimeoutException->new(%error);
    } elsif ($code == 0x1200) {
        # Read timeout
        $error{cl}= &unpack_short;
        $error{received}= &unpack_int;
        $error{blockfor}= &unpack_int;
        $error{data_present}= &unpack_char;
        return Cassandra::Client::Error::ReadTimeoutException->new(%error);
    }

    return Cassandra::Client::Error::Base->new(%error);
}

# Support for 32bit perl
sub bigint_to_bytes {
    my $mb= Math::BigInt->new($_[0]);
    if ($_[0] !~ /^-?[0-9\.E]+$/i) { # Idk, approximate it
        warn "Argument $_[0] isn't numeric";
    }
    my $negative= $mb->is_neg && $mb != 0;
    if ($negative) {
        $mb *= -1; # Flips the bits, adds one
        $mb -= 1; # Removes that one
    }

    my $hex= $mb->as_hex;
    $hex =~ s/^0x//;
    my $bytes= pack('H*', substr(("0"x16).$hex, -16));
    if ($negative) {
        $bytes= ~$bytes; # Flip those bits back
    }

    return $bytes;
}

1;

__END__

=pod

=head1 NAME

Cassandra::Client::Protocol

=head1 VERSION

version 0.16

=head1 AUTHOR

Tom van der Woerdt <tvdw@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Tom van der Woerdt.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
