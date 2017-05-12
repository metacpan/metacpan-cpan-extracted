package Cassandra::Client::Protocol;
use 5.010;
use strict;
use warnings;

use Encode;

require Exporter;
our @ISA= qw(Exporter);

use Cassandra::Client::Error;

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
            pack_long               unpack_long
            pack_short              unpack_short
            pack_string             unpack_string
            pack_longstring         unpack_longstring
            pack_stringlist         unpack_stringlist
            pack_bytes              unpack_bytes
            pack_shortbytes         unpack_shortbytes
            pack_option_type        unpack_option_type
            pack_optionlist_type    unpack_optionlist_type
            pack_stringmap          unpack_stringmap
            pack_stringmultimap     unpack_stringmultimap
            pack_inet               unpack_inet
            pack_char               unpack_char

                                    unpack_metadata
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

my %java_type_to_ours= (
    # Because of implementation details, we can only have non-complex types here, eg. int and blob
    'org.apache.cassandra.db.marshal.UTF8Type'          => TYPE_VARCHAR,
    'org.apache.cassandra.db.marshal.AsciiType'         => TYPE_ASCII,
    'org.apache.cassandra.db.marshal.UUIDType'          => TYPE_UUID,
    'org.apache.cassandra.db.marshal.TimeUUIDType'      => TYPE_TIMEUUID,
    'org.apache.cassandra.db.marshal.Int32Type'         => TYPE_INT,
    'org.apache.cassandra.db.marshal.BytesType'         => TYPE_BLOB,
    'org.apache.cassandra.db.marshal.FloatType'         => TYPE_FLOAT,
    'org.apache.cassandra.db.marshal.DoubleType'        => TYPE_DOUBLE,
    'org.apache.cassandra.db.marshal.BooleanType'       => TYPE_BOOLEAN,
    'org.apache.cassandra.db.marshal.InetAddressType'   => TYPE_INET,
    'org.apache.cassandra.db.marshal.SimpleDateType'    => TYPE_DATE,
    'org.apache.cassandra.db.marshal.TimeType'          => TYPE_TIME,
    'org.apache.cassandra.db.marshal.ShortType'         => TYPE_SMALLINT,
    'org.apache.cassandra.db.marshal.ByteType'          => TYPE_TINYINT,
    'org.apache.cassandra.db.marshal.DateType'          => TYPE_TIMESTAMP,
    'org.apache.cassandra.db.marshal.TimestampType'     => TYPE_TIMESTAMP,
    'org.apache.cassandra.db.marshal.LongType'          => TYPE_BIGINT,
    'org.apache.cassandra.db.marshal.DecimalType'       => TYPE_DECIMAL,
    'org.apache.cassandra.db.marshal.IntegerType'       => TYPE_VARINT,
    'org.apache.cassandra.db.marshal.CounterColumnType' => TYPE_COUNTER,
);

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

sub unpack_long {
    if (BIGINT_SUPPORTED) {
        return unpack('q>', substr $_[0], 0, 8, '');
    } else {
        return bytes_to_bigint(substr($_[0], 0, 8, ''));
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
sub pack_char {
    pack('c', $_[0])
}

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

sub unpack_longstring {
    my $length= &unpack_int;
    if ($length > 0) {
        my $string= substr($_[0], 0, $length, '');
        utf8::decode $string;
        return $string;
    } else {
        return '';
    }
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
sub pack_inet {
    die 'Not implemented';
}

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
    die 'Not implemented';
}

sub unpack_option_type {
    my $id= &unpack_short;
    my @value;
    if ($id == TYPE_CUSTOM) {
        @value= (&unpack_string);
        # Java will sometimes send its types as CUSTOM instead of the real type. Quite annoying.
        if (my $real_type= $java_type_to_ours{$value[0]}) {
            $id= $real_type;
            @value= ();
        }
    } elsif ($id < 0x20) {
        # Nothing
    } elsif ($id == TYPE_LIST || $id == TYPE_SET) { # List<?> / Set<?>
        @value= (&unpack_option_type);
    } elsif ($id == TYPE_MAP) { # Map<?,?>
        @value= (&unpack_option_type, &unpack_option_type);
    } elsif ($id == TYPE_UDT) {
        my $keyspace= &unpack_string;
        my $udt_name= &unpack_string;
        my $field_n=  &unpack_short;
        my @fields;
        for (1..$field_n) {
            my $name= &unpack_string;
            my $type= &unpack_option_type;
            push @fields, [ $name, $type ];
        }
        @value= ($keyspace, $udt_name, \@fields);
    } elsif ($id == TYPE_TUPLE) { # Tuple
        my $field_n= &unpack_short;
        my @fields;
        for (1..$field_n) {
            push @fields, &unpack_option_type;
        }
        @value= (\@fields);
    } else {
        die 'Unable to decode protocol: no idea what type '.$id.' is...';
    }

    return [ $id, @value ];
}

# TYPE: optionlist_type
sub pack_optionlist_type {
    pack_short(0+@$_[0]).join('', map pack_option_type($_), @$_[0])
}

sub unpack_optionlist_type {
    my $count= &unpack_short;
    [ map &unpack_option_type, 1..$count ]
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

sub unpack_stringmap {
    my $count= &unpack_short;
    my $result= {};
    for (1..$count) {
        my $key= &unpack_string;
        $result->{$key}= &unpack_string;
    }
    return $result;
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
sub unpack_metadata {
    my ($flags, $columns_count, $paging_state, $keyspace_name, $table_name, @columns);

    ($flags, $columns_count)= unpack('l>l>', substr($_[0], 0, 8, '')); # Short-circuited for perf
    if ($flags & 2) {
        $paging_state= &unpack_bytes;
    }
    unless ($flags & 4) { # "No metadata"
        my $global_tables_spec= ($flags & 1);
        if ($global_tables_spec) {
            $keyspace_name= &unpack_string;
            $table_name= &unpack_string;
        }

        for (1..$columns_count) {
            my ($keyspace, $table);
            if ($global_tables_spec) {
                ($keyspace, $table)= ($keyspace_name, $table_name);
            } else {
                ($keyspace, $table)= (&unpack_string, &unpack_string);
            }
            my $column_name= &unpack_string;
            my $type= &unpack_option_type;

            push @columns, [ $keyspace, $table, $column_name, $type ];
        }
    }

    return {
        columns => ($flags & 4) ? undef : \@columns,
        paging_state => $paging_state,
    };
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
    } elsif ($code == 0x1100) {
        # Write timeout
        $error{cl}= &unpack_short;
        $error{received}= &unpack_int;
        $error{blockfor}= &unpack_int;
        $error{write_type}= &unpack_string;
    } elsif ($code == 0x1200) {
        # Read timeout
        $error{cl}= &unpack_short;
        $error{received}= &unpack_int;
        $error{blockfor}= &unpack_int;
        $error{data_present}= &unpack_char;
    }

    return Cassandra::Client::Error->new(%error);
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

sub bytes_to_bigint {
    my $bytes= substr("\0\0\0\0\0\0\0\0".$_[0], -8);
    my $negative= 0;
    if ((substr($bytes, 0, 1) & "\x80") ne "\0") { # Negative
        $negative= 1;
        $bytes= ~$bytes;
    }
    my $mb= Math::BigInt->new('0x'.substr(("0"x16).unpack('H*', $bytes), -16));
    if ($negative) {
        $mb += 1; # Because two's complement
        $mb *= -1;
    }
    return $mb->bstr;
}

1;
