#!/usr/bin/perl

use strict;

eval "use Acme::VerySign (xform => 'Text::Metaphone')";

if ($@)
{
  eval "use Test::More skip_all => 'no Text::Metaphone'";
}
else
{
  eval "use Test::More tests => 2";
}

sub willow { }

is(wilow()."", "64.94.110.11", "yep, that works");
ok(defined(wilow()->[0]),"returned a listref");
