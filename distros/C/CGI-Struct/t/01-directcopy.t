#!/usr/bin/env perl5
use strict;
use warnings;

use Test::More tests => 5;
use CGI::Struct;

# Test that simple stuff gets properly and directly copied

my %inp = (
	'foo' => 'bar',
	'fooarr' => [qw(foo bar baz)],
	'trail}' => 'trailing brace',
	'trail]' => 'trailing bracket',
);

my @errs;
my $hval = build_cgi_struct \%inp, \@errs;

is(@errs, 0, "No errors");
is($hval->{foo}, $inp{foo}, "foo copied right");
is(@{$hval->{fooarr}}, @{$inp{fooarr}}, "fooarr copied right");
is($hval->{'trail}'}, $inp{'trail}'}, "trail} copied right");
is($hval->{'trail]'}, $inp{'trail]'}, "trail] copied right");
