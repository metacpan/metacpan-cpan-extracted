#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use_ok 'CatalystX::Restarter::GTK';
use_ok 'Catalyst', '5.80032';
use_ok 'MooseX::Types::Moose';
use_ok 'Try::Tiny';
use_ok 'POSIX';
use_ok 'IPC::Semaphore';
use_ok 'IPC::SysV';
use_ok 'Object::Destroyer';
use_ok 'Carp';
use_ok 'Socket';
use_ok 'IO::Handle';
use_ok 'AnyEvent::Socket';
use_ok 'Catalyst::Restarter';
use_ok 'Gtk2';
use_ok 'Glib';

ok($^O ne 'MSWin32', 'Linux required');

use Catalyst::Restarter;

can_ok('Catalyst::Restarter', '_handle_events');

ok(Catalyst::Restarter->meta->has_attribute('_watcher'));

use Socket               qw(AF_UNIX SOCK_STREAM);

ok(socketpair(my $parent, my $child, AF_UNIX, SOCK_STREAM, 0));

my $restarter = Catalyst::Restarter->new(start_sub => sub {}, argv => []);
can_ok($restarter->_watcher, 'new_events');

$restarter = undef;

done_testing;

