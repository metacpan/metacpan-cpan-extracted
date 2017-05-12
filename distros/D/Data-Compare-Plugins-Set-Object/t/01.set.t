use Test::More tests => 4;

BEGIN {
use_ok( 'Set::Object' );
use_ok( 'Data::Compare', 0.06 );
}

$foo = {
    list => [ qw(one two three) ],
    set  => Set::Object->new( [1], [2], [3] ),
};
$bar = {
    list => [ qw(one two three) ],
    set  => Set::Object->new( [1], [2], [3] ),
};

isnt($foo->{set}, $bar->{set}, 'set comparison');
ok(Compare($foo, $bar), 'Data::Compare comparison');
