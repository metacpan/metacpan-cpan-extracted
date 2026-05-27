use strict;
use warnings;
use Test::More;
use lib 'blib/lib', 'blib/arch', 't/lib';
use ClickHouse::Encoder;
use TestCH qw(read_varint_ref split_paren_list);
*_read_varint       = \&read_varint_ref;
*_split_paren_list  = \&split_paren_list;

# Pure-Perl decoder for the ClickHouse native block format. The point isn't
# to be a general decoder but to verify that the encoder's columnar layout
# (offsets, null bitmaps, tuple ordering) matches the wire spec by encoding
# values and decoding them back.

sub _read_string {
    my ($buf, $off) = @_;
    my $len = _read_varint($buf, $off);
    my $s = substr($$buf, $$off, $len);
    $$off += $len;
    return $s;
}


sub _parse_type {
    my ($t) = @_;
    return { code => $t } if $t =~ /\A(?:Int8|Int16|Int32|Int64|UInt8|UInt16|UInt32|UInt64|Float32|Float64|String|Date|Date32|DateTime|Bool|UUID|IPv4|IPv6)\z/;
    return { code => 'Boolean'  }                          if $t eq 'Boolean';
    return { code => 'DateTime' }                          if $t =~ /\ADateTime\(.*\)\z/;
    return { code => 'DateTime64', p => $1 }               if $t =~ /\ADateTime64\((\d+)/;
    return { code => 'FixedString', n => $1 }              if $t =~ /\AFixedString\((\d+)\)\z/;
    return { code => 'Decimal32',  s => $1 }               if $t =~ /\ADecimal32\((\d+)\)\z/;
    return { code => 'Decimal64',  s => $1 }               if $t =~ /\ADecimal64\((\d+)\)\z/;
    return { code => 'Decimal128', s => $1 }               if $t =~ /\ADecimal128\((\d+)\)\z/;
    return { code => 'Decimal256', s => $1 }               if $t =~ /\ADecimal256\((\d+)\)\z/;
    return { code => 'Enum8' }                             if $t =~ /\AEnum8\(/;
    return { code => 'Enum16' }                            if $t =~ /\AEnum16\(/;
    return { code => 'Array',    inner => _parse_type($1) } if $t =~ /\AArray\((.+)\)\z/;
    return { code => 'Nullable', inner => _parse_type($1) } if $t =~ /\ANullable\((.+)\)\z/;
    if ($t =~ /\ATuple\((.+)\)\z/) {
        # Strip optional field names (CH allows "Tuple(a Int32, b String)").
        my @parts;
        for my $p (_split_paren_list($1)) {
            $p =~ s/\A([A-Za-z_]\w*)\s+(?=\S)//;
            push @parts, _parse_type($p);
        }
        return { code => 'Tuple', parts => \@parts };
    }
    if ($t =~ /\AMap\((.+)\)\z/) {
        my @kv = _split_paren_list($1);
        return { code => 'Map', key => _parse_type($kv[0]), val => _parse_type($kv[1]) };
    }
    if ($t =~ /\AVariant\((.+)\)\z/) {
        my @raw   = _split_paren_list($1);
        my @parts = map { _parse_type($_) } @raw;
        # ClickHouse stores Variant sub-columns in alphabetical order of
        # type names, so the wire discriminator at position w refers to
        # the alphabetically-w'th variant. Build the same permutation the
        # encoder uses so the decoder can map wire idx -> declaration idx.
        my @order = sort { $raw[$a] cmp $raw[$b] } 0 .. $#raw;
        my @decl_to_wire; $decl_to_wire[$order[$_]] = $_ for 0 .. $#order;
        return { code => 'Variant', parts => \@parts,
                 wire_to_decl => \@order, decl_to_wire => \@decl_to_wire };
    }
    if ($t =~ /\ALowCardinality\((.+)\)\z/) {
        return { code => 'LowCardinality', inner => _parse_type($1) };
    }
    # Geo aliases:
    return { code => 'Tuple', parts => [{code=>'Float64'},{code=>'Float64'}] }
        if $t eq 'Point';
    return { code => 'Array', inner => _parse_type('Point') }
        if $t eq 'Ring' || $t eq 'LineString';
    return { code => 'Array', inner => _parse_type('Ring') }
        if $t eq 'Polygon';
    return { code => 'Array', inner => _parse_type('LineString') }
        if $t eq 'MultiLineString';
    return { code => 'Array', inner => _parse_type('Polygon') }
        if $t eq 'MultiPolygon';
    die "Decoder doesn't support type: $t";
}

sub _decode_column {
    my ($buf, $off, $type, $nrows) = @_;
    my @vals;
    my $code = $type->{code};

    if    ($code eq 'Int8')    { for (1..$nrows) { push @vals, unpack('c',  substr($$buf, $$off, 1)); $$off += 1 } }
    elsif ($code eq 'UInt8')   { for (1..$nrows) { push @vals, unpack('C',  substr($$buf, $$off, 1)); $$off += 1 } }
    elsif ($code eq 'Int16')   { for (1..$nrows) { push @vals, unpack('s<', substr($$buf, $$off, 2)); $$off += 2 } }
    elsif ($code eq 'UInt16')  { for (1..$nrows) { push @vals, unpack('v',  substr($$buf, $$off, 2)); $$off += 2 } }
    elsif ($code eq 'Int32' || $code eq 'Date32' || $code eq 'Decimal32') {
        for (1..$nrows) { push @vals, unpack('l<', substr($$buf, $$off, 4)); $$off += 4 }
    }
    elsif ($code eq 'UInt32' || $code eq 'DateTime') {
        for (1..$nrows) { push @vals, unpack('V', substr($$buf, $$off, 4)); $$off += 4 }
    }
    elsif ($code eq 'Int64' || $code eq 'DateTime64' || $code eq 'Decimal64') {
        for (1..$nrows) { push @vals, unpack('q<', substr($$buf, $$off, 8)); $$off += 8 }
    }
    elsif ($code eq 'UInt64')  { for (1..$nrows) { push @vals, unpack('Q<', substr($$buf, $$off, 8)); $$off += 8 } }
    elsif ($code eq 'Float32') { for (1..$nrows) { push @vals, unpack('f<', substr($$buf, $$off, 4)); $$off += 4 } }
    elsif ($code eq 'Float64') { for (1..$nrows) { push @vals, unpack('d<', substr($$buf, $$off, 8)); $$off += 8 } }
    elsif ($code eq 'Date')    { for (1..$nrows) { push @vals, unpack('v',  substr($$buf, $$off, 2)); $$off += 2 } }
    elsif ($code eq 'String')  { for (1..$nrows) { push @vals, _read_string($buf, $off) } }
    elsif ($code eq 'FixedString') {
        my $n = $type->{n};
        for (1..$nrows) { push @vals, substr($$buf, $$off, $n); $$off += $n }
    }
    elsif ($code eq 'Enum8')   { for (1..$nrows) { push @vals, unpack('c', substr($$buf, $$off, 1)); $$off += 1 } }
    elsif ($code eq 'Enum16')  { for (1..$nrows) { push @vals, unpack('s<', substr($$buf, $$off, 2)); $$off += 2 } }
    elsif ($code eq 'Decimal128') {
        for (1..$nrows) {
            my $lo = unpack('Q<', substr($$buf, $$off, 8));
            my $hi = unpack('q<', substr($$buf, $$off + 8, 8));
            push @vals, [$lo, $hi];
            $$off += 16;
        }
    }
    elsif ($code eq 'Decimal256') {
        for (1..$nrows) {
            push @vals, [map {
                unpack('Q<', substr($$buf, $$off + 8 * $_, 8))
            } 0 .. 3];
            $$off += 32;
        }
    }
    elsif ($code eq 'Bool' || $code eq 'Boolean') {
        for (1..$nrows) { push @vals, unpack('C', substr($$buf, $$off, 1)); $$off += 1 }
    }
    elsif ($code eq 'UUID') {
        for (1..$nrows) { push @vals, substr($$buf, $$off, 16); $$off += 16 }
    }
    elsif ($code eq 'IPv4') {
        for (1..$nrows) {
            my $v = unpack('V', substr($$buf, $$off, 4));
            $$off += 4;
            push @vals, sprintf('%d.%d.%d.%d',
                ($v>>24)&0xff, ($v>>16)&0xff, ($v>>8)&0xff, $v&0xff);
        }
    }
    elsif ($code eq 'IPv6') {
        for (1..$nrows) { push @vals, substr($$buf, $$off, 16); $$off += 16 }
    }
    elsif ($code eq 'Map') {
        # Map(K, V) on the wire is Array(Tuple(K, V)).
        my $array_t = { code => 'Array',
            inner => { code => 'Tuple', parts => [$type->{key}, $type->{val}] } };
        @vals = @{ _decode_column($buf, $off, $array_t, $nrows) };
    }
    elsif ($code eq 'Variant') {
        my $mode = unpack('Q<', substr($$buf, $$off, 8));
        $$off += 8;
        die "Variant mode != 0" unless $mode == 0;
        my @wire_disc;
        for (1..$nrows) { push @wire_disc, ord(substr($$buf, $$off, 1)); $$off += 1 }
        # wire_disc is in alphabetical-order space; map to declaration idx.
        my @parts = @{ $type->{parts} };
        my $wire_to_decl = $type->{wire_to_decl};
        my @counts; for my $w (@wire_disc) { $counts[$w]++ if $w != 255 }
        my @subcols;  # subcols[wire_idx] = decoded values for that wire arm
        for my $w (0 .. $#parts) {
            my $decl = $wire_to_decl->[$w];
            $subcols[$w] = _decode_column($buf, $off, $parts[$decl], $counts[$w] // 0);
        }
        my @cursors = (0) x scalar @parts;
        for my $r (0 .. $nrows - 1) {
            my $w = $wire_disc[$r];
            if ($w == 255) { push @vals, undef; next }
            push @vals, [$wire_to_decl->[$w], $subcols[$w][ $cursors[$w]++ ]];
        }
    }
    elsif ($code eq 'LowCardinality') {
        my $version = unpack('Q<', substr($$buf, $$off, 8));   $$off += 8;
        my $flags   = unpack('Q<', substr($$buf, $$off, 8));   $$off += 8;
        my $dict_n  = unpack('Q<', substr($$buf, $$off, 8));   $$off += 8;
        die "LC version != 1" unless $version == 1;
        my $idx_type = $flags & 0xff;
        my $inner    = $type->{inner};
        $inner = $inner->{inner} if $inner->{code} eq 'Nullable';
        my $dict = _decode_column($buf, $off, $inner, $dict_n);
        my $idx_n = unpack('Q<', substr($$buf, $$off, 8));     $$off += 8;
        for my $r (1 .. $idx_n) {
            my $i;
            if    ($idx_type == 0) { $i = ord(substr($$buf, $$off, 1)); $$off += 1 }
            elsif ($idx_type == 1) { $i = unpack('v',  substr($$buf, $$off, 2)); $$off += 2 }
            elsif ($idx_type == 2) { $i = unpack('V',  substr($$buf, $$off, 4)); $$off += 4 }
            else                    { $i = unpack('Q<', substr($$buf, $$off, 8)); $$off += 8 }
            # For Nullable LC, slot 0 is the null sentinel.
            if ($type->{inner}{code} eq 'Nullable' && $i == 0) {
                push @vals, undef;
            } else {
                push @vals, $dict->[$i];
            }
        }
    }
    elsif ($code eq 'Array') {
        my @offsets;
        for (1..$nrows) { push @offsets, unpack('Q<', substr($$buf, $$off, 8)); $$off += 8 }
        my $total = @offsets ? $offsets[-1] : 0;
        my $flat = _decode_column($buf, $off, $type->{inner}, $total);
        my $prev = 0;
        for my $end (@offsets) {
            push @vals, [@$flat[$prev .. $end - 1]];
            $prev = $end;
        }
    }
    elsif ($code eq 'Tuple') {
        my @cols = map { _decode_column($buf, $off, $_, $nrows) } @{$type->{parts}};
        for my $r (0 .. $nrows - 1) {
            push @vals, [map { $_->[$r] } @cols];
        }
    }
    elsif ($code eq 'Nullable') {
        my @nulls;
        for (1..$nrows) { push @nulls, ord(substr($$buf, $$off, 1)); $$off += 1 }
        my $inner = _decode_column($buf, $off, $type->{inner}, $nrows);
        for my $r (0 .. $nrows - 1) {
            push @vals, $nulls[$r] ? undef : $inner->[$r];
        }
    }
    else {
        die "Decoder: unsupported $code";
    }
    return \@vals;
}

sub decode_block {
    my ($buf) = @_;
    my $off = 0;
    my $ncols = _read_varint(\$buf, \$off);
    my $nrows = _read_varint(\$buf, \$off);
    my @columns;
    for (1..$ncols) {
        my $name     = _read_string(\$buf, \$off);
        my $type_str = _read_string(\$buf, \$off);
        my $values   = _decode_column(\$buf, \$off, _parse_type($type_str), $nrows);
        push @columns, { name => $name, type => $type_str, values => $values };
    }
    return { ncols => $ncols, nrows => $nrows, columns => \@columns, consumed => $off };
}

# ---- helpers --------------------------------------------------------------

sub roundtrip {
    my ($cols, $rows) = @_;
    my $enc = ClickHouse::Encoder->new(columns => $cols);
    my $bin = $enc->encode($rows);
    return decode_block($bin);
}

sub _values { return [map { $_->{values} } @{$_[0]->{columns}}] }

# ---- tests ----------------------------------------------------------------

# Block header
{
    my $b = roundtrip([['a','UInt32'], ['b','String']], [[1,'x'],[2,'y'],[3,'z']]);
    is($b->{ncols}, 2, 'ncols');
    is($b->{nrows}, 3, 'nrows');
    is($b->{columns}[0]{name}, 'a', 'col 0 name');
    is($b->{columns}[1]{type}, 'String', 'col 1 type');
    is($b->{consumed}, length(ClickHouse::Encoder->new(columns => [['a','UInt32'],['b','String']])->encode([[1,'x'],[2,'y'],[3,'z']])), 'fully consumed');
}

# Integers
{
    my $b = roundtrip(
        [map { ["c$_->[0]", $_->[1]] } [0,'Int8'],[1,'Int16'],[2,'Int32'],[3,'Int64'],[4,'UInt8'],[5,'UInt16'],[6,'UInt32'],[7,'UInt64']],
        [[-1, -1000, -100000, -10_000_000_000, 255, 65535, 4294967295, 4611686018427387904]],
    );
    is_deeply(_values($b),
        [[-1], [-1000], [-100000], [-10_000_000_000], [255], [65535], [4294967295], [4611686018427387904]],
        'all integer types roundtrip');
}

# Floats
{
    my $b = roundtrip([['f','Float64']], [[3.14], [-2.5e10], [0]]);
    is($b->{columns}[0]{values}[0], 3.14, 'Float64 3.14');
    is($b->{columns}[0]{values}[1], -2.5e10, 'Float64 -2.5e10');
    is($b->{columns}[0]{values}[2], 0,   'Float64 0');
}

# String + FixedString
{
    my $b = roundtrip([['s','String'],['f','FixedString(5)']], [['hello','hi'],['world!','xyzzy']]);
    is_deeply($b->{columns}[0]{values}, ['hello','world!'], 'String roundtrip');
    is($b->{columns}[1]{values}[0], "hi\0\0\0", 'FixedString pad');
    is($b->{columns}[1]{values}[1], 'xyzzy',     'FixedString full');
}

# Array — verifies the cumulative-offset layout and recursive decode.
{
    my $b = roundtrip([['arr','Array(Int32)']], [[[1,2,3]],[[]],[[10,20]]]);
    is_deeply($b->{columns}[0]{values}, [[1,2,3], [], [10,20]], 'Array(Int32) layout');
}

# Nested Array(Array)
{
    my $b = roundtrip([['m','Array(Array(UInt8))']], [[[[1,2],[3]]],[[[4,5,6]]]]);
    is_deeply($b->{columns}[0]{values}, [[[1,2],[3]], [[4,5,6]]], 'Array(Array) layout');
}

# Tuple — verifies positional sub-column layout.
{
    my $b = roundtrip([['t','Tuple(UInt32, String, Float64)']],
                      [[[1,'a',1.5]], [[2,'b',-3.25]]]);
    is_deeply($b->{columns}[0]{values}, [[1,'a',1.5], [2,'b',-3.25]], 'Tuple layout');
}

# Nullable simple — verifies null bitmap layout.
{
    my $b = roundtrip([['n','Nullable(Int32)']], [[42],[undef],[-7]]);
    is_deeply($b->{columns}[0]{values}, [42, undef, -7], 'Nullable(Int32)');
}

# Nullable composite — null rows must produce a placeholder that decodes back to null.
{
    my $b = roundtrip([['n','Nullable(Tuple(UInt8, String))']],
                      [[[1,'a']], [undef], [[2,'b']]]);
    my $vals = $b->{columns}[0]{values};
    is_deeply($vals->[0], [1,'a'], 'Nullable(Tuple) row 0');
    is($vals->[1],        undef,  'Nullable(Tuple) row 1 null');
    is_deeply($vals->[2], [2,'b'], 'Nullable(Tuple) row 2');
}

# Array(Nullable(T)) — exercises Array-of-Nullable layout.
{
    my $b = roundtrip([['a','Array(Nullable(UInt32))']],
                      [[[1, undef, 3]], [[]], [[undef, undef]]]);
    is_deeply($b->{columns}[0]{values},
        [[1, undef, 3], [], [undef, undef]],
        'Array(Nullable) layout');
}

# Date / DateTime numeric inputs roundtrip exactly.
{
    my $b = roundtrip([['d','Date'],['dt','DateTime']], [[19889, 1718451045]]);
    is($b->{columns}[0]{values}[0], 19889,      'Date numeric');
    is($b->{columns}[1]{values}[0], 1718451045, 'DateTime numeric');
}

# Empty row block
{
    my $b = roundtrip([['v','UInt32']], []);
    is($b->{nrows}, 0, 'empty rows block');
    is_deeply($b->{columns}[0]{values}, [], 'empty column data');
}

# Decimal as scaled integer (Decimal32/64).
{
    my $b = roundtrip([['a','Decimal32(2)'],['b','Decimal64(4)']],
                      [['123.45','12345.6789'], ['-99.99','0.0001']]);
    is_deeply($b->{columns}[0]{values}, [12345, -9999],          'Decimal32 scaled');
    is_deeply($b->{columns}[1]{values}, [123456789, 1],          'Decimal64 scaled');
}

## ---- new-type roundtrips --------------------------------------------------

# Bool
{
    my $b = roundtrip([['v','Bool']], [[1],[0],['']]);
    is_deeply($b->{columns}[0]{values}, [1, 0, 0], 'Bool roundtrip');
}

# UUID
{
    my $b = roundtrip([['v','UUID']], [['550e8400-e29b-41d4-a716-446655440000']]);
    is(unpack('H*', $b->{columns}[0]{values}[0]),
       'd4419be200840e5500004455664416a7',
       'UUID encoded bytes match expected (each half reversed)');
}

# IPv4
{
    my $b = roundtrip([['v','IPv4']], [['1.2.3.4'], ['255.255.255.255']]);
    is_deeply($b->{columns}[0]{values}, ['1.2.3.4','255.255.255.255'],
              'IPv4 roundtrip');
}

# IPv6
{
    my $b = roundtrip([['v','IPv6']], [['::1'], ['2001:db8::1']]);
    is(unpack('H*', $b->{columns}[0]{values}[0]),
       '00000000000000000000000000000001', 'IPv6 ::1');
    is(unpack('H*', $b->{columns}[0]{values}[1]),
       '20010db8000000000000000000000001', 'IPv6 2001:db8::1');
}

# Map(String, UInt32)
{
    my $b = roundtrip([['m','Map(String, UInt32)']],
                      [[[['k1', 10], ['k2', 20]]], [[]]]);
    is_deeply($b->{columns}[0]{values},
              [[['k1',10],['k2',20]], []],
              'Map(String, UInt32) roundtrip via Array(Tuple) layout');
}

# Variant
{
    my $b = roundtrip([['v','Variant(Array(UInt8), String, UInt64)']],
                      [[[0,[1,2,3]]], [[1,'hello']], [[2,12345]], [undef]]);
    is_deeply($b->{columns}[0]{values}[0], [0,[1,2,3]], 'Variant Array variant');
    is_deeply($b->{columns}[0]{values}[1], [1,'hello'],  'Variant String variant');
    is_deeply($b->{columns}[0]{values}[2], [2,12345],    'Variant UInt64 variant');
    is($b->{columns}[0]{values}[3], undef,              'Variant null row');
}

# LowCardinality(String)
{
    my $b = roundtrip([['v','LowCardinality(String)']],
                      [['a'],['b'],['a'],['c'],['a']]);
    is_deeply($b->{columns}[0]{values}, ['a','b','a','c','a'],
              'LC(String) roundtrip via dict + indices');
}

# LowCardinality(Nullable(String))
{
    my $b = roundtrip([['v','LowCardinality(Nullable(String))']],
                      [['x'],[undef],[''], [undef], ['x']]);
    is_deeply($b->{columns}[0]{values}, ['x', undef, '', undef, 'x'],
              'LC(Nullable(String)) preserves null vs empty string');
}

# Decimal256
{
    my $b = roundtrip([['v','Decimal256(2)']], [['12345.67']]);
    is($b->{columns}[0]{values}[0][0], 1234567, 'Decimal256 limb 0');
    is($b->{columns}[0]{values}[0][1], 0,       'Decimal256 limb 1');
}

# Geo: Point
{
    my $b = roundtrip([['p','Point']], [[[1.5, 2.5]], [[-3.0, 4.5]]]);
    is_deeply($b->{columns}[0]{values}, [[1.5,2.5], [-3.0,4.5]], 'Point roundtrip');
}

# Geo: Polygon
{
    my $b = roundtrip([['p','Polygon']],
                      [[[[[0,0],[1,0],[1,1],[0,0]]]]]);
    is_deeply($b->{columns}[0]{values},
              [[[[0,0],[1,0],[1,1],[0,0]]]],
              'Polygon (Array(Array(Point))) roundtrip');
}

# Named Tuple (the field names get stripped during decode)
{
    my $b = roundtrip([['t','Tuple(a Int32, b String)']],
                      [[[42,'hi']], [[100,'world']]]);
    is_deeply($b->{columns}[0]{values}, [[42,'hi'],[100,'world']],
              'Named Tuple roundtrip (field names ignored on decode)');
}

done_testing();
