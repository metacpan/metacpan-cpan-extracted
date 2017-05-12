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
#use AI::MicroStructure::Object;
use AI::MicroStructure::ObjectSet;
#use AI::MicroStructure::ObjectParser;
use Env qw(PWD);


#print Dumper join "-", soundex(("rock'n'roll", 'rock and roll', 'rocknroll'));

our $meta = AI::MicroStructure->new();
our @t = $meta->structures;

my $TOP = "";

#$TOP = "/tmp/test";#$ARGV[0] unless(!@ARGV);
   $TOP = "$PWD/t/canned/docs";

#   if($TOP  eq ""){
 #   $TOP =  $meta->{state}->{path}->{"cwd/structures"} unless(!$meta->{state}->{path}->{"cwd/structures"});

  # }


#mkpath dirname($TOP),1;


our $curSysDate = `date +"%F"`;
    $curSysDate=~ s/\n//g;

our %opts = (cache_file =>
              sprintf("%s/%s/%s_.cache",
              $PWD,"t/canned",$curSysDate));

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

  lock_store($set,$opts{cache_file});

  print Dumper [$set->size,$set->members];


  }


our $files={};


find(\&translate, "$TOP");
#p $set;
sub translate {

  return unless -f;
  (my $rel_name = $File::Find::name) =~ s{.*/}{}xs;

  my $name = md5_hex($rel_name);

  if (/\.(html|htm)$/) {
    $files->{html}->{$name}=$rel_name;
  }
  elsif (/\.pdf$/) {
    $files->{pdf}->{$name}=$rel_name;
  }elsif (/\.ltx$/) {
    $files->{latex}->{$name}=$rel_name;
  }elsif (/\.(flv|mpg4|ogg)$/) {
    $files->{media}->{$name}=$rel_name;
  }elsif (/\.json$/) {
    $files->{text}->{$name}=$rel_name;
  }


}
p $files;


__DATA__
our $c = AI::MicroStructure::Context->new(@ARGV);
    $c->retrieveIndex($PWD."/t/docs"); #"/home/santex/data-hub/data-hub" structures=0 text=1 json=1



   my $style = {};
      $style->{explicit}  = 1;
ok($c->simpleMixedSearch($style,$_)) && ok($c->play($style,$_))   for
 qw(atom antimatter planet);



ok(print Dumper $c->intersect($style,$_)) for
 qw(atom antimatter planet);

ok(print Dumper $c->similar($style,$_)) for
 qw(atom antimatter planet);

#p @out;

1;

package main;

$|++;
use strict;

use File::Find;
use Data::Dumper;
use Storable qw(lock_store lock_retrieve);
use Getopt::Long;
our $curSysDate = `date +"%F"`;
    $curSysDate=~ s/\n//g;

our %opts = (cache_file =>
              sprintf("/tmp/%s.cache",
              $curSysDate));

GetOptions (\%opts, "cache_file=s");

our $cache = {};
our @target = split("\/",$opts{cache_file});
my $set = AI::MicroStructure::ObjectSet->new();

eval {
    local $^W = 0;  # because otherwhise doesn't pass errors
#`rm $opts{cache_file}`;
    $cache = lock_retrieve($opts{cache_file});

    $cache = {} unless $cache;

    warn "New cache!\n" unless defined $cache;
};


END{

  lock_store($cache,$opts{cache_file});

  print Dumper [$set->size,$set->members];


  }




find(\&translate, "$TOP/./");

sub translate {
  return unless -f;
  (my $rel_name = $File::Find::name) =~ s{.*/}{}xs;

  $set->insert(AI::MicroStructure::Object->new($rel_name));

}


