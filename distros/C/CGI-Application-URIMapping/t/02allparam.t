#! /usr/bin/perl

use Test::More tests => 7;

use strict;
use warnings;

$ENV{CGI_APP_RETURN_ONLY} = 1;

BEGIN {
    use_ok('CGI::Application::URIMapping', ':all');
};

our $callback = sub {};

package T::URIMapping;

use base qw/CGI::Application::URIMapping/;

sub require_module {
}

package T::Start;

use base qw/CGI::Application/;

T::URIMapping->register({
    path  => '/:p1?/:p2?',
    rm    => 'start',
    query => [ qw/q1 q2/ ],
});

sub start {
    $main::callback->(@_);
}

package main;

$callback = sub {
    my $app = shift;
    is($app->all_param('q1'), 'a');
    is($app->all_param('q2'), 'b');
    is($app->all_param('q3'), 'c');
    $app->all_param('p1', 'A');
    is($app->param('p1'), 'A');
    is($app->all_param('p1'), 'A');
    $app->param('p1', 'B');
    is($app->all_param('p1'), 'B');
};

T::URIMapping->dispatch(
    args_to_new => {
        QUERY => CGI->new('q1=a&q2=b&q3=c'),
    },
);
