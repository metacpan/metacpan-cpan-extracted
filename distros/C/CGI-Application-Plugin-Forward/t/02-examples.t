#!/usr/bin/perl

use strict;
use Test::More 'no_plan';
$ENV{CGI_APP_RETURN_ONLY} = 1;
{
    package Example1;
    use vars qw(@ISA);

    use Test::More;
    use CGI::Application;
    use CGI::Application::Plugin::Forward;

    @ISA = ('CGI::Application');

    use CGI::Application::Plugin::Forward;

    sub setup {
        my $self = shift;
        $self->run_modes([qw(
            start
            second_runmode
        )]);
    }
    sub start {
        my $self = shift;
        return $self->forward('second_runmode');
    }
    sub second_runmode {
        my $self = shift;

        my $rm = $self->get_current_runmode;  # 'second_runmode'
        is($rm,'second_runmode','rm=second_runmode');
    }

}

Example1->new->run;

{
    package Example2;
    use vars qw(@ISA);

    use Test::More;
    use CGI::Application;
    use CGI::Application::Plugin::Forward;

    @ISA = ('CGI::Application');

    sub setup {
        my $self = shift;
        $self->run_modes({
            start         => 'start',
            other_action  => 'other_method',
        });
    }
    sub start {
        my $self = shift;
        return $self->forward('other_action');
    }
    sub other_method {
        my $self = shift;

        my $rm = $self->get_current_runmode;  # 'other_action'
        is($rm,'other_action','rm=other_action');
    }
}
Example2->new->run;


{
    package Example3;
    use vars qw(@ISA);

    use Test::More;
    use CGI::Application;
    use CGI::Application::Plugin::Forward;

    @ISA = ('CGI::Application');

    sub setup {
        my $self = shift;
        $self->run_modes({
            start         => 'start',
            other_action  => 'other_method',
        });
    }
    sub start {
        my $self = shift;
        return $self->other_method;
    }
    sub other_method {
        my $self = shift;

        my $rm = $self->get_current_runmode;  # 'start'
        is($rm,'start','rm=start');
    }


}

Example3->new->run;


{
    package Example4;
    use vars qw(@ISA);

    use Test::More;
    use CGI::Application;
    use CGI::Application::Plugin::Forward;

    @ISA = ('CGI::Application');

    sub setup {
        my $self = shift;
        $self->run_modes({
            start         => 'start',
            anon_action  => sub {
                my $self = shift;
                my $rm = $self->get_current_runmode;  # 'anon_action'
                is($rm,'anon_action','rm=anon_action');
            },
        });
    }
    sub start {
        my $self = shift;
        return $self->forward('anon_action');
    }



}

Example4->new->run;

