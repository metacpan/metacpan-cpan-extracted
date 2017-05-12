#! perl

use strict;
use warnings;
use Test::More qw(no_plan);

use Data::Report;

my $rep = Data::Report::->create
  (layout => [ { name => "acct", title => "Acct",   width => 6  },
	       { name => "desc", title => "Report", width => 40, align => "|" },
	       { name => "deb",  title => "Debet",  width => 10, align => "<" },
	       { name => "crd",  title => "Credit", width => 10, align => ">" },
	     ],
  );
isa_ok($rep, 'Data::Report::Plugin::Text');

my $data = "";
$rep->set_output(\$data);
$rep->start;
$rep->finish;
$rep->close;

is($data, "", "contents");

