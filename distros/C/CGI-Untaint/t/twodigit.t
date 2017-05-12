#!/usr/bin/perl -w

use strict;
use Test::More;
use CGI;
use CGI::Untaint;

plan tests => 5;

package CGI::Untaint::twodigit;

use base 'CGI::Untaint::integer';

sub _untaint_re { return qr/^\s*([0-9]{2})\s*$/ }

package main;

my $q = CGI->new( { foo => 12, bar => 0, baz => "" } );
my $h = CGI::Untaint->new($q->Vars);

is $h->extract(-as_twodigit => "foo"), 12, "12 extracts";

is $h->extract(-as_twodigit => "bar"), undef, "0 doesn't";
like $h->error, qr/does not untaint/, "With error";

is $h->extract(-as_twodigit => "baz"), undef, "empty string doesn't";
like $h->error, qr/does not untaint/, "With error";

