#!perl -T

use Test::More;

BEGIN {
    use_ok('Config::TT2') || print "Bail out!\n";
}

my $tests = [
    {
        name   => 'used global as scalar',
        vars   => undef,
        cfg    => '[% global = 1 %]',
        expect => { global => 1 },
    },

    {
        name   => 'used global as struct',
        vars   => undef,
        cfg    => '[% global.foo = 1 %]',
        expect => { global => {foo => 1} },
    },

    {
        name   => 'used predefined global as struct',
        vars   => { global => [ 1, 2, 3, 4 ] },
        cfg    => '',
        expect => { global => [ 1, 2, 3, 4 ] },
    },

    {
        name   => 'change predefined global',
        vars   => { global => [ 1, 2, 3, 4 ] },
        cfg    => '[% global.0 = 0 %]',
        expect => { global => [ 0, 2, 3, 4 ] },
    },

];

foreach my $test (@$tests) {
    my $tcfg = Config::TT2->new;
    my $stash = $tcfg->process( \$test->{cfg}, $test->{vars} );
    is_deeply( $stash, $test->{expect}, $test->{name} );
} 


done_testing(5);

