#!/usr/bin/env perl
#
# $Id$
#
use strict;
use warnings;
use version; our $VERSION = qv('0.1.0');

{

    package TestApp;
    use Catalyst qw(+CatalystX::Plugin::Engine::FastCGI::Lighttpd);
    __PACKAGE__->setup;

    sub default : Path : Args {
        my ( $self, $c ) = @_;
        $c->res->body('OK');
        return;
    }
}

use Catalyst::Test qw(TestApp);
use Test::More tests => 3;

local *STDERR;
open STDERR, '>', \my $stderr or die $!;
get('/');
like(
    $stderr,
    qr/\Q: This plugin should run on Lighttpd.\E/ms,
    'warning no-lighttpd'
);
like(
    $stderr,
    qr/\Q: This plugin should run on FastCGI.\E/ms,
    'warning no-fastcgi'
);
undef $stderr;

TODO: {
    local $TODO = 'It is difficult to write test using lighttpd and fastcgi.';
    pass('[FIXME] Please write tests.');
}
