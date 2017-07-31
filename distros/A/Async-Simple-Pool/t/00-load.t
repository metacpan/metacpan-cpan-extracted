#!perl -T

use strict;
use warnings;
use Test::More;

plan tests => $^O =~ /^(dos|os2|MSWin32|NetWare)$/ ? 3 : 4;

BEGIN {
    use_ok( 'Async::Simple::Pool'              ) || print "Bail out!\n";
    use_ok( 'Async::Simple::Task'              ) || print "Bail out!\n";

    unless ( $^O =~ /^(dos|os2|MSWin32|NetWare)$/ ) {
        use_ok( 'Async::Simple::Task::Fork'        ) || print "Bail out!\n";
    };

    use_ok( 'Async::Simple::Task::ForkTmpFile' ) || print "Bail out!\n";
}

diag( "Testing Async::Simple::Pool $Async::Simple::Pool::VERSION, Perl $], $^X" );
