
use strict;
use Test::More 'no_plan';

$ENV{'CGI_APP_RETURN_ONLY'} = 1;

use CGI::Session;
use CGI::Session::Driver::file;

use File::Spec;

$CGI::Session::Driver::file::FileName = 'session.dat';

my $Session_ID;
my $Storage_Name = 'some_storage_name';
my $Storage_Hash;

{
    package WebApp1;
    use CGI::Application;

    use vars qw(@ISA);
    BEGIN { @ISA = qw(CGI::Application); }

    use CGI::Application::Plugin::Session;
    use CGI::Application::Plugin::FormState;

    use Test::More;

    sub setup {
        my $self = shift;

        $self->run_modes(['start']);

        $self->session_config(
            CGI_SESSION_OPTIONS => [ "driver:File", undef, { Directory => 't' } ],
        );
        $Session_ID = $self->session->id;
        $self->session->param('foo', 42);
        is($self->session->param('foo'), 42, 'new session initialized');
        $self->form_state;

    }
    sub start {
        my $self = shift;

        $self->form_state->init($Storage_Name, 'expires' => '1s');
        my $session_key = 'form_state_' . $Storage_Name . '_' . $self->form_state->id;

        my @keys = sort $self->form_state->param;
        ok(eq_array(\@keys, []), '[webapp2] form_state keys (1)');

        # Store some parameters
        $self->form_state->param(
            'name'       => 'Road Runner',
            'occupation' => 'Having Fun',
        );

        @keys = sort $self->form_state->param;
        ok(eq_array(\@keys, ['name', 'occupation']), '[webapp2] form_state keys (2)');

        is($self->form_state->param('name'),       'Road Runner', '[webapp1] form_state: name');
        is($self->form_state->param('occupation'), 'Having Fun',  '[webapp1] form_state: occupation');


    }
}

{

    package WebApp2;
    use CGI::Application;

    use vars qw(@ISA);
    BEGIN { @ISA = qw(CGI::Application); }

    use CGI::Application::Plugin::Session;
    use CGI::Application::Plugin::FormState;

    use Test::More;

    sub setup {
        my $self = shift;

        $self->run_modes(['start']);

        # init session and verify that it's got content
        $self->session_config(
            CGI_SESSION_OPTIONS => [ "driver:File", $Session_ID, { Directory => 't' } ],
        );
        is($self->session->param('foo'), 42, 'previous session initialized');

        $self->start_mode('start');
        $self->run_modes([qw/start/]);
    }
    sub start {
        my $self = shift;

        $self->form_state->init($Storage_Name);

        # Retrieve some parameters
        my @keys = sort $self->form_state->param;
        ok(eq_array(\@keys, []), '[webapp2] form_state is empty');

    }

}


WebApp1->new->run;
sleep 2;

my $query = CGI->new;
$query->param($Storage_Name, $Storage_Hash);

WebApp2->new(QUERY => $query)->run;

unlink File::Spec->catfile('t', $CGI::Session::Driver::file::FileName);


