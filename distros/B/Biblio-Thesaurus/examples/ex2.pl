#!/usr/bin/perl -w -s
#use lib qw{ .. ../.. ../../.. };
use Biblio::Thesaurus;
use Data::Dumper;

our ($t);

unless($t){ die ("usage: ex2.pl t=1..7\n");}

$thesaurus = thesaurusLoad('animal.the');

if($t==1){
  print Dumper($thesaurus->depth_first("animal",1,"NT","USE","HAS"));
  print Dumper($thesaurus->depth_first("_top_",1,"NT","USE","HAS"));
  print Dumper($thesaurus->depth_first("_top_",2,"NT","USE","HAS"));
  print Dumper($thesaurus->depth_first("_top_",3,"NT","USE","HAS"));}
elsif($t ==2){
  print $thesaurus->downtr(
     {-default  => sub { "\n$rel \t".join("\n\t",@terms)},
      -eachTerm => sub { "\n______________($term)______$_"},
      -end      => sub { "Thesaurus :\n $_ \nFIM\n"}
     });
}
elsif($t ==3){
  print $thesaurus->downtr(
     {-default  => sub { "\n$rel \t".join("\n\t",@terms)},
      -eachTerm => sub { "\nPT\tterm$_\n"},
      -end      => sub { "Thesaurus :\n $_ \nFIM\n"},
      -order    => ["EN","FR","BT"],
     }, "gato", "animal","sapo");
}
elsif($t ==4){
  print $thesaurus->downtr(
     {-eachTerm => sub { "\n\n$term$_"} });
}
elsif($t ==5){
  print $thesaurus->toTex();
}
elsif($t ==6){
  print $thesaurus->toTex({EN=>["\\\\\\emph{Inglês} -- ",""]},{FR => sub{""}});
}
elsif($t ==7){
  print $thesaurus->toXml();
}
