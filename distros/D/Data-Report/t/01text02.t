#! perl

use strict;
use warnings;
use Test::More qw(no_plan);

use Data::Report;

my $data = "01text.out";
$data = "t/$data" if -d "t";

my $rep = Data::Report::->create
  (type => "text",
   layout => [ { name => "acct", title => "Acct",   width => 6  },
	       { name => "desc", title => "Report", width => 40, align => "|" },
	       { name => "deb",  title => "Debet",  width => 10, align => "<" },
	       { name => "crd",  title => "Credit", width => 10, align => ">" },
	     ],
  );

$rep->set_output($data);
$rep->start;
$rep->add({ acct => "one", desc => "two", deb => "three", crd => "four" });
$rep->finish;
$rep->close;

undef $/;
my $ref = <DATA>;
open(my $fh, "<", $data);
my $out = <$fh>;
close($fh);
$ref =~ s/[\r\n]/\n/g;
$out =~ s/[\r\n]/\n/g;
is($out, $ref);
unlink($data) if $out eq $ref;

# Same, capturing output in a scalar.
$out = "";
$rep->set_output(\$out);
$rep->start;
$rep->add({ acct => "one", desc => "two", deb => "three", crd => "four" });
$rep->finish;
$rep->close;

$out =~ s/[\r\n]/\n/g;
is($out, $ref);

# Same, capturing output in an array.
my @out;
$rep->set_output(\@out);
$rep->start;
$rep->add({ acct => "one", desc => "two", deb => "three", crd => "four" });
$rep->finish;
$rep->close;

$out = join("", @out);
$out =~ s/[\r\n]/\n/g;
is($out, $ref);

__DATA__
Acct                                      Report  Debet           Credit
------------------------------------------------------------------------
one                                          two  three             four
