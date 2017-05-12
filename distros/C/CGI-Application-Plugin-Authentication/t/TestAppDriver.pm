package TestAppDriver;

use base qw(CGI::Application);
use CGI::Application::Plugin::Authentication;
use Test::More;
use CGI ();

sub setup {
    my $self = shift;
    $self->start_mode('unprotected');
    $self->run_modes([qw(unprotected protected)]);
    $self->authen->protected_runmodes(qw(protected));
}

sub unprotected {
    my $self     = shift;
    my $username = $self->authen->username;
    return "username:$username\n";
}

sub protected {
    my $self     = shift;
    my $username = $self->authen->username;
    return "username:$username\n";
}

#
# These tests should pass with the credentials that were passed
#  But other tests are performed that should successfully fail
#
sub run_authen_tests {
    my $class       = shift;
    my $credentials = shift;
    my @testdata    = @_;

    $ENV{CGI_APP_RETURN_ONLY} = 1;


    foreach my $data (@testdata) {
        my ($params, $query, $cgiapp, $results);

        # Successful Login
        $params = { map { $credentials->[$_] => $data->[$_] } 0..$#$credentials };
        $params->{rm} = 'protected';
        $query = CGI->new( $params );
        $cgiapp = $class->new( QUERY => $query );
        $results = $cgiapp->run;

        ok($cgiapp->authen->is_authenticated,'successful login');
        is( $cgiapp->authen->username, $data->[0], 'successful login - username set' );

        # Missing Credentials
        $params = { map { $credentials->[$_] => $data->[$_] } 1..$#$credentials };
        $params->{rm} = 'protected';
        $query = CGI->new( $params );
        $cgiapp = $class->new( QUERY => $query );
        $results = $cgiapp->run;

        ok(!$cgiapp->authen->is_authenticated,'missing credentials - login failure');
        is( $cgiapp->authen->username, undef, 'missing credentials - username not set' );

        # Bad user or password
        $params = { map { $credentials->[$_] => 'badvalue' } 0..$#$credentials };
        $params->{rm} = 'protected';
        $query = CGI->new( $params );
        $cgiapp = $class->new( QUERY => $query );
        $results = $cgiapp->run;

        ok(!$cgiapp->authen->is_authenticated,'login failure');
        is( $cgiapp->authen->username, undef, "login failure - username not set" );
    }
}


#
# These tests should pass with the credentials that were passed
#
sub run_authen_success_tests {
    my $class       = shift;
    my $credentials = shift;
    my @testdata    = @_;

    $ENV{CGI_APP_RETURN_ONLY} = 1;


    foreach my $data (@testdata) {
        my ($params, $query, $cgiapp, $results);

        # Failed Login
        $params = { map { $credentials->[$_] => $data->[$_] } 0..$#$credentials };
        $params->{rm} = 'protected';
        $query = CGI->new( $params );
        $cgiapp = $class->new( QUERY => $query );
        $results = $cgiapp->run;

        ok( $cgiapp->authen->is_authenticated,'good credentials - login success');
        is( $cgiapp->authen->username, $data->[0], 'good credentials - username set' );

    }
}

#
# These tests should fail with the credentials that were passed
#
sub run_authen_failure_tests {
    my $class       = shift;
    my $credentials = shift;
    my @testdata    = @_;

    $ENV{CGI_APP_RETURN_ONLY} = 1;


    foreach my $data (@testdata) {
        my ($params, $query, $cgiapp, $results);

        # Failed Login
        $params = { map { $credentials->[$_] => $data->[$_] } 0..$#$credentials };
        $params->{rm} = 'protected';
        $query = CGI->new( $params );
        $cgiapp = $class->new( QUERY => $query );
        $results = $cgiapp->run;

        ok(!$cgiapp->authen->is_authenticated,'failed credentials - login failure');
        is( $cgiapp->authen->username, undef, 'failed credentials - username not set' );

    }
}

1;
