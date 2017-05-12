use utf8;
use strict;
use warnings;
use Test::More tests => 1247;
use FindBin '$Bin';
BEGIN{unshift @INC,$Bin.'/../lib';use_ok('Config::Column')};
require $Bin.'/base.pl';
our $set;

my $initdatafile = $set->{datafile};
my $datafilename = 'nodelim_order-last1';
my $encoding = 'utf8';
my $order = ['' => name => '/' => subject => '<>' => date => '<>' => value => '<>' => mail => ' ' => url => "\t" => key => ";" => host => "\\" => addr => ' ' => 1 => ''];
my $delimiter = "";
testmulticond($initdatafile,$datafilename,$encoding,$order,$delimiter);
