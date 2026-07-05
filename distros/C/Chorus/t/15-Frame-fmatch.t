#!perl -T

use Test::More tests => 3;

BEGIN {
}

use strict;
use Chorus::Frame;

diag( "Testing Chorus::Frame::fmatch $Chorus::Frame::VERSION, Perl $], $^X" );


my $f1 = Chorus::Frame->new(
  whois => sub { print "frame " . $SELF->ID . "\n" },

);

my $f2 = Chorus::Frame->new(
  _ISA  => $f1,
  ID    => 'F2',
  flag  => 'y',
  score => 6,
);

my $f3 = Chorus::Frame->new(
  _ISA  => $f1,
  ID    => 'F3',
  flag  => 'y',
  score => 3,
);

my $f4 = Chorus::Frame->new(
  _ISA  => $f1,
  ID    => 'F4',
  flag  => 'y',
  flag2 => 'y',
  score => 8,
);
          
my $res;

$res = join('-', sort map { $_->ID } grep { $_->score > 5 } fmatch(slot => 'flag'));        
is($res,'F2-F4','Test 1');

$res = join('-', sort map { $_->ID } grep { $_->score < 7 } fmatch(slot => 'flag', from => [$f3, $f4]));        
is($res,'F3','Test 2');

$res = join('-', sort map { $_->ID } grep { $_->score > 7 } fmatch(slot => ['flag', 'flag2']));        
is($res,'F4','Test 3');

done_testing();
