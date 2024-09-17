use strict;
use warnings;

use lib 'test-data/lib';

use App::perlvars ();
use Test::More import => [qw( done_testing is ok subtest )];

subtest 'pkg with unused vars' => sub {
    my ( $exit_code, $msg, @errors )
        = App::perlvars->new->validate_file('test-data/lib/Local/Unused.pm');
    ok( $exit_code, 'non-zero exit code' );
    is( scalar @errors, 4, 'found all errors' );
};

subtest 'pkg without unused vars' => sub {
    my ( $exit_code, $msg, @errors )
        = App::perlvars->new->validate_file(
        'test-data/lib/Local/NoUnused.pm');
    is( $exit_code,     0, '0 exit code' );
    is( scalar @errors, 0, 'found no errors' );
};

subtest 'file not found' => sub {
    my ( $exit_code, $msg, @errors )
        = App::perlvars->new->validate_file('test-data/oops');
    is( $exit_code,     1, 'exit code 1' );
    is( scalar @errors, 0, 'found no errors' );
};

done_testing();
