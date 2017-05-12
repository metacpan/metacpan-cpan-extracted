use Test::More tests => 17;

SKIP: {
    eval "use Getopt::Long 2.36";
    skip "Getopt::Long 2.36 or higher not installed", 17, if $@;

    use App::Rad;

    @ARGV = qw(herculoids --igoo=ape -t 4 --zok=3.14 --glup -abc);

    # kids, don't try this at home...
    my $c = {};
    bless $c, 'App::Rad';
    $c->_init();
    $c->_get_input();

    $c->getopt(
            'igoo|i=s',
            'tundro|t=i',
            'zok|z=f',
            'glup',
            'glip',
            'a',
            'b',
            'c',
        );

    is($c->cmd, 'herculoids', 'command name should be set');
    is(scalar @ARGV, 6, '@ARGV should have 6 elements');
    is(scalar @{$c->argv}, 0, '$c->argv should have been consumed');
    is(keys %{$c->options}, 7, '$c->options should have 7 elements');
    is_deeply(\@ARGV, ['--igoo=ape', '-t', '4', '--zok=3.14',
                       '--glup', '-abc'
                      ],
              '@ARGV should have just the passed arguments, not the command name'
             );

    is($c->options->{'igoo'}, 'ape', '--igoo should be set');
    ok(defined $c->options->{'tundro'}, '--tundro should be defined');
    ok(!defined $c->options->{'t'}, '-t should have become --tundro');
    is($c->options->{'tundro'}, 4, '--tundro should be set');

    ok(defined $c->options->{'zok'}, '--zok should be defined');
    is($c->options->{'zok'}, 3.14, '--zok should be set');
    ok(!defined $c->options->{'z'}, '-z should not be set');

    ok(defined $c->options->{'glup'}, '--glup should be defined');
    ok(!defined $c->options->{'glip'}, '--glip should not be defined');

    ok(defined $c->options->{'a'}, '-a should be defined');
    ok(defined $c->options->{'a'}, '-a should be defined');
    ok(defined $c->options->{'a'}, '-a should be defined');

}
