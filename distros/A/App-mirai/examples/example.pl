#!/usr/bin/env perl
use strict;
use warnings;
use Future;
my $f = Future->new->set_label('one');
my @pending = map Future->new->set_label($_), qw(two three four);
Future->wait_any(
	Future->needs_all(@pending)->set_label('needs_all'),
	Future->needs_any(@pending)->set_label('needs_any'),
)->set_label('wait_any');
sleep 3;
$f->fail('failed!');
$pending[1]->done;
sleep 2;
$pending[0]->cancel;
sleep 5;

