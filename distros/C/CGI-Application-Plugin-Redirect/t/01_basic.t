use Test::More tests => 8;
BEGIN { use_ok('CGI::Application::Plugin::Redirect') }

use lib './t';
use strict;

$ENV{CGI_APP_RETURN_ONLY} = 1;

{

    package TestAppBasic;

    use CGI::Application;
    @TestAppBasic::ISA = qw(CGI::Application);
    use CGI::Application::Plugin::Redirect;

    sub setup {
        my $self = shift;
        $self->start_mode('test_mode');
        $self->run_modes( test_mode => 'test_mode' );
    }

    sub cgiapp_prerun {
        my $self = shift;

        if ($self->param('PRERUN_TEST')) {
            return $self->redirect('http://example.com/');
        }
    }

    sub test_mode {
        my $self = shift;

        if ($self->param('RUNMODE_TEST')) {
            return $self->redirect('http://other.example.com/');
        } elsif ($self->param('RUNMODE_STATUS_TEST')) {
            return $self->redirect('http://status.example.com/', '301 Moved Permanently');
        }
        return "test_mode return value";
    }

};

# Test redirect in prerun
my $t1_obj    = TestAppBasic->new( PARAMS => { PRERUN_TEST => 1 } );
my $t1_output = $t1_obj->run();

unlike( $t1_output, qr/test_mode return value/, 'test_mode return value' );
like( $t1_output, qr{Location:\s+http://example\.com/}, 'Location set correctly' );

# test redirect in runmode
$t1_obj    = TestAppBasic->new( PARAMS => { RUNMODE_TEST => 1 } );
$t1_output = $t1_obj->run();

unlike( $t1_output, qr/test_mode return value/, 'test_mode return value' );
like( $t1_output, qr{Location:\s+http://other\.example\.com/}, 'Location set correctly' );

# test redirect with a custom status value
$t1_obj    = TestAppBasic->new( PARAMS => { RUNMODE_STATUS_TEST => 1 } );
$t1_output = $t1_obj->run();

unlike( $t1_output, qr/test_mode return value/, 'test_mode return value' );
like( $t1_output, qr{Location:\s+http://status\.example\.com/}, 'Location set correctly' );
like( $t1_output, qr{Status:\s+301 Moved Permanently}, 'Status set correctly' );

