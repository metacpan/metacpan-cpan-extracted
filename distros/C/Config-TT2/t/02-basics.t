#!perl -T

use Test::More;

BEGIN {
    use_ok('Config::TT2') || print "Bail out!\n";
}

my $tests = [
    {
        name   => 'simple scalar',
        vars   => undef,
        cfg    => '[% foo = 1 %]',
        expect => { foo => 1 }
    },

    {
        name   => 'simple scalar, predefined var',
        vars   => { bar => 'baz' },
        cfg    => '[% foo = bar %]',
        expect => { foo => 'baz', bar => 'baz' }
    },

    {
        name   => 'list and join',
        vars   => undef,
        cfg    => '[% foo = [1 2 3 4]; bar = foo.join(":") %]',
        expect => { foo => [ 1, 2, 3, 4 ], bar => '1:2:3:4' }
    },

    {
        name => 'hash and import',
        vars => { hash2 => { one => 1, two => 2 } },
        cfg  => '[% foo = {}; foo.import(hash2) %]',
        expect =>
          { foo => { one => 1, two => 2 }, hash2 => { one => 1, two => 2 } }
    },

];

foreach my $test (@$tests) {
    my $tcfg = Config::TT2->new;
    my $stash = $tcfg->process( \$test->{cfg}, $test->{vars} );
    delete $stash->{global};

    is_deeply( $stash, $test->{expect}, $test->{name} );
} 


done_testing(5);

