package Cassandra::Client::Encoder;
use 5.010;
use strict;
use warnings;

use Cassandra::Client::Protocol qw/:constants BIGINT_SUPPORTED pack_long/;
use Math::BigInt;
use Encode;
use POSIX qw/floor/;
use Ref::Util qw/is_hashref/;

use Exporter 'import';
our @EXPORT_OK= qw/
    make_encoder
/;

use vars qw/@INPUT/;

my @bigint_enc= BIGINT_SUPPORTED ? ( 'q>', 8 ) : ( \&e_bigint );

my %types= (
    TYPE_CUSTOM     ,=> [ \&e_passthru ],
    TYPE_ASCII      ,=> [ \&e_passthru ],
    TYPE_BIGINT     ,=> [ @bigint_enc  ],
    TYPE_BLOB       ,=> [ \&e_passthru ],
    TYPE_BOOLEAN    ,=> [ \&e_bool ],
    TYPE_COUNTER    ,=> [ @bigint_enc  ],
    TYPE_DECIMAL    ,=> [ \&e_decimal  ],
    TYPE_DOUBLE     ,=> [ 'd>', 8 ],
    TYPE_FLOAT      ,=> [ 'f>', 4 ],
    TYPE_INT        ,=> [ 'l>', 4 ],
    TYPE_TEXT       ,=> [ \&e_string ],
    TYPE_VARINT     ,=> [ \&e_varint   ],
    TYPE_TIMESTAMP  ,=> [ @bigint_enc  ],
    TYPE_UUID       ,=> [ \&e_uuid ],
    TYPE_VARCHAR    ,=> [ \&e_string ],
    TYPE_TIMEUUID   ,=> [ \&e_uuid ],
    TYPE_INET       ,=> [ \&e_inet ],
    TYPE_LIST       ,=> [ \&e_list ],
    TYPE_MAP        ,=> [ \&e_map ],
    TYPE_SET        ,=> [ \&e_set ],
    TYPE_TINYINT    ,=> [ 'c', 1 ],
    TYPE_SMALLINT   ,=> [ 's>', 2 ],
    TYPE_TIME       ,=> [ \&e_time ],
    TYPE_DATE       ,=> [ \&e_date ],
);

sub make_encoder {
    my ($metadata)= @_;

    my @columns= @{$metadata->{columns}};
    my @names= map { $_->[2] } @columns;

    my $code= <<EOC;

    my \$null= pack('l>', -1);
    my \$length= pack('n', @{[ 0+@columns ]});
    my \$true= pack('l>c', 1, 1);
    my \$false= pack('l>c', 1, 0);

    sub {
        my \$input_ref= \$_[0];
        if (is_hashref(\$input_ref)) {
            \$input_ref= [ @\$input_ref{\@names} ];
        }
        local *INPUT= \$input_ref;
        my \$row= \$length;

@{[ map { my $i= $_; my $column= $columns[$i]; <<EOP } 0..$#columns

        { # $column->[0].$column->[1].$column->[2]
            @{[ make_column_encoder($column->[3], "\$INPUT[$i]", '$row', 3, 0) ]}

        }
EOP
]}

        return \$row;
    }

EOC

    return ( eval($code) or die $@ );
}

sub make_column_encoder {
    my ($type, $input, $output, $indent, $level)= @_;

    my $code= "# Encoder for type $type->[0]
if (!defined($input)) {
    $output .= \$null;
} else {\n";

    my $type_entry= $types{$type->[0]};
    if (!$type_entry) {
        warn "Cannot encode type $type->[0]. Sending a NULL instead, this is probably not what you want!"; # XXX Can we do this?
        $code .= "$output .= \$null;";
    } elsif (!ref $type_entry->[0]) {
        if (my $length= $type_entry->[1]) {
            $code .= "$output .= pack('l>$type_entry->[0]', $length, $input);";
        } else {
            $code .= "$output .= pack('l>/a', pack('$type_entry->[0]', $input));";
        }
    } else {
        $code .= $type_entry->[0]->($type, $input, $output, $level+1);
    }

    $code .= "\n}\n";

    return "\n".join("\n", map { ("    "x$indent).$_ } split /\n/, $code);
}

sub e_passthru {
    my ($type, $input, $output)= @_;

    return "Encode::_utf8_off($input);
$output .= pack('l>', length($input)).$input;";
}

sub e_string {
    my ($type, $input, $output)= @_;

    return "utf8::encode($input) if utf8::is_utf8($input);
$output .= pack('l>', length($input)).$input;";
}

sub e_uuid {
    my ($type, $input, $output)= @_;
    return "my \$tmp= $input;
\$tmp =~ s/\\W+//g;
$output .= pack('l>H[32]', 16, \$tmp);";
}

sub e_bool {
    my ($type, $input, $output)= @_;
    return "$output .= ($input ? \$true : \$false);";
}

sub e_inet {
    my ($type, $input, $output)= @_;
    my $code= <<EOC;
if ($input !~ /:/) {
    $output .= pack('l>CCCC', 4, split(/\\./, $input));
} else {
    my \@ipv6_bits= split(/:/, $input, 8);
    my \$left= 8 - \@ipv6_bits;
    \@ipv6_bits= map { length(\$_) ? substr("000\$_", -4) : do { my \$old_left= \$left; \$left= 0; (('0000')x(\$old_left+1)) } } \@ipv6_bits;
    $output .= pack('l>(H4)[8]', 16, \@ipv6_bits);
}
EOC
}

sub e_list {
    my ($type, $input, $output, $level)= @_;
    my $subtype= $type->[1];
    my $code= <<EOC;
my \$tmp_output_$level= '';
\$tmp_output_$level .= pack('l>', 0+\@{$input});
for my \$list_item (\@{$input}) {
    @{[ make_column_encoder($subtype, '$list_item', '$tmp_output_'.$level, 1, $level) ]}
}
$output .= pack('l>', length(\$tmp_output_$level)).\$tmp_output_$level;
EOC

    return $code;
}

sub e_map {
    my ($type, $input, $output, $level)= @_;
    my $keytype= $type->[1];
    my $valuetype= $type->[2];

    my $code= <<EOC;
my \$tmp_output_$level= '';
\$tmp_output_$level .= pack('l>', 0+keys \%{$input});
for my \$key (sort keys \%{$input}) {
    my \$value= $input\->{\$key};
    @{[ make_column_encoder($keytype, '$key', '$tmp_output_'. $level, 1, $level) ]}
    @{[ make_column_encoder($valuetype, '$value', '$tmp_output_'. $level, 1, $level) ]}
}
$output .= pack('l>', length(\$tmp_output_$level)).\$tmp_output_$level;
EOC

    return $code;
}

sub e_set {
    my ($type, $input, $output, $level)= @_;
    my $subtype= $type->[1];

    my $code= <<EOC;
my \$tmp_output_$level= '';
\$tmp_output_$level .= pack('l>', 0+\@{$input});
for my \$item (\@{$input}) {
    @{[ make_column_encoder($subtype, '$item', '$tmp_output_'. $level, 1, $level) ]}
}
$output .= pack('l>', length(\$tmp_output_$level)).\$tmp_output_$level;
EOC

    return $code;
}

sub e_bigint {
    my ($type, $input, $output)= @_;
    return "$output .= pack('l>', 8).pack_long($input);";
}

sub e_varint {
    my ($type, $input, $output)= @_;
    return <<EOC;
{
    my \$number= Math::BigInt->new($input);
    my \$negative= \$number->is_neg;
    if (\$negative) {
        \$number *= -1; # This means invert the bits and add one
        \$number -= 1; # So remove that one
    }
    my \$hex= \$number->as_hex;
    \$hex =~ s/^0x//;
    \$hex= "0\$hex" if length(\$hex) % 2;
    \$hex= "00\$hex" if substr(\$hex, 0, 1) =~ /[89abcdef]/;
    my \$binary= pack('H*', \$hex);
    \$binary= ~\$binary if \$negative;
    $output .= pack('l>/a', \$binary);
}
EOC
}

sub e_decimal {
    my ($type, $input, $output)= @_;
    my $varint_enc= e_varint($type, '$unscaled', '$output_with_length_bytes');
    return <<EOC;
my \$input_copy= "".$input;
my \$scale= 0;
if (\$input_copy =~ /E([+-]?\\d+)\$/i) {
    \$scale -= \$1;
    \$input_copy =~ s/E([+-]?\\d+)\$//i;
}
if (\$input_copy =~ /[.](\\d+)\$/) {
    \$scale += length \$1;
    \$input_copy =~ s/[.]//;
}
\$input_copy =~ s/^0+//;
\$input_copy= "0" unless length \$input_copy;
my \$unscaled= \$input_copy;
my \$output_with_length_bytes;
VARINT: {
$varint_enc
}
$output .= pack('l>/a', pack('l>', \$scale). substr(\$output_with_length_bytes, 4));
EOC
}

sub e_time {
    my ($type, $input, $output)= @_;

    my $regex= qr/\A(\d+)(?::(\d+)(?::(\d+)(?:\.(\d+))?)?)?\z/;
    return <<EOC;
{
    if ($input =~ m#$regex#) {
        my (\$hours, \$minutes, \$seconds, \$ns)= (\$1, \$2, \$3, \$4);
        my \$timeval= ((((\$hours||0) * 3600) + ((\$minutes||0) * 60) + (\$seconds||0))%86400) . substr((\$ns||0)."000000000", 0, 9);
        $output .= pack('l>', 8) . ( BIGINT_SUPPORTED ? pack('q>', \$timeval) : pack_long(\$timeval) );
    } else {
        my \$value= $input;
        warn "Invalid value for TIME type: \$value";
        $output .= \$null;
    }
}
EOC
}

sub e_date {
    my ($type, $input, $output)= @_;

    my $regex= qr/\A(-?\d+)-(\d+)-(\d+)\z/;
    return <<EOC;
{
    if ($input =~ m#$regex#) {
        my (\$year, \$month, \$day)= (\$1, \$2, \$3);

        my \$v_a= ((\$month == 1 || \$month == 2) ? 1 : 0);
        my \$y= \$year + 4800 - \$v_a;
        my \$m= \$month + (12 * \$v_a) - 3;
        my \$jdn= \$day + floor(((153 * \$m) + 2) / 5) + (365 * \$y) + floor(\$y / 4) - floor(\$y / 100) + floor(\$y / 400);

        my \$days= (1 << 31) - 2472633 + \$jdn;

        $output .= pack('l>L>', 4, \$days);
    } else {
        my \$value= $input;
        warn "Invalid value for DATE type: \$value";
        $output .= \$null;
    }
}
EOC
}

1;
