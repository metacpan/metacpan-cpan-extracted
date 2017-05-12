########################################
# regression test for specifying non-standard header location
########################################
use t::lib;
use t::utilBabel;
use Test::More;
use Test::Deep;
use File::Spec;
use Class::AutoDB;
use Data::Babel;
use Data::Babel::Config;
use strict;

my $file=File::Spec->catfile(scriptpath,'headloc.maptable.ini');
my $header=File::Spec->catfile(scriptpath,'headloc_header.tt');
my $maptables=new Data::Babel::Config
  (file=>$file,tt=>{maptable_header=>$header})->objects('MapTable');
my @maptables=sort_objects($maptables);

my @classes=map {ref $_} (@maptables);
cmp_deeply(\@classes,[('Data::Babel::MapTable')x3],'classes');
my @names= map {$_->name} @maptables;
cmp_deeply(\@names,[qw(headloc_001 headloc_002 headloc_003)],'names');

my($ok,$details);
for my $i (0..2) {
  my $maptable=$maptables[$i];
  my $actual=$maptable->idtypes; # still in string form
  my $correct=join(' ','type_'.sprintf("%03d",$i+1),'type_'.sprintf("%03d",$i+2));
  ($ok,$details)=cmp_quietly($actual,$correct,"idtypes object $i",,,$details) or last;
}
report_pass($ok,'idtypes');

done_testing();
