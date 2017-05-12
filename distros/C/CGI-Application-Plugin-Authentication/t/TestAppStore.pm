package TestAppStore;

use base qw(CGI::Application);
use CGI::Application::Plugin::Authentication;
use Test::More;
use CGI ();

$ENV{CGI_APP_RETURN_ONLY} = 1;

sub setup {
    my $self = shift;
    $self->start_mode('unprotected');
    $self->run_modes([qw(unprotected protected)]);
    $self->authen->protected_runmodes(qw(protected));
}

sub unprotected {
    my $self     = shift;
    my $username = $self->authen->username || '';
    return "unprotected\nusername:$username\n";
}

sub protected {
    my $self     = shift;
    my $username = $self->authen->username;
    return "protected\nusername:$username\n";
}

# helper class method that runs the app with certain parameters
our ($CGIAPP, $RESULTS);
sub run_app {
    my $class  = shift;
    my $params = shift || {};
    my $query  = CGI->new( $params );
    $class->maintain_state($CGIAPP, $RESULTS, $query) if $CGIAPP && $RESULTS;
    $CGIAPP = $class->new( QUERY => $query );
    $RESULTS = $CGIAPP->run;
    my $store_entries = $class->can('get_store_entries') ? $class->get_store_entries($CGIAPP, $RESULTS) : undef;
    return ($CGIAPP, $RESULTS, $store_entries);
}

sub maintain_state {}

sub clear_state {
    my $class = shift;
    $CGIAPP = undef;
    $RESULTS = undef;
}



sub run_store_tests {
    my $class = shift;
    my ( $cgiapp, $results, $store_entries );

    # Regular call to unprotected page shouldn't create a store entry
    ($cgiapp, $results, $store_entries) = $class->run_app( { rm => 'unprotected' } );
    ok(!$store_entries, "Store entry not created when calling unprotected page" );

    # Regular call to protected page (without a valid login) shouldn't create a store entry
    ($cgiapp, $results, $store_entries) = $class->run_app( { rm => 'protected' } );
    ok(!$store_entries, "Store entry not created when calling protected page without valid login" );

    # Regular call to protected page (with an invalid login) should create a store entry marking login attempts
    ($cgiapp, $results, $store_entries) = $class->run_app( { rm => 'protected', auth_username => 'test', auth_password => 'badpassword' } );
    ok(!$cgiapp->authen->is_authenticated,'failed login attempt');
    ok($store_entries, "Store entry created when calling protected page with invalid login" );
    isnt($store_entries->{username}, 'test', "Store entry contained the right username" );
    is($store_entries->{login_attempts}, 1, "Store entry contained the right value for login_attempts" );

    # Regular call to protected page (with an invalid login) should create a store entry marking login attempts
    ($cgiapp, $results, $store_entries) = $class->run_app( { rm => 'protected', auth_username => 'test', auth_password => 'badpassword' } );
    ok(!$cgiapp->authen->is_authenticated,'failed login attempt');
    ok($store_entries, "Store entry created when calling protected page with invalid login" );
    isnt($store_entries->{username}, 'test', "Store entry contained the right username" );
    is($store_entries->{login_attempts}, 2, "Store entry contained the right value for login_attempts" );

    # Regular call to protected page (with a valid login) should create a store entry
    ($cgiapp, $results, $store_entries) = $class->run_app( { rm => 'protected', auth_username => 'test', auth_password => '123' } );
    ok($cgiapp->authen->is_authenticated,'successful login');
    ok($store_entries, "Store entry created when calling protected page with valid login" );
    is($store_entries->{username}, 'test', "Store entry contained the right username" );
    ok(!$store_entries->{login_attempts}, "Store entry cleared login_attempts" );

}

1;
