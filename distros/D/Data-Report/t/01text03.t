#! perl

use strict;
use warnings;
use Test::More qw(no_plan);

use Data::Report;

my $rep = Data::Report::->create(type => "text");

$rep->set_layout
  ([ { name => "acct", title => "Acct",   width => 6  },
     { name => "desc", title => "Report", width => 40, align => "|" },
     { name => "deb",  title => "Debet",  width => 10, align => "<" },
     { name => "crd",  title => "Credit", width => 10, align => ">" },
   ]);

my $out = "";
$rep->set_output(\$out);
$rep->set_fields([qw(desc crd deb acct)]);
$rep->set_width({ deb => 9, crd => '-1' });
$rep->start;
$rep->add({ acct => "one", desc => "two", deb => "three", crd => "four" });
$rep->finish;
$rep->close;

my $ref; { undef $/; $ref = <DATA>; }
$ref =~ s/[\r\n]/\n/g;

is($out, $ref);

__DATA__
                                  Report     Credit  Debet      Acct
----------------------------------------------------------------------
                                     two       four  three      one
