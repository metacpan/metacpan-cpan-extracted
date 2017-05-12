#!perl
# live_warnings.t 
# Copyright (c) 2006 Jonathan Rockway <jrockway@cpan.org>

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";

package foolog;

sub new { bless {} => shift; }

sub warn {
    my $self = shift;
    $self->{message} = shift;
}

sub get_warning {
    my $self = shift;
    return $self->{message};
}

sub AUTOLOAD {
    return;
}

1;

package main;
use Test::More tests => 8;
use Catalyst::Test 'TestApp';

TestApp->log(foolog->new);
isa_ok(TestApp->log, 'foolog');

ok(my $r = request('/warnings'), 'request /warnings');
is($r->content, 'Hello, warnings!', '/warnings worked');

ok(!TestApp->log->get_warning, 'no warnings yet');

my $our_warning;
$SIG{__WARN__} = sub { $our_warning = shift };

ok($r = request('/warnings/do_warn'), 'request do_warn');
is($r->content, 'Hello, warnings!', 'request worked');
ok(TestApp->log->get_warning, 'got a warning from the log');
ok(!$our_warning, "shouldn't get any warnings via our handler here");
