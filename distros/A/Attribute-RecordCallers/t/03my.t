#!perl

BEGIN {
    if ($] < 5.018) {
        print "1..0 # SKIP: needs 5.18 or later\n";
        exit 0;
    }
}

use 5.18.0;
use warnings;
use Test::More tests => 4;
use feature 'lexical_subs';
no warnings "experimental::lexical_subs";
use Attribute::RecordCallers;

my @w;
BEGIN { $SIG{__WARN__} = sub { push @w, @_ }; }

my $calls = 0;
my sub foo :RecordCallers { $calls++ }

foo();
is($calls, 1, 'the lexical sub has been called');

my $k = scalar keys %Attribute::RecordCallers::callers;
is($k, 0, 'the call to the lexical sub has not been recorded');
::is(scalar @w, 1, "Got only one warning");
::like($w[0], qr/^Ignoring RecordCallers attribute on anonymous subroutine at .*03my\.t/, "Got a compile-time warning");
