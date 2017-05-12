#!perl

use strict;
use warnings;
use Test::More tests => 9;
use Attribute::RecordCallers;

sub call_me_with_one_arg ($) : RecordCallers {
    our $arg = shift;
}

TODO: {
    local $TODO;
    $TODO = 'Prototypes are not passed to BEGIN attributes before 5.16' if $] < 5.016;
    is(prototype "call_me_with_one_arg", '$', 'Wrapper symbol has the correct prototype');
    is(prototype \&call_me_with_one_arg, '$', 'Wrapper coderef has the correct prototype');
}

call_me_with_one_arg "foo";

is(our $arg, "foo", "got the argument");
ok(exists $Attribute::RecordCallers::callers{'main::call_me_with_one_arg'}, 'seen a caller');
is(scalar @{$Attribute::RecordCallers::callers{'main::call_me_with_one_arg'}}, 1, 'seen exactly 1 call');
for my $c (@{$Attribute::RecordCallers::callers{'main::call_me_with_one_arg'}}) {
    is($c->[0], 'main', 'caller package is main');
    like($c->[1], qr/05proto\.t$/, 'file name is correct');
    is($c->[2], 19, 'line number is correct');
    ok($c->[3] - time < 10, 'time is correct');
}
