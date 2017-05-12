#!/usr/bin/perl

use strict;
# the number of tests is important, because we want to make sure that
# all run modes are actually reached
use Test::More 'tests' => 3;

{
    package WebApp;
    use vars qw(@ISA);

    use Test::More;
    use CGI::Application;
    use CGI::Application::Plugin::Forward;

    @ISA = ('CGI::Application');

    sub setup {
        my $self = shift;
        $self->header_type('none');
        $self->start_mode('action_one');
        $self->run_modes({
            action_one => 'meth_one',
            action_two => sub {
                my $self = shift;
                is($self->get_current_runmode, 'action_two', '[codref] crm: action_two');
                return "coderefs work";
            },
        });
    }

    sub meth_one {
        my $self = shift;
        is($self->get_current_runmode, 'action_one', '[meth_one] crm: action_one');
        my $output = $self->forward('action_two');
        is($output, 'coderefs work',  'coderefs work');
    }

}


WebApp->new->run;
