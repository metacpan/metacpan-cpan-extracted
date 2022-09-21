use strict;
use warnings;
use Test::More;
use Test::Alien;

BEGIN {
    use_ok('Alien::sqlite') or BAIL_OUT('Failed to load Alien::sqlite');
}

alien_ok 'Alien::sqlite';

diag(
    sprintf(
        'Testing Alien::sqlite %s, Perl %s, %s',
        $Alien::sqlite::VERSION, $], $^X
    )
);

#  something of a canary so we don't pack Mojolicious
#  when packaging for CPAN
if (!eval 'require Mojo::DOM58') {
    diag 'testing without Mojo::DOM58';
}

done_testing();

