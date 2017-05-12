package TestAppDriver;

use base qw(CGI::Application);
use CGI::Application::Plugin::Authorization;
use Test::More;

#
# These tests should pass with the parameters that were passed
#
sub run_authz_success_tests {
    my $class    = shift;
    my @testdata = @_;

    my $cgiapp = $class->new();

    foreach my $data (@testdata) {
        # Successful authz
        ok($cgiapp->authz->authorize(@$data), 'successful authz');
    }
}


#
# These tests should fail with the parameters that were passed
#
sub run_authz_failure_tests {
    my $class    = shift;
    my @testdata = @_;

    my $cgiapp = $class->new();

    foreach my $data (@testdata) {
        # Failed authz
        ok(!$cgiapp->authz->authorize(@$data), 'failed authz');
    }
}


1;
