# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

use strict;
use warnings;

use Test::More qw(no_plan); 

use DataFax::StudyDB; 

my $self  = bless {}, "main"; 
my $class = "DataFax::StudyDB";
my $s  = bless {}, $class;
my $obj = $s->new; 

isa_ok($obj, $class);

my @md = (@DataFax::StudyDB::EXPORT_OK);
foreach my $m (@md) {
    ok($obj->can($m), "$class->can('$m')");
}

# 10/18/2005 readDFstudies($ifn, $ar)
$obj->debug_level(2);
my $ifn = '/dlb/datafax/src_data/DFstudies.db';
my $ar = {source_dir=>'/dlb/datafax/src_data',
   datafax_host=>'df-beltane',datafax_dir=>'/opt/datafax',
   datafax_usr=>'datafax', datafax_pwd=>'hamcheese',
   real_time => 1,
   };
my ($c, $d) = $obj->readDFstudies('',$ar);

$obj->disp_param($c);
$obj->disp_param($d);

1;

