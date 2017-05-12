#! perl

use strict;
use warnings;
use Test::More qw(no_plan);

use Data::Report;

my $rep = Data::Report::->create(type => "text", stylist => \&my_stylist);

$rep->set_layout
  ([ { name => "acct", title => "Acct",   width => 6, truncate => 1  },
     { name => "desc", title => "Report", width => 40, align => "|" },
     { name => "deb",  title => "Debet",  width => 10, align => "<" },
     { name => "crd",  title => "Credit", width => 10, align => ">" },
   ]);

my $out = "";
$rep->set_output(\$out);
$rep->set_fields([qw(desc crd deb acct)]);
$rep->start;
$rep->add({ acct => "one two", desc => "two", deb => "three", crd => "four", _style => "normal" });
$rep->add({ acct => "one", desc => "two", deb => "three", crd => "four", _style => "normal" });
$rep->add({ acct => "one", desc => "two", deb => "three", crd => "four", _style => "normal" });
$rep->add({ acct => "one", desc => "two", deb => "three", crd => "four", _style => "total"  });
$rep->finish;
$rep->close;

my $ref; { undef $/; $ref = <DATA>; }
$ref =~ s/[\r\n]/\n/g;

is($out, $ref);

sub my_stylist {
    my ($rep, $row, $col) = @_;

    unless ( $col ) {
	return { line_after => 1 } if $row eq "total";
	return;
    }
    return { line_after => 1 } if $col eq "deb";
    return;
}

__DATA__
                                  Report      Credit  Debet       Acct
------------------------------------------------------------------------
                                     two        four  three       one tw
                                                      ----------
                                     two        four  three       one
                                                      ----------
                                     two        four  three       one
                                                      ----------
                                     two        four  three       one
                                                      ----------
------------------------------------------------------------------------
