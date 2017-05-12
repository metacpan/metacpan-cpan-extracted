# Tests for Connector::Proxy::Proc::SafeExec
#
# Sooooo... this is a trick one. We found that in our Net::Server
# environment, Proc::SafeExec returns STDOUT from the child
# command correctly when our daemon starts. After forking and
# switching the effective user ID, however, the STDOUT was empty.
#
# In this test script, we try to see if we can reproduce the problem
# to be able to pinpoint the bug.
#

use strict;
use warnings;
use English;
use Try::Tiny;

use Test::More tests => 17;

#diag "LOAD MODULE\n";

our $req_err_ps;
our $req_err_ns;

BEGIN {
    eval 'require Proc::SafeExec;';
    our $req_err_ps = $@;

    #    use_ok( 'Connector::Proxy::Proc::SafeExec' );
    eval 'require Net::Server;';
    our $req_err_ns = $@;
}

package MyTestServer;

if ( not $req_err_ns and not $req_err_ps ) {
    eval 'use base qw( Net::Server::MultiType );'
        or die "Error using Net::Server::MultiType: $@";
    eval 'use Net::Server::Daemonize qw( set_uid set_gid );'
        or die "Error using Net::Server::Daemonize: $@";

    sub new {
        my $that  = shift;
        my $class = ref($that) || $that;
        my $self  = {};
        bless $self, $class;
        # mask isn't available by default, so let's postpone this
        eval '$self->{umask} = mask 0007;';
    }
}

package main;

#diag "Connector::Proxy::Proc::SafeExec\n";
###########################################################################
SKIP: {
    skip "Proc::SafeExec not installed", 17 if $req_err_ps;
    skip "Net::Server not installed",    17 if $req_err_ns;

    require_ok('Connector::Proxy::Proc::SafeExec');

    my $conn = Connector::Proxy::Proc::SafeExec->new(
        {   LOCATION => 't/config/test.sh',
            args     => ['foo'],
            timeout  => 2,
        }
    );

    ok( defined $conn );

    is( $conn->get(), 'foo', 'Simple invocation' );

    $conn->args( [ '--quote-character', '**', 'foo' ] );
    is( $conn->get(), '**foo**', 'Multiple arguments and options' );

    my $exception;
    $conn->args( [ '--exit-with-error', '1' ] );

    undef $exception;
    try {
        $conn->get();
    }
    catch {
        $exception = $_;
    };
    like(
        $exception,
        qr/^System command exited with return code/,
        'Error code handling'
    );

    $conn->args( [ '--sleep', '1', 'foo' ] );
    is( $conn->get(), 'foo', 'Timeout: not triggered' );

    $conn->args( [ '--sleep', '3', 'foo' ] );
    undef $exception;
    try {
        $conn->get();
    }
    catch {
        $exception = $_;
    };
    like( $exception, qr/^System command timed out/, 'Timeout: triggered' );

    ####
    # argument passing tests
    $conn->args( ['abc[% ARG.0 %]123'] );
    is( $conn->get('foo'), 'abcfoo123',
        'Passing parameters from get arguments' );

    $conn->args( ['abc[% ARG.0 %]123[% ARG.1 %]xyz'] );
    is( $conn->get( 'foo', 'bar' ),
        'abcfoo123barxyz', 'Multiple parameters from get arguments' );

    ###
    # environment tests
    $ENV{MYVAR} = '';
    $conn->args( [ '--printenv', 'MYVAR' ] );
    is( $conn->get('foo'), '', 'Environment variable test: no value' );

    $ENV{MYVAR} = 'bar';
    is( $conn->get('foo'), 'bar',
        'Environment variable test: externally set' );

    $ENV{MYVAR} = '';
    $conn->env( { MYVAR => '1234', } );
    is( $conn->get('foo'), '1234',
        'Environment variable test: internally set to static value' );

    $conn->env( { MYVAR => '1234[% ARG.0 %]', } );
    is( $conn->get('foo'), '1234foo',
        'Environment variable test: internally set with template' );

    ###
    # stdin tests
    $conn->stdin('54321');
    $conn->args( ['--'] );
    is( $conn->get('foo'), '54321', 'Passing scalar data via STDIN 1/2' );
    is( $conn->get('bar'), '54321', 'Passing scalar data via STDIN 2/2' );

    $conn->stdin('54321[% ARG.0 %]abc');
    is( $conn->get('foo'), '54321fooabc',
        'Passing data via STDIN with template' );

    $conn->stdin( [ '1234[% ARG.0 %]abc', '4321[% ARG.1 %]def' ] );
    is( $conn->get( 'foo', 'bar' ), '1234fooabc
4321bardef', 'Passing multiple lines via STDIN'
    );

}

