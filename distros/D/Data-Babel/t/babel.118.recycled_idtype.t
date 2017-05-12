########################################
# recycled idtype bug
# maptables attribute of recycled idtype not reset
########################################
use t::lib;
use t::utilBabel;
use Test::More;
use Data::Babel;
use strict;

my $autodb=new Class::AutoDB(database=>'test',create=>1); 
isa_ok_quietly($autodb,'Class::AutoDB','sanity test - $autodb');
my $idtype=new Data::Babel::IdType(name=>"idtype",sql_type=>'VARCHAR(255)');
my($maptable_1,$maptable_2)=map 
  {new Data::Babel::MapTable (name=>"maptable_$_",idtypes=>[$idtype])} (1..2);

dotest('1st time',$maptable_1);
dotest('2nd time',$maptable_1);
dotest('3rd time - different maptable',$maptable_2);

done_testing();

sub dotest {
  my($label,$maptable)=@_;
  my $babel=new Data::Babel
    (name=>'test',autodb=>$autodb,idtypes=>[$idtype],maptables=>[$maptable]);
  my $ok=isa_ok_quietly($babel,'Data::Babel',"$label sanity test - \$babel");
  $ok&&=cmp_bag_quietly($babel->idtypes,[$idtype],"$label babel idtypes") or return 0;
  my @master_names=map {$_->name} @{$babel->masters};
  $ok&&=cmp_bag_quietly(\@master_names,['idtype_master'],"$label babel masters") or return 0;
  $ok&&=cmp_bag_quietly($babel->maptables,[$maptable],"$label babel maptables") or return 0;
  $ok&&=cmp_bag_quietly($babel->idtypes->[0]->maptables,[$maptable],"$label idtype maptables")
    or return 0;
  report_pass($ok,$label);
}

