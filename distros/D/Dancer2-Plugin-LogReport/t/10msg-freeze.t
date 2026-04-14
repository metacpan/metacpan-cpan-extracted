#!/usr/bin/env perl

use warnings;
use strict;

use Test::More;

use_ok 'Dancer2::Plugin::LogReport::Message';

### CREATE

my $msg = Dancer2::Plugin::LogReport::Message->new(
	_msgid => 'test',
	reason => 'error',
);

ok defined $msg, 'Created message';
isa_ok $msg, 'Dancer2::Plugin::LogReport::Message', '... ';
isa_ok $msg, 'Log::Report::Message', '... ';
is $msg->reason, 'error', '... reason attribute';

### FREEZE

my $freeze = $msg->FREEZE('JSON');
is ref $freeze, 'HASH', 'Freeze message';
is $freeze->{_msgid}, 'test', '... msgid';
is $freeze->{reason}, 'error', '... reason';

ok ! ref $freeze->{$_}, "... non-ref $_"
	for sort keys %$freeze;

### THAW

my $thaw = Dancer2::Plugin::LogReport::Message->THAW(JSON => $freeze);
ok defined $thaw, 'Thaw message';
isa_ok $thaw, 'Dancer2::Plugin::LogReport::Message', '... ';
is $thaw->reason, 'error', '... reason attribute';

done_testing;
