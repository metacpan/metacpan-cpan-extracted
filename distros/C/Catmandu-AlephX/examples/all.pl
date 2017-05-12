#!/usr/bin/env perl
use FindBin;
use lib "$FindBin::Bin/../lib";
use Catmandu::Sane;
use Catmandu::Store::AlephX;
use Data::Dumper;
use open qw(:std :utf8);
use Time::HiRes qw(gettimeofday tv_interval);

sub verbose {
  state $count = 0;
  state $start = [gettimeofday];
  ++$count;
  my $speed = $count / tv_interval($start);
  say STDERR sprintf " (doc %d %f)" ,$count,$speed if ($count % 10 == 0);
}

my $bag = Catmandu::Store::AlephX->new(url => "http://aleph.ugent.be/X",username=> "test",password => "test")->bag();

$bag->tap(\&verbose)->each(sub{
  print Dumper(shift);
});
