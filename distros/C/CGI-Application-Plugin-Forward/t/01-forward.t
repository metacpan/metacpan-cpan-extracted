#!/usr/bin/perl

use strict;
# the number of tests is important, because we want to make sure that
# all run modes are actually reached
use Test::More 'tests' => 8;

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
            action_two => 'meth_two',
            action_not => 'zzzzzzzz',
        });
    }

    sub meth_one {
        my $self = shift;
        is($self->get_current_runmode, 'action_one', '[meth_one] crm: action_one');
        $self->other_method('foo');
        '';
    }
    sub other_method {
        my $self = shift;
        my @params = @_;
        ok(eq_array(\@params, ['foo']),              '[other_method] params');
        is($self->get_current_runmode, 'action_one', '[other_method] crm: action_one');
        my $output = $self->forward('action_two', 'bar', 'baz');
        is($output, 'other_runmode_output',  'other_runmode output');
        eval {
            $output = $self->forward('non_existent', 'bar', 'baz');
        };
        ok($@, 'prevented from forwarding to non-existent run mode');
        eval {
            $output = $self->forward('action_not', 'bar', 'baz');
        };
        ok($@, 'prevented from forwarding to non-existent run mode method');
        '';
    }
    sub meth_two {
        my $self = shift;
        my @params = @_;
        ok(eq_array(\@params, ['bar', 'baz']),          '[meth_two] params');
        is($self->get_current_runmode, 'action_two',    '[meth_two] crm: action_two');
        return 'other_runmode_output';
    }

}


WebApp->new->run;



