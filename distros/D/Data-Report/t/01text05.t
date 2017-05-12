#! perl

use strict;
use warnings;
use Test::More qw(no_plan);

use Data::Report;

my $rep = Data::Report::->create(type => "text");

$rep->set_layout
  ([ { name => "one", title => "One",   width => 10, },
     { name => "two", title => "Two",   width => 11, },
     { name => "thr", title => "Three", width => 12, },
     { name => "fou", title => "Four",  width => 13, },
     { name => "fiv", title => "Five",  width => 14, },
   ]);

my $ref; { undef $/; $ref = <DATA>; }
$ref =~ s/[\r\n]/\n/g;
my $out = "";

my $dd = "The quick brown fox jumps over the lazy dog.";
$dd = "$dd $dd $dd";

$rep->set_output(\$out);
$rep->start;
$rep->add({ one => $dd, two => $dd, thr => $dd, fou => $dd, fiv => $dd });
$rep->finish;

is($out, $ref);

__DATA__
One         Two          Three         Four           Five
--------------------------------------------------------------------
The quick   The quick    The quick     The quick      The quick
brown fox   brown fox    brown fox     brown fox      brown fox
jumps over  jumps over   jumps over    jumps over     jumps over the
the lazy    the lazy     the lazy      the lazy dog.  lazy dog. The
dog. The    dog. The     dog. The      The quick      quick brown
quick       quick brown  quick brown   brown fox      fox jumps over
brown fox   fox jumps    fox jumps     jumps over     the lazy dog.
jumps over  over the     over the      the lazy dog.  The quick
the lazy    lazy dog.    lazy dog.     The quick      brown fox
dog. The    The quick    The quick     brown fox      jumps over the
quick       brown fox    brown fox     jumps over     lazy dog.
brown fox   jumps over   jumps over    the lazy dog.
jumps over  the lazy     the lazy
the lazy    dog.         dog.
dog.
