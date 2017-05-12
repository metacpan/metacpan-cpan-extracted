
use strict;
use Test::More 'no_plan';

$ENV{'CGI_APP_RETURN_ONLY'} = 1;

use CGI::Session;
use CGI::Session::Driver::file;

use File::Spec;

$CGI::Session::Driver::file::FileName = 'session.dat';

my $Session_ID;
my $Storage_Name = 'cap_form_state';
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
        is($self->session->param('foo'), 42, '[webapp1] new session initialized');
    }
    sub start {
        my $self = shift;

        my @keys = sort $self->form_state->param;
        ok(eq_array(\@keys, []), '[webapp2] form_state keys (1)');

        # Store some parameters
        $self->form_state->param('name' =>   'Road Runner');
        is($self->form_state->param('name'), 'Road Runner',  '[webapp1] form_state: name');

        @keys = sort $self->form_state->param;
        ok(eq_array(\@keys, ['name']), '[webapp2] form_state keys (2)');

        $self->form_state->clear_params;
        is($self->form_state->param('name'), undef,          '[webapp1] form_state: name (cleared)');

        @keys = sort $self->form_state->param;
        ok(eq_array(\@keys, []), '[webapp2] form_state keys (3)');

        $self->form_state->param('name' =>   'Bugs Bunny');
        $self->form_state->param('occupation' => 'Having Fun');

        # Store some other parameters via hashref
        $self->form_state->param({
            'name2'      => 'Wile E. Coyote',
            'occupation' => 'Cartoon Character',
        });

        @keys = sort $self->form_state->param;
        ok(eq_array(\@keys, ['name', 'name2', 'occupation']), '[webapp2] form_state keys (4)');

        is($self->form_state->param('name'),        'Bugs Bunny',        '[webapp1] form_state: name');
        is($self->form_state->param('name2'),       'Wile E. Coyote',    '[webapp1] form_state: name2');
        is($self->form_state->param('occupation'),  'Cartoon Character', '[webapp1] form_state: occupation');

        my $t = $self->load_tmpl('t/tmpl/basic.html');

        my $output = $t->output;

        $Storage_Hash = $self->form_state->id;

        my $session_key = 'form_state_cap_form_state_' . $self->form_state->id;
        is($session_key, $self->form_state->session_key, 'session key');
        is($self->form_state->name, 'cap_form_state',    'name');

        is($output, "$Storage_Name:$Storage_Hash", 'form_state_id added to output');
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
        is($self->session->param('foo'), 42, '[webapp2] previous session initialized');

        $self->start_mode('start');
        $self->run_modes([qw/start/]);
    }
    sub start {
        my $self = shift;

        # Retrieve some parameters
        my @keys = sort $self->form_state->param;
        ok(eq_array(\@keys, ['name', 'name2', 'occupation']), '[webapp2] form_state keys');

        # Retrieve some parameters
        is($self->form_state->param('name'),        'Bugs Bunny',        '[webapp2] form_state: name');
        is($self->form_state->param('name2'),       'Wile E. Coyote',    '[webapp2] form_state: name2');
        is($self->form_state->param('occupation'),  'Cartoon Character', '[webapp2] form_state: occupation');

    }

}

WebApp1->new->run;

my $query = CGI->new;
$query->param($Storage_Name, $Storage_Hash);

WebApp2->new(QUERY => $query)->run;

unlink File::Spec->catfile('t', $CGI::Session::Driver::file::FileName);

