#!/usr/bin/perl

use strict;
# the number of tests is important, because we want to make sure that
# all run modes are actually reached
use Test::More;

BEGIN {
    eval {
        require CGI::Application::Plugin::AutoRunmode;
    };
    if ($@) {
        plan skip_all => 'CGI::Application::Plugin::AutoRunmode not installed';
    }
    if (!CGI::Application->can('new_hook')) {
        plan skip_all => 'installed CGI::Application does not support callbacks';
    }
    else {
        if (CGI::Application::Plugin::AutoRunmode->can('is_auto_runmode')) {
            plan 'tests' => 17;
            CGI::Application::Plugin::AutoRunmode->import('cgiapp_prerun');
        }
        else {
            plan skip_all => 'installed CGI::Application::Plugin::AutoRunmode does not support is_auto_runmode';
        }
    }
}

{
    package WebApp;
    use vars qw(@ISA);

    use Test::More;
    use CGI::Application;
    BEGIN { @ISA = ('CGI::Application'); }

    use CGI::Application::Plugin::Forward;
    BEGIN {
        CGI::Application::Plugin::AutoRunmode->import('cgiapp_prerun');
    }


    sub setup {
        my $self = shift;
        $self->header_type('none');
        $self->param('hook' => 0);
        $self->add_callback('forward_prerun', \&hooked_method);
    }

    sub meth_one : StartRunmode {
        my $self = shift;
        is($self->get_current_runmode, 'meth_one',   '[meth_one] crm: meth_one');
        ok(!$self->param('hook'),                    '[meth_one] hook not called yet 1');
        $self->other_method('foo');
        ok(!$self->param('hook'),                    '[meth_one] hook not called yet 2');
        '';
    }
    sub other_method : Runmode {
        my $self = shift;
        my @params = @_;
        ok(!$self->param('hook'),                    '[other_method] hook not called yet 1');
        ok(eq_array(\@params, ['foo']),              '[other_method] params');
        is($self->get_current_runmode, 'meth_one',   '[other_method] crm: meth_one');
        my $output = $self->forward('meth_two', 'bar', 'baz');
        is($self->param('hook'), 'meth_two',         '[other_method] hook called');
        $self->param('hook' => 0);
        ok(!$self->param('hook'),                    '[other_method] hook not called yet 2');
        is($output, 'other_runmode_output',  'other_runmode output');
        eval {
            $output = $self->forward('non_existent', 'bar', 'baz');
        };
        ok($@, 'prevented from forwarding to non-existent run mode');
        ok(!$self->param('hook'),                    '[other_method] hook not called yet 3 (after non-existent)');
        eval {
            $output = $self->forward('action_not', 'bar', 'baz');
        };
        ok(!$self->param('hook'),                    '[other_method] hook not called yet 4 (after non-existent)');
        ok($@, 'prevented from forwarding to non-existent run mode method');
        is($self->get_current_runmode, 'meth_two',   '[other_method] crm: meth_one');
        '';
    }
    sub meth_two : Runmode {
        my $self = shift;
        my @params = @_;
        ok($self->param('hook'),                        '[meth_two] hook called');
        ok(eq_array(\@params, ['bar', 'baz']),          '[meth_two] params');
        is($self->get_current_runmode, 'meth_two',      '[meth_two] crm: meth_two');
        return 'other_runmode_output';
    }
    sub action_not {
        my $self = shift;
    }
    sub hooked_method {
        my $self = shift;
        $self->param('hook' => $self->get_current_runmode);
    }

}


WebApp->new->run;




