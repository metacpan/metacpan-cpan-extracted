use strict;
use warnings;

use lib 'test-data/lib';

use App::perlvars ();
use Test::More import => [qw( done_testing is ok subtest )];

# For perl version 5.37.3 there was a change in the Perl internals such that
# some variables are no longer considered unused by Test::Vars. This is a known issue, see
# https://github.com/houseabsolute/p5-Test-Vars/issues/47
# Until this is resolved, we need to adjust the expected number of errors depending on
# the Perl version.
my $perl_old = $] <= 5.037002;

subtest 'pkg with unused vars' => sub {
    my ( $exit_code, $msg, @errors )
        = App::perlvars->new->validate_file('test-data/lib/Local/Unused.pm');
    ok( $exit_code, 'non-zero exit code' );
    my $expected = $perl_old ? 4 : 5;
    is( scalar @errors, $expected, 'found all errors' );
};

subtest 'pkg without unused vars' => sub {
    my ( $exit_code, $msg, @errors )
        = App::perlvars->new->validate_file(
        'test-data/lib/Local/NoUnused.pm');
    if ($perl_old) {
        is( $exit_code,     0, '0 exit code' );
        is( scalar @errors, 0, 'found no errors' );
    }
    else {
        is( $exit_code,     256, 'exit code 256' );
        is( scalar @errors, 1,   'found 1 error' );
    }
};

subtest 'file not found' => sub {
    my ( $exit_code, $msg, @errors )
        = App::perlvars->new->validate_file('test-data/oops');
    is( $exit_code,     1, 'exit code 1' );
    is( scalar @errors, 0, 'found no errors' );
};

done_testing();
