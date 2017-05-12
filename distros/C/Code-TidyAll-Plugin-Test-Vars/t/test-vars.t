#!/usr/bin/perl

use strict;
use warnings;

use Capture::Tiny qw( capture_merged );
use Code::TidyAll;
use Path::Class qw( dir );
use Test::More;

my $temp_dir = Path::Class::tempdir( CLEANUP => 1 );

subtest 'No unused variables' => sub {
    my $module = $temp_dir->file('Good.pm');
    $module->spew(<<'EOF');
package Good;

sub test {
    my $used = 1;
    print $used;
}

1;
EOF

    my $result = _test_file( $module, qr/^\[checked\] Good.pm\n$/ );
    ok( !$result->error, 'result is not an error' );
};

subtest 'One unused variable' => sub {
    my $module = $temp_dir->file('Bad.pm');
    $module->spew(<<'EOF');
package Bad;

sub test {
    my $unused = 1;
    print 1;
}

1;
EOF

    my $result
        = _test_file( $module, qr/\$unused is used once in &Bad::test/ );
    ok( $result->error, 'result is an error' );
};

sub _test_file {
    my $module      = shift;
    my $expected    = shift;
    my $expected_rv = shift;

    my $ct = Code::TidyAll->new(
        root_dir => $temp_dir,
        plugins  => { 'Test::Vars' => { select => $module->basename }, }
    );

    my ( $output, $result ) = capture_merged { $ct->process_all() };
    like( $output, $expected, 'expected output' );
    return $result;
}

done_testing();
