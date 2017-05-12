#!perl

use strict;
use warnings;
use Test::More tests => 4;
use Attribute::RecordCallers;

package T;

my @w;
BEGIN { $SIG{__WARN__} = sub { push @w, @_ }; }

my $calls = 0;
my $closure = sub :RecordCallers { $calls++ };

$closure->();
::is($calls, 1, 'the closure has been called');

my $k = scalar keys %Attribute::RecordCallers::callers;
::is($k, 0, 'the call to the closure has not been recorded');
::is(scalar @w, 1, "Got only one warning");
::like($w[0], qr/^Ignoring RecordCallers attribute on anonymous subroutine at .*02anon\.t/, "Got a compile-time warning");
