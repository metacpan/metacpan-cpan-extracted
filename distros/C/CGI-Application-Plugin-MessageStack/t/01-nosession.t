use Test::More tests => 2;

use lib './t';
use strict;

$ENV{CGI_APP_RETURN_ONLY} = 1;

use CGI;
use TestAppNoSession;

eval {
    my $t1_obj = TestAppNoSession->new(QUERY=>CGI->new());
    my $t1_output = $t1_obj->run();
};

my $err = $@;
my $test_name = "testing for die() since we did't use a session";
ok( $err, $test_name );

$test_name = 'testing for right error message';
ok( $err =~ /No session object!/, $test_name );