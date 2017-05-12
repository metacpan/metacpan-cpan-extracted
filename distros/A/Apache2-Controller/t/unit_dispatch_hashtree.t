#!/usr/bin/perl

use strict;
use warnings FATAL => 'all';
use blib;

package TestApp::HashTree::Dispatch;

use base qw( Apache2::Controller::Dispatch::HashTree );

sub dispatch_map { {
    foo => {
        default     => 'TestApp::HashTree::Foo',
        bar => {
            biz         => 'TestApp::HashTree::Biz',
            baz         => 'TestApp::HashTree::Baz',
        },
    },
    default => 'TestApp::HashTree::Default',
} }

1;

=for comment

 /subdir/foo                    TestApp::HashTree::Foo->default()
 /subdir/foo/bar                TestApp::HashTree::Foo->bar()
 /subdir/foo/bar/zerm           TestApp::HashTree::Foo->bar(), path_args == ['zerm']
 /subdir/foo/bar/biz            TestApp::HashTree::Biz->default()
 /subdir/foo/biz/baz/noz/wiz    TestApp::HashTree::Baz->noz(), path_args == ['wiz']

=cut

package main;

use strict;
use warnings;
use English '-no_match_vars';

use Log::Log4perl qw(:easy);
use FindBin;
use lib "$FindBin::Bin/lib";

use Test::More qw( no_plan );
use YAML::Syck;

use Apache2::Controller::Test::Mockr;
use Apache2::Controller::X;


my $tests = Load(q{
    foo:
        controller:         TestApp::HashTree::Foo
        method:             default
        relative_uri:       foo

    'foo/bar':
        controller:         TestApp::HashTree::Foo
        method:             bar
        relative_uri:       foo

    'foo/bar/zerm':
        controller:         TestApp::HashTree::Foo
        method:             bar
        relative_uri:       foo
        path_args:
            - zerm

    'foo/bar/biz':
        controller:         TestApp::HashTree::Biz
        relative_uri:       foo/bar/biz
        method:             default

    'foo/bar/baz/noz/wiz':
        controller:         TestApp::HashTree::Baz
        method:             noz
        relative_uri:       foo/bar/baz
        path_args:
            - wiz

    '/':
        controller:         TestApp::HashTree::Default
        method:             default
        relative_uri:       ''

    bar:
        controller:         TestApp::HashTree::Default
        method:             bar
        relative_uri:       ''
    
    lame:
        controller:         TestApp::HashTree::Default
        method:             default
        relative_uri:       ''

    'bar/none/some':
        controller:         TestApp::HashTree::Default
        method:             bar
        relative_uri:       ''
        path_args:
            - none
            - some

    'lame/lamer/lamest':
        controller:         TestApp::HashTree::Default
        method:             default
        relative_uri:       ''
        path_args:
            - lame
            - lamer
            - lamest
});

URI:
for my $uri ('/', sort keys %{$tests}) {
    my $request_uri = $uri eq '/' ? '' : $uri;
    my $mock = Apache2::Controller::Test::Mockr->new(
        location            => '/subdir',
        uri                 => "/subdir/$request_uri",
    );
    my $dispatcher = TestApp::HashTree::Dispatch->new($mock);
    my $controller;
    eval { $controller = $dispatcher->find_controller() };

    if (my $X = Exception::Class->caught('Apache2::Controller::X')) {
        DEBUG("$X: \n".$X->trace());
        print "# caught X (check logs): $X\n";
    }
    elsif ($EVAL_ERROR) {
        print "# unknown error: $EVAL_ERROR\n";
    }

    my $pnotes = $mock->pnotes;
    DEBUG "PNOTES:\n".Dump($pnotes);

    is($pnotes->{a2c}{$_} => $tests->{$uri}{$_}, "$uri $_") 
        for qw( controller method relative_uri );

    if ($tests->{$uri}{path_args}) {
        is_deeply(
            $pnotes->{a2c}{path_args}, 
            $tests->{$uri}{path_args}, 
            "$uri path_args"
        );
    }
}


1;
