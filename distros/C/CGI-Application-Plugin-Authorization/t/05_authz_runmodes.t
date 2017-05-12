#!/usr/bin/perl
use Test::More tests => 15;
use Test::Exception;
use Scalar::Util;

use strict;
use warnings;
use lib './t';

$ENV{CGI_APP_RETURN_ONLY} = 1;

###############################################################################
# Define a test application package.
#
# Using this test package still requires that:
# - we call 'start_mode()' explicitly to set the initial run-mode
# - we call 'authz->authz_runmodes()' to set the authorization rules
###############################################################################
{
    package TestApp;
    use base qw(CGI::Application);
    use CGI::Application::Plugin::Authorization;

    sub setup {
        my $self = shift;
        $self->run_modes( [qw(
            test_regexp
            test_coderef
            test_string
            test_all
            )] );
        $self->authz->config(
            DRIVER => [ 'Generic',
                sub {
                    my ($username, $group) = @_;
                    return ($group eq 'ok');
                },
            ] );
    }
    sub test_regexp     { return 'test_regexp' };
    sub test_coderef    { return 'test_coderef' };
    sub test_string     { return 'test_string' };
    sub test_all        { return 'test_all' };
}

###############################################################################
# Make sure that "authz_runmodes()" sets up the runmodes consistently,
# regardless of whether we pass in a list of entries or a list of list-refs.
#
# If this works, we only need to concern ourselves with testing the interface
# in one fashion from here on out.
authz_runmodes_sets_up_consistently: {
    my $app = TestApp->new();
    $app->authz->authz_runmodes(
        ['listref'          => 'for'],
        ['compatibility'    => 'with'],
        ['0.06'             => 'interface'],
        );
    $app->authz->authz_runmodes(
        'newer'     => 'interface',
        'allows'    => 'for',
        'listrefs'  => 'to',
        'be'        => 'absent',
        );
    my @authz  = $app->authz->authz_runmodes();
    my @expect = (
        ['listref'          => 'for'],
        ['compatibility'    => 'with'],
        ['0.06'             => 'interface'],
        ['newer'            => 'interface'],
        ['allows'           => 'for'],
        ['listrefs'         => 'to'],
        ['be'               => 'absent'],
        );
    is_deeply \@authz, \@expect, 'authz_runmodes() is consistent';
}

###############################################################################
# Authz runmode definition: string
authz_runmode_string: {
    test_allow: {
        my $app = TestApp->new();
        $app->start_mode( 'test_string' );
        $app->authz->authz_runmodes(
            'test_string'   => 'ok',
            ':all'          => 'fail',
            );
        my $res = $app->run();
        like $res, qr/test_string/, 'runmode definition: string (allow)';
    }
    test_forbid: {
        my $app = TestApp->new();
        $app->start_mode( 'test_string' );
        $app->authz->authz_runmodes(
            'test_string'   => 'fail',
            ':all'          => 'ok',
            );
        my $res = $app->run();
        like $res, qr/Forbidden/, 'runmode definition: string (forbid)';
    }
}

###############################################################################
# Authz runmode definition: regexp
authz_runmode_regexp: {
    test_allow: {
        my $app = TestApp->new();
        $app->start_mode( 'test_regexp' );
        $app->authz->authz_runmodes(
            qr/regexp/  => 'ok',
            ':all'      => 'fail',
            );
        my $res = $app->run();
        like $res, qr/test_regexp/, 'runmode definition: regexp (allow)';
    }
    test_allow: {
        my $app = TestApp->new();
        $app->start_mode( 'test_regexp' );
        $app->authz->authz_runmodes(
            qr/regexp/  => 'fail',
            ':all'      => 'ok',
            );
        my $res = $app->run();
        like $res, qr/Forbidden/, 'runmode definition: regexp (forbid)';
    }
}

###############################################################################
# Authz runmode definition: coderef
authz_runmode_coderef: {
    test_allow: {
        my $app = TestApp->new();
        $app->start_mode( 'test_coderef' );
        $app->authz->authz_runmodes(
            sub { $_[0] =~ /coderef/ }, 'ok',
            ':all'      => 'fail',
            );
        my $res = $app->run();
        like $res, qr/test_coderef/, 'runmode definition: coderef (allow)';
    }
    test_forbid: {
        my $app = TestApp->new();
        $app->start_mode( 'test_coderef' );
        $app->authz->authz_runmodes(
            sub { $_[0] =~ /coderef/ }, 'fail',
            ':all'      => 'ok',
            );
        my $res = $app->run();
        like $res, qr/Forbidden/, 'runmode definition: coderef (forbid)';
    }
}

###############################################################################
# Authz runmode definition: :all
authz_runmode_all: {
    test_allow: {
        my $app = TestApp->new();
        $app->start_mode( 'test_all' );
        $app->authz->authz_runmodes(
            ':all'  => 'ok',
            );
        my $res = $app->run();
        like $res, qr/test_all/, 'runmode definition: all (allow)';
    }
    test_forbid: {
        my $app = TestApp->new();
        $app->start_mode( 'test_all' );
        $app->authz->authz_runmodes(
            ':all' => 'fail',
            );
        my $res = $app->run();
        like $res, qr/Forbidden/, 'runmode definition: all (forbid)';
    }
}

###############################################################################
# Authz rules: group
authz_rules_group: {
    test_allow: {
        my $app = TestApp->new();
        $app->start_mode( 'test_string' );
        $app->authz->authz_runmodes(
            'test_string'   => 'ok',
            ':all'          => 'fail',
            );
        my $res = $app->run();
        like $res, qr/test_string/, 'authz rule: group (allow)';
    }
    test_forbid: {
        my $app = TestApp->new();
        $app->start_mode( 'test_string' );
        $app->authz->authz_runmodes(
            'test_string'   => 'fail',
            ':all'          => 'ok',
            );
        my $res = $app->run();
        like $res, qr/Forbidden/, 'authz rule: group (forbid)';
    }
}

###############################################################################
# Authz rules: list-ref of groups
authz_rules_group_list: {
    test_allow: {
        my $app = TestApp->new();
        $app->start_mode( 'test_string' );
        $app->authz->authz_runmodes(
            'test_string'   => [qw(any of these is ok)],
            ':all'          => 'fail',
            );
        my $res = $app->run();
        like $res, qr/test_string/, 'authz rule: list-ref of groups (allow)';
    }
    test_forbid: {
        my $app = TestApp->new();
        $app->start_mode( 'test_string' );
        $app->authz->authz_runmodes(
            'test_string'   => [qw(otherwise we just fail)],
            ':all'          => 'ok',
            );
        my $res = $app->run();
        like $res, qr/Forbidden/, 'authz rule: list-ref of groups (forbid)';
    }

}

###############################################################################
# Authz rules: coderef
authz_rules_coderef: {
    test_allow: {
        my $app = TestApp->new();
        $app->start_mode( 'test_string' );
        $app->authz->authz_runmodes(
            'test_string'   => sub { 1 },
            ':all'          => 'fail',
            );
        my $res = $app->run();
        like $res, qr/test_string/, 'authz rule: coderef (allow)';
    }
    test_forbid: {
        my $app = TestApp->new();
        $app->start_mode( 'test_string' );
        $app->authz->authz_runmodes(
            'test_string'   => sub { 0 },
            ':all'          => 'ok',
            );
        my $res = $app->run();
        like $res, qr/Forbidden/, 'authz rule: coderef (forbid)';
    }
}
