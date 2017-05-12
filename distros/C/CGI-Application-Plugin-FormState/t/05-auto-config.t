
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
    package BaseWebApp;
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
        is($self->session->param('foo'), 42, "[" . (ref $self) ."] new session initialized");
    }
}

{
    package WebApp1;
    @WebApp1::ISA = ('BaseWebApp');
    use Test::More;

    sub start {
        my $self = shift;

        ok($self->form_state->id,          'id autoconfigs');
    }
}


{
    package WebApp2;
    @WebApp2::ISA = ('BaseWebApp');
    use Test::More;

    sub start {
        my $self = shift;

        ok($self->form_state->name,        'name autoconfigs');
    }
}

{
    package WebApp3;
    @WebApp3::ISA = ('BaseWebApp');
    use Test::More;

    sub start {
        my $self = shift;
        ok($self->form_state->session_key, 'session_key autoconfigs');

    }
}


WebApp1->new->run;
WebApp2->new->run;
WebApp3->new->run;

unlink File::Spec->catfile('t', $CGI::Session::Driver::file::FileName);


