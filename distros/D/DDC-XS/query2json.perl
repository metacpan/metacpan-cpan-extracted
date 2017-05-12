#!/usr/bin/perl -w

use lib qw(./blib/lib ./blib/arch);
use DDC::XS;
use JSON;

our $qc = DDC::XS::QueryCompiler->new();

my $qstr = join(' ', @ARGV);
$qc->CleanParser();
die ("$0: could not parse query \`$qstr'") if (!$qc->ParseQuery($qstr));

my $jstr = $qc->QueryToJson();
my ($qobj);
eval {
  $qobj = from_json($jstr);
};
die ("$0: could not parse json string \`$jstr': $@") if ($@ || !$qobj);

print to_json($qobj, {pretty=>1,canonical=>1});
