use strict;
use warnings;
use Test::More;
use Encode qw(encode_utf8);
use lib 'blib/lib', 'blib/arch';
use ClickHouse::Encoder;

{
    package ProductionHTTP;
    sub new { bless { responses => [@_[1 .. $#_]], requests => [] }, $_[0] }
    sub post {
        my ($self, $url, $opts) = @_;
        push @{$self->{requests}}, [$url, $opts->{content}];
        return shift(@{$self->{responses}})
            || {success => 1, status => 200, headers => {}, content => ''};
    }
}
my $enc = ClickHouse::Encoder->new(columns => [['v', 'Int32']]);
{
    my $bi = $enc->bulk_inserter(encoder => $enc, table => 't', batch_size => 2,
        dedup_token => 'job & 1', retries => 0);
    $bi->{http} = ProductionHTTP->new({success => 0, status => 503, content => 'retry'});
    eval { $bi->push_many([[1], [2], [3], [4], [5]]) };
    like($@, qr/gave up/, 'bulk failure surfaces');
    is($bi->buffered_count, 5, 'failed and untried rows retained');
    $bi->push_many([])->finish;
    my $requests = $bi->{http}{requests};
    is($requests->[0][0], $requests->[1][0], 'manual retry reuses batch token');
    is($requests->[0][1], $requests->[1][1], 'manual retry reuses batch body');
    like($requests->[1][0], qr/job%20%26%201-0(?:&|$)/, 'first token escaped');
    like($requests->[2][0], qr/job%20%26%201-1(?:&|$)/, 'next batch has distinct token');
    is($bi->sent_rows, 5, 'all rows sent after retry');
}
{
    require Time::HiRes;
    my @sleeps;
    no warnings 'redefine';
    local *Time::HiRes::sleep = sub { push @sleeps, $_[0] };
    my $bi = $enc->bulk_inserter(encoder => $enc, table => 't', retries => 1, retry_wait => 0);
    $bi->{http} = ProductionHTTP->new({success => 0, status => 429, content => 'busy'});
    $bi->push([1])->finish;
    is(scalar @{$bi->{http}{requests}}, 2, 'HTTP 429 retried');
    is(scalar @sleeps, 0, 'zero retry wait does not sleep');
}
{
    require HTTP::Tiny;
    my @args;
    no warnings qw(redefine once);
    local *HTTP::Tiny::new = sub { shift; @args = @_; bless {}, 'ProductionHTTP' };
    ClickHouse::Encoder::_http_tiny();
    my %args = @args;
    is($args{max_redirect}, 0, 'credential-bearing HTTP requests do not redirect');
    is($args{verify_SSL}, 1, 'TLS verification explicit');
}
{
    my $char = "caf" . chr(0xe9); utf8::upgrade($char);
    my $byte = encode_utf8($char);
    my ($cu) = ClickHouse::Encoder::_http_url_headers("select '$char'");
    my ($bu) = ClickHouse::Encoder::_http_url_headers("select '$byte'");
    is($cu, $bu, 'HTTP UTF-8 characters and bytes agree');
    my $e = ClickHouse::Encoder->new(columns => [[$byte, 'String']]);
    is($e->encode_columns({$char => ['x']}), $e->encode([['x']]), 'Unicode column hash key');
    $e = ClickHouse::Encoder->new(columns => [['t', "Tuple(`$byte` String)"]]);
    is($e->encode([[{$char => 'x'}]]), $e->encode([[['x']]]), 'Unicode named Tuple key');
    $e = ClickHouse::Encoder->new(columns => [['m', 'Map(String, UInt8)']]);
    my $b = ClickHouse::Encoder->decode_block($e->encode([[{$char => 7}]]));
    is($b->{columns}[0]{values}[0][0][0], $byte, 'Unicode Map key preserved as UTF-8 bytes');
}
{
    my $e = ClickHouse::Encoder->new(columns => [['e', q{Enum16('neg' = -9, 'pos' = 3)}]]);
    is_deeply($e->decode_rows($e->encode([['neg'], ['pos']]))->{rows}, [[-9], [3]], 'Enum signed values decode');
    my $j = ClickHouse::Encoder->new(columns => [['j', 'JSON']]);
    is_deeply($j->decode_rows($j->encode([[{'' => {a => 1}}]]))->{rows}, [[{'' => {a => 1}}]], 'empty JSON path segments');
    eval { $j->encode([[{a => {b => 1}, 'a.b' => 2}]]) };
    like($@, qr/duplicate path/, 'duplicate flattened JSON path rejected');
    for (1 .. 10) {
        my $value = $j->decode_rows($j->encode([[{'a.b' => 1, 'a.b.c' => 2}]]))->{rows}[0][0];
        my $again = $j->decode_rows($j->encode([[$value]]))->{rows}[0][0];
        my $flatten;
        $flatten = sub {
            my ($h, $prefix) = @_;
            my %leaves;
            for my $k (keys %$h) {
                my $path = defined $prefix ? "$prefix.$k" : $k;
                if (ref $h->{$k} eq 'HASH') { %leaves = (%leaves, %{$flatten->($h->{$k}, $path)}) }
                else { $leaves{$path} = $h->{$k} }
            }
            return \%leaves;
        };
        is_deeply($flatten->($again), {'a.b' => 1, 'a.b.c' => 2}, 'overlapping JSON paths keep both values');
        undef $flatten;
    }
}
{
    my $bin = pack('H*', '010201640744796e616d69630100000000000000010104426f6f6c000000000000000000000100');
    open my $p, '-|', $^X, '-Mblib', '-MClickHouse::Encoder', '-e',
        'my $v=ClickHouse::Encoder->decode_block(pack("H*",shift))->{columns}[0]{values}; print $v->[0]?1:0, $v->[1]?1:0', unpack('H*', $bin)
        or die $!;
    my $got = do { local $/; <$p> };
    close $p;
    is($?, 0, 'fresh process decodes booleans');
    is($got, '10', 'decoded false stays false without caller loading JSON::PP');
}
{
    for my $type ('UUID', 'IPv6', 'Decimal128(2)', 'Decimal256(2)', 'Array(UInt8)', 'Map(String, UInt8)') {
        my $value = $type eq 'UUID' ? '123e4567-e89b-12d3-a456-426614174000'
            : $type eq 'IPv6' ? '1:2:3:4:5:6:78:9'
            : $type =~ /^Array/ ? [1, 2] : $type =~ /^Map/ ? {a => 1} : '1.23';
        my $e = ClickHouse::Encoder->new(columns => [['v', $type]]);
        my $bin = $e->encode([map { [$value] } 1 .. 400]);
        open my $fh, '<', \$bin or die $!;
        my @b;
        my $ok = eval { $e->decode_stream($fh, sub { push @b, $_[0] }, chunk_size => 512); 1 };
        ok($ok, "short reads for $type") or diag $@;
        is($b[0]{nrows}, 400, "$type complete row count");
        close $fh;
    }
}
{
    my $ddl = q{create table db.t (a Enum8('x)y' = 1, 'p,q' = 2), b UInt8) engine = MergeTree order by (a, b) comment 'ORDER BY, SETTINGS'};
    my $s = ClickHouse::Encoder->parse_create_table($ddl);
    is(scalar @{$s->{columns}}, 2, 'quoted enum label keeps column list aligned');
    is($s->{order_by}, '(a, b)', 'quoted clause names do not split real clauses');
    like(ClickHouse::Encoder->format_create_table(table => 'db.t', columns => [['a','UInt8']]), qr/create table `db`\.`t`/, 'database-qualified DDL quoted by component');
    is_deeply(ClickHouse::Encoder->parse_wkt('MULTIPOLYGON(((0 0,1 0,0 0),(0 0,0 1,0 0)),((2 2,3 3,2 2)))'),
        [[[[0,0],[1,0],[0,0]], [[0,0],[0,1],[0,0]]], [[[2,2],[3,3],[2,2]]]], 'MULTIPOLYGON holes and multiple polygons');
}

{
    my $e = ClickHouse::Encoder->new(columns => [['d','DateTime(03)']]);
    my $row = [['1970-01-01 00:00:01.123']];
    is(length($e->encode_row_binary($row)), 8, 'DateTime precision alias uses 8-byte RowBinary');
    my $block = $e->decode_block($e->encode($row));
    $e->coerce_datetimes($block);
    is($block->{columns}[0]{values}[0], '1970-01-01T00:00:01.123Z', 'DateTime alias coerces at declared precision');
    $e = ClickHouse::Encoder->new(columns => [['d','DateTime(0)']]);
    is(length($e->encode_row_binary([[1]])), 4, 'DateTime zero precision retains 4-byte storage');
}
done_testing();
