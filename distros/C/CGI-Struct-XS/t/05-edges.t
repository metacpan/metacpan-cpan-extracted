#!/usr/bin/env perl5
use strict;
use warnings;

use Test::More tests => 10;
use Test::Deep;
use CGI::Struct::XS;

my @errs;
my $hval;

@errs = ();
$hval = build_cgi_struct { "x\0" => 2 }, \@errs;
cmp_deeply($hval, { "x\0" => 2 });
is(@errs, 0);

@errs = ();
$hval = build_cgi_struct { "\0" => 2 }, \@errs;
cmp_deeply($hval, { "\0" => 2 });
is(@errs, 0);

@errs = ();
$hval = build_cgi_struct { "a" => "" }, \@errs, { nullsplit => 1 };
cmp_deeply($hval, { "a" => "" });
is(@errs, 0);

@errs = ();
$hval = build_cgi_struct { "a" => "\0" }, \@errs, { nullsplit => 1 };
cmp_deeply($hval, { "a" => ["", ""] });
is(@errs, 0);

@errs = ();
$hval = build_cgi_struct { "a" => "\0\0" }, \@errs, { nullsplit => 1 };
cmp_deeply($hval, { "a" => ["", "", ""] });
is(@errs, 0);

