use utf8;
use strict;
use warnings;
use Test::More tests => 1247;
use FindBin '$Bin';
BEGIN{unshift @INC,$Bin.'/../lib';use_ok('Config::Column')};
require $Bin.'/base.pl';
our $set;

my $initdatafile = $set->{datafile};
my $datafilename = 'nodelim_order-has1';
my $encoding = 'utf8';
my $order = ['' => 1 => ' ' => name => '/' => subject => '<>' => date => '<>' => value => '<>' => mail => ' ' => url => "\t" => key => ";" => host => "\\" => addr => ''];
my $delimiter = "";
testmulticond($initdatafile,$datafilename,$encoding,$order,$delimiter);
