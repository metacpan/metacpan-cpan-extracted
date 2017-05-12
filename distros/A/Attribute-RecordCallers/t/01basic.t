#!perl

use strict;
use warnings;
use Test::More tests => 36;

BEGIN { use_ok 'Attribute::RecordCallers' }

my $manual_counter = 0;

sub call_me_maybe : RecordCallers {
    $manual_counter++;
}

ok(!exists $Attribute::RecordCallers::callers{'main::call_me_maybe'}, 'no caller yet');

call_me_maybe(); my $expected_line = 17;
call_me_maybe();

is($manual_counter, 2, 'called twice, manual check');
ok(exists $Attribute::RecordCallers::callers{'main::call_me_maybe'}, 'seen a caller');
is(scalar @{$Attribute::RecordCallers::callers{'main::call_me_maybe'}}, 2, 'seen exactly 2 calls');
for my $c (@{$Attribute::RecordCallers::callers{'main::call_me_maybe'}}) {
    is($c->[0], 'main', 'caller package is main');
    like($c->[1], qr/01basic\.t$/, 'file name is correct');
    is($c->[2], $expected_line, 'line number is correct');
    ok($c->[3] - time < 10, 'time is correct');
    $expected_line++;
}

Attribute::RecordCallers->clear;
ok(!exists $Attribute::RecordCallers::callers{'main::call_me_maybe'}, 'caller list cleared');

package Foo;

::call_me_maybe(); $expected_line = 36;

::is($manual_counter, 3, 'called 3 times, manual check');
::is(scalar @{$Attribute::RecordCallers::callers{'main::call_me_maybe'}}, 1, 'seen exactly 1 call');
for my $c (@{$Attribute::RecordCallers::callers{'main::call_me_maybe'}}) {
    ::is($c->[0], 'Foo', 'caller package is Foo');
    ::like($c->[1], qr/01basic\.t$/, 'file name is correct');
    ::is($c->[2], $expected_line, 'line number is correct');
    ::ok($c->[3] - time < 10, 'time is correct');
}

Attribute::RecordCallers->clear;
::is(scalar keys %Attribute::RecordCallers::callers, 0, 'caller list cleared');

package Bar;

*call_me_maybe = \&::call_me_maybe;

call_me_maybe(); $expected_line = 54;

::is($manual_counter, 4, 'called 4 times, manual check');
::is(scalar @{$Attribute::RecordCallers::callers{'main::call_me_maybe'}}, 1, 'seen exactly 1 call in main::');
::is(scalar @{$Attribute::RecordCallers::callers{'Bar::call_me_maybe'} // []}, 0, 'seen exactly 0 call in Bar::');
for my $c (@{$Attribute::RecordCallers::callers{'main::call_me_maybe'}}) {
    ::is($c->[0], 'Bar', 'caller package is Bar');
    ::like($c->[1], qr/01basic\.t$/, 'file name is correct');
    ::is($c->[2], $expected_line, 'line number is correct');
    ::ok($c->[3] - time < 10, 'time is correct');
}

Attribute::RecordCallers->clear;
::is(scalar keys %Attribute::RecordCallers::callers, 0, 'caller list cleared');

package Xyz;

BEGIN { *call_me_maybe = \&::call_me_maybe; }

call_me_maybe(); $expected_line = 73;

::is($manual_counter, 5, 'called 5 times, manual check');
::is(scalar @{$Attribute::RecordCallers::callers{'main::call_me_maybe'}}, 1, 'seen exactly 1 call in main::');
::is(scalar @{$Attribute::RecordCallers::callers{'Xyz::call_me_maybe'} // []}, 0, 'seen exactly 0 call in Xyz::');
for my $c (@{$Attribute::RecordCallers::callers{'main::call_me_maybe'}}) {
    ::is($c->[0], 'Xyz', 'caller package is Xyz');
    ::like($c->[1], qr/01basic\.t$/, 'file name is correct');
    ::is($c->[2], $expected_line, 'line number is correct');
    ::ok($c->[3] - time < 10, 'time is correct');
}
