########################################
# schema mechanics - empty schema, maptable with 0 idtypes
########################################
use t::lib;
use t::utilBabel;
use Test::More;
use Test::Deep;
use Class::AutoDB;
use Data::Babel;
use Data::Babel::Config;
use strict;

# create AutoDB database
my $autodb=new Class::AutoDB(database=>'test',create=>1); 
isa_ok($autodb,'Class::AutoDB','sanity test - $autodb');
cleanup_db($autodb);		# cleanup database from previous test
Data::Babel->autodb($autodb);

# make empty schema
my $babel=new Data::Babel(name=>'test');
my $label='empty schema';
isa_ok($babel,'Data::Babel',$label);
for my $component (qw(idtypes masters maptables)) {
  my $list=$babel->$component;
  report(!@$list,"$label - $component is empty");
}
# make schemas with 1, 2, 3 MapTables
for my $n (1..3) {
  my @idtypes=map {new Data::Babel::IdType name=>"idtype_$_"} 0..$n;
  my @maptables=
    map {my $m=$_;
	 new Data::Babel::MapTable
	   name=>"maptable_$m",idtypes=>join(' ',map {"idtype_$_"} ($m,$m+1))} 0..($n-1);
  my $babel=new Data::Babel(name=>'test',idtypes=>\@idtypes,maptables=>\@maptables);
  my $label="schema with $n maptables";
  isa_ok($babel,'Data::Babel',$label);
  my @idtypes=@{$babel->idtypes};
  is(scalar(@idtypes),$n+1,"$label - correct number of idtypes (".($n+1).')');
  my @masters=@{$babel->masters};
  is(scalar(@masters),$n+1,"$label - correct number of masters (".($n+1).')');
  my @maptables=@{$babel->maptables};
  is(scalar(@maptables),$n,"$label - correct number of maptables ($n)");
  my $ok=1;
  map {idtypes_per_maptable($_,2,$label) or $ok=0} @maptables;
  report_pass($ok,"$label - maptables have correct number of idtypes");
}
# make schemas with 3 MapTables, with 0, 1, 2, 3 IdTypes each
my @idtypes=map {new Data::Babel::IdType name=>"idtype_$_"} 0..2;
my @maptables;
for my $n (0..3) {
  push(@maptables,
       new Data::Babel::MapTable
       name=>"maptable_$n",idtypes=>join(' ',map {"idtype_$_"} 0..($n-1)));
}
my $babel=new Data::Babel(name=>'test',idtypes=>\@idtypes,maptables=>\@maptables);
my $label="schema with 0-3 idtypes per maptable";
isa_ok($babel,'Data::Babel',$label);
my @idtypes=@{$babel->idtypes};
is(scalar(@idtypes),3,"$label - correct number of idtypes (3)");
my @masters=@{$babel->masters};
is(scalar(@masters),3,"$label - correct number of masters (3)");
my @maptables=@{$babel->maptables};
is(scalar(@maptables),4,"$label - correct number of maptables (4)");
my $ok=1;
map {idtypes_per_maptable("maptable_$_",$_,$label) or $ok=0} 0..3;
report_pass($ok,"$label - maptables have correct number of idtypes");

done_testing();
exit;

sub idtypes_per_maptable {
  my($maptable,$n,$label)=@_;
  $maptable=ref $maptable? $maptable: $babel->name2maptable($maptable);
  my @idtypes=@{$maptable->idtypes};
  report_fail(scalar(@idtypes)==$n,"$label ".$maptable->name." - correct number of idtypes ($n)");
}
