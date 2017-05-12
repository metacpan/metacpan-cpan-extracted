#!/usr/bin/perl -w
use strict;
use Test::More 'no_plan'; # tests =>$n
use Test::Exception;
use Scalar::Util qw(reftype);

BEGIN { use_ok( 'Data::Rmap' ); }
use Data::Dumper;
$Data::Dumper::Purity=1;

our $data = {
          'arrays' => [[ 'shared', 'not_shared' ]],
          'num' => 2,
          'ref'  => \do { my $a = 'ref' },
          'hash' => {
                      'a' => 'vala',
                      'b' => 'valb',
                      'c' => { qn=> 'this' },
                    },
          'ref_to_hash' => \{ qn=> 'that' },
        };

# shared value
$data->{share_ref} = \$data->{arrays}[0][0];
$data->{another_obj} = \do{ my $o = ${$data->{ref_to_hash}}};

my $orig_dump = Dumper($data);

# do nothing slowly
rmap { } $data;
rmap_all { } $data;

# test importing implicitly
use Data::Rmap qw(rmap_scalar);
rmap_scalar { } $data;
use Data::Rmap qw(:types rmap_to);
rmap_to { } HASH|ARRAY|SCALAR|REF|VALUE|GLOB, $data;
use Data::Rmap qw(:all);
rmap_hash { } $data;
rmap_array { } $data;

# check nothing changed
ok(Dumper($data) eq $orig_dump, 'nothing changed');

rmap { $_ = "#$_#"; } $data; # all the leaves

ok($data->{num} eq '#2#', "num #2#");
ok($data->{arrays}[0][0] eq '#shared#', "done once #shared#");
ok(${$data->{ref}} eq '#ref#', "${$data->{ref}} eq '#ref#'");
ok($data->{hash}{a} eq '#vala#', "nested hashes done #vala#");
ok(${$data->{ref_to_hash}}->{qn} eq '#that#', "ref_to_hash done #that#");

my $count = 1;
rmap_all {
    cut if ref($_) eq 'ARRAY';
    $_ = "=\U$_=" if !ref($_); # leaves
    $_->{qnum} = $count++ if ref($_) eq 'HASH' && exists $_->{qn};
} $data;
#diag(Dumper $data);

ok($data->{arrays}[0][1] eq '#not_shared#', 'ARRAY cut');
ok($data->{arrays}[0][0] eq '=#SHARED#=', 'cut one path only');
ok($data->{hash}{a} eq '=#VALA#=', 'HASH not cut');
like(${$data->{ref_to_hash}}->{qnum}, qr/^=\d+=$/, 'qnum added to qn');

# action only done once
$data = [];
$data->[0] = "string";
$data->[1] = \$data->[0];
$data->[2] = \\do{ my $s = "last" };

rmap { $_ = "!$_" } $data;
ok($data->[0] eq '!string', "done once");
ok(${$data->[1]} eq '!string', "access via both paths");
ok(\$data->[0] == \${$data->[1]}, "still same ref");
ok($${$data->[2]} eq '!last', "got '!last'");

# test aliasing with write only: ref => \'ref'
my $ro_err = qr/^Modification of a read-only value attempted/;
throws_ok { rmap { $_++ } 1 } $ro_err, 'read-only scalar';
throws_ok { rmap { $_++ } \1 } $ro_err, 'read-only scalar ref';
throws_ok { rmap { $_++ } [\1] } $ro_err, 'read-only scalar ref in array';
throws_ok { rmap { $_++ } {1,\1} } $ro_err, 'read-only scalar ref in hash';
*ro = \1;
throws_ok { rmap { $_++ } *ro } $ro_err, 'read-only scalar ref in glob';

# test returns
is_deeply([ rmap { ++$_ } [1,2] ], [2,3], 'return altered pre-inc');
is_deeply([ rmap { $_++ } [1,2] ], [1,2], 'return not altered post-inc');
is( scalar(rmap { ++$_ } [2..4]), 3, 'scalar context num items');
our $rw = 2;
is_deeply([ rmap { ++$_ } [\do{my $a = 1}, \*rw] ], [2,3], 'flattens return');
is_deeply([ rmap { ++$_ } [1,[2]] ], [2,3], 'flattens 2');

# test cut
# take first element of each array reference found
is_deeply([ rmap_array { cut($_->[0]) } [1,0],[2,0,[0]],[[3],0], {0,\[4]} ],
            [                            1,    2,        [3],         4   ],
            'cut limits recursion');

is_deeply([ rmap { cut(++$_) } [1,2] ], [2,3], 'cut return altered pre-inc');
is_deeply([ rmap { ++$_; cut() } [1,2] ], [], 'cut can return nothing');

# test $_[0]->recurse
my ($array_dump) = rmap_to {
    return $_ unless ref($_);
    '[ ' . join(', ', $_[0]->recurse() ) . ' ]';
} ARRAY|VALUE,   [ 1, [ 2, [ [ 3 ], 4 ] ], 5 ];
is($array_dump, '[ 1, [ 2, [ [ 3 ], 4 ] ], 5 ]', 'dumper dumps');

my $tree = [
    one =>
    two =>
    [
        three_one =>
        three_two =>
        [
            three_three_one =>
        ],
        three_four =>
    ],
    four =>
    [
        [
            five_one_one =>
        ],
    ],
];

my $got = '';
our @path = ('q');
rmap_to {
    if(ref $_) {
        local(@path) = (@path, 1); # ARRAY adds a new level to the path
        $_[0]->recurse(); # does stuff within local(@path)'s scope
    } else {
        $got .= join('.', @path) . ' ';
    }
    $path[-1]++; # bump last element (even when it was an aref)
} ARRAY|VALUE, $tree;

is($got, 'q.1 q.2 q.3.1 q.3.2 q.3.3.1 q.3.4 q.4 q.5.1.1 ',
            'tree numbering w/ recurse');


# assign each of the THINGs in GLOB x
local *x;
*x = \3;
*x = sub {};
*x = {};
*x = [];

# test each name works as expected
my @types = (1, [], {}, \\2, \*x, sub {});
#$_ = join(' ', rmap_all { $_ } @types); s/\(.*?\)/\\S+/g; diag($_);
like(join(' ',
    rmap { $_ } @types),
    qr/^1 2 3$/,
    'rmap types'
);


is(join(' ',
    rmap_all { reftype($_) || $_ } @types),
    '1 ARRAY HASH REF SCALAR 2 GLOB SCALAR 3 ARRAY HASH',
    'rmap_all types'
);

# stringification of references, eg. ARRAY(0x1e8ce28) =~ /ARRAY\S+/
like(join(' ',
    rmap_scalar { $_ } @types),
    qr/^1 (REF|SCALAR)\S+ SCALAR\S+ 2 SCALAR\S+ 3$/,
    'rmap_scalar types'
);

like(join(' ',
    rmap_hash { $_ } @types),
    qr/^HASH\S+ HASH\S+$/,
    'rmap_hash types'
);

like(join(' ',
    rmap_array { $_ } @types),
    qr/^ARRAY\S+ ARRAY\S+$/,
    'rmap_array types'
);

like(join(' ',
    rmap_code { $_ } @types),
    qr/^CODE\S+ CODE\S+$/,
    'rmap_array types'
);

is(join(' ',
    rmap_ref { reftype($_) || $_ } @types),
    'ARRAY HASH REF SCALAR SCALAR ARRAY HASH',
    'rmap_ref types'
);


like(join(' ',
    rmap_to { $_ } GLOB|HASH, @types),
    qr/^HASH\S+ GLOB\S+ HASH\S+$/,
    'rmap_to GLOB|HASH types'
);

like(join(' ',
    rmap_to { $_ } GLOB|CODE, @types),
    qr/^GLOB\S+ CODE\S+ CODE\S+$/,
    'rmap_to GLOB|HASH types'
);

