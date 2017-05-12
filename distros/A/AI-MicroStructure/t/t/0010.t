#!/usr/bin/perl -w

use strict;
use Test::More 'no_plan';#tests =>12;
use File::Find;
use Storable qw(lock_store lock_retrieve);
use Getopt::Long;
use Digest::MD5 qw(md5_hex);
use Data::Dumper;
use Data::Printer;
use AI::MicroStructure;
use AI::MicroStructure::Object;
use AI::MicroStructure::ObjectSet;
use AI::MicroStructure::Context;
use Search::ContextGraph;
use Env qw(PWD);


#print Dumper join "-", soundex(("rock'n'roll", 'rock and roll', 'rocknroll'));

our $meta = AI::MicroStructure->new();
our @t = $meta->structures();

my $TOP = "";
#"/home/santex/wwwstuff/wikileaks.org";
  $TOP = "$PWD/t/canned/docs";

   if($TOP  eq ""){
  $TOP =  $meta->{state}->{path}->{"cwd/structures"} unless(!$meta->{state}->{path}->{"cwd/structures"});

 }




our $curSysDate = `date +"%F"`;
    $curSysDate=~ s/\n//g;

our %opts = (cache_file =>
              sprintf("%s/%s/%s_.cache",
              $PWD,"canned",$curSysDate));

GetOptions (\%opts, "cache_file=s");

our $cache = {};
our @target = split("\/",$opts{cache_file});
ok(my $set = AI::MicroStructure::ObjectSet->new());

eval {
    local $^W = 0;  # because otherwhise doesn't pass errors
#`rm $opts{cache_file}`;
    $cache = lock_retrieve($opts{cache_file});

    $cache = {} unless $cache;

    warn "New cache!\n" unless defined $cache;
};


END{

#  lock_store($set,$opts{cache_file});

  print Dumper [$set];


  }


our $files={};


   my $style = {};
      $style->{explicit}  = 1;
  our $c = AI::MicroStructure::Context->new(@ARGV);
      $c->retrieveIndex($TOP);#"data-hub" structures=0 text=1 json=1
      my $cg = $c->{graph}->{content};

         my @ranked_docs = $cg->simple_search( 'peanuts' );

         # get back both related terms and docs for more power

         my ( $docs, $words ) = $cg->search('dna');

p $docs;
p $words;
         # you can use a document as your query

          ( $docs, $words ) = $cg->find_similar('First Document');

p $docs;
p $words;
         # Or you can query on a combination of things

         ( $docs, $words ) =
           $cg->mixed_search( { docs  => [ 'First Document' ],
                                terms => [ 'snake', 'pony' ]}
                            );


p $docs;
p $words;
         # Print out result set of returned documents
         foreach my $k ( sort { $docs->{$b} <=> $docs->{$a} }
             keys %{ $docs } ) {
             print "Document $k had relevance ", $docs->{$k}, "\n";
         }






sub translate {

  return unless -f;
  (my $rel_name = $File::Find::name) =~ s{.*/}{}xs;

  my $name = md5_hex($rel_name);

  if (/\.(html|htm|txt|json)$/) {
    $files->{html}->{$name}=$rel_name;
      #ok(my $obj = AI::MicroStructure::Object->new($rel_name));
      #ok($set->insert($obj));




  }
  elsif (/\.pdf$/) {
    $files->{pdf}->{$name}=$rel_name;
  }

}
#p $set;



find(\&translate, "$TOP");
p $set;


1;
