#!perl -T

use Test::More;

BEGIN {
    use_ok('Config::TT2') || print "Bail out!\n";
}

my $tests = [
    {
        name   => 'set template.title via META',
        vars   => undef,
        cfg    => '[% META title = "bar"; title = template.title %]',
        expect => { title => 'bar' },
    },

    {
        name   => 'template.name is "input text"',
        vars   => undef,
        cfg    => '[% name = template.name %]',
        expect => { name => 'input text' },
    },

    {
        name   => 'component.name is "header"',
        vars   => undef,
        cfg    => '[% BLOCK header; name = component.name; END; PROCESS "header" %]',
        expect => { name => 'header' },
    },
];

foreach my $test (@$tests) {
    my $tcfg = Config::TT2->new();
    my $stash = $tcfg->process( \$test->{cfg}, $test->{vars} );
    delete $stash->{global};

    is_deeply( $stash, $test->{expect}, $test->{name} );
} 

done_testing(4);

