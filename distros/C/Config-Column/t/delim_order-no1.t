use utf8;
use strict;
use warnings;
use Test::More tests => 1247;
use FindBin '$Bin';
BEGIN{unshift @INC,$Bin.'/../lib';use_ok('Config::Column')};
require $Bin.'/base.pl';
our $set;

my $initdatafile = $set->{datafile};
my $datafilename = 'delim_order-no1';
my $encoding = 'utf8';
my $order = [qw(name subject date value mail url key host addr)];
my $delimiter = "\t";
testmulticond($initdatafile,$datafilename,$encoding,$order,$delimiter);
