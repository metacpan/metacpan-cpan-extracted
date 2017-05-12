#!/usr/bin/perl -w

our $t;
BEGIN {
  use Test::Inter;
  $t = new Test::Inter 'objects,method/func';
}

$testdir = '';
$testdir = $t->testdir();

BEGIN { $t->use_ok('Date::Manip::Date','feature'); }
BEGIN { $t->use_ok('Archive::Zip','feature'); }

$t->skip_all('Date::Manip 6.xx required','Date::Manip::Date');
$t->skip_all('Archive::Zip required','Archive::Zip');

use Data::PrettyPrintObjects;

PPO_Options('objs' => { 'Date::Manip::Date'     => { 'print'  => 'method',
                                                     'func'   => 'value',
                                                     'type'   => 'scalar' },
                        'Archive::Zip::Archive' => { 'print'  => 'method', 
                                                     'func'   => 'memberNames', 
                                                     'type'   => 'list' },

                        'PPOtest01'             => { 'print'  => 'method', 
                                                     'func'   => 'members', 
                                                     'type'   => 'list' },
                        'PPOtest02'             => { 'print'  => 'method', 
                                                     'func'   => 'members', 
                                                     'type'   => 'list' },
                        'PPOtest03'             => { 'print'  => 'method', 
                                                     'func'   => 'members', 
                                                     'type'   => 'list' },

                        'PPOtest04'             => { 'print'  => 'method', 
                                                     'func'   => 'count', 
                                                     'type'   => 'scalar' },
                        'PPOtest05'             => { 'print'  => 'method', 
                                                     'func'   => 'count', 
                                                     'type'   => 'scalar' },

                        'PPOtest06'             => { 'print'  => 'method',
                                                     'func'   => 'val',
                                                     'args'   => ['c06'],
                                                     'type'   => 'scalar' },
                        'PPOtest07'             => { 'print'  => 'method',
                                                     'func'   => 'vals',
                                                     'args'   => ['d07','c07','b07'],
                                                     'type'   => 'list' },
 
                        'PPOtest08'             => { 'print'  => 'data' },

                        'PPOtest09'             => { 'print'  => 'method',
                                                     'func'   => 'data',
                                                     'type'   => 'hash' },
                        'PPOtest10'             => { 'print'  => 'method',
                                                     'func'   => 'data',
                                                     'type'   => 'hash' },

                        'PPOtest11'             => { 'print'  => 'func',
                                                     'func'   => 'vals11',
                                                     'args'   => ['$OBJ','d11','c11','b11'],
                                                     'type'   => 'list' },
                        'PPOtest12'             => { 'print'  => 'func',
                                                     'func'   => 'vals12',
                                                     'args'   => ['$OBJ','d12','c12','b12'],
                                                     'type'   => 'list' },
 
                        'PPOtest13'             => { 'print'  => 'method', 
                                                     'func'   => 'members', 
                                                     'ref'    => 1,
                                                     'type'   => 'list' },
                      });

$date = new Date::Manip::Date;
$date->parse('2010-01-01 00:00:00');
$zip  = new Archive::Zip "$testdir/ppo.zip";

sub test {
  my($var) = @_;
  $out = PPO($var);

  my $i = 0;
  while ($out =~ /(0x[0-9a-f]{2,})/) {
    my $ref = $1;
    my $rep = '1x' . sprintf('%06x',$i++);
    $out    =~ s/$ref/$rep/g;
  }
  return $out;
}

@tests = ();
@exp   = ();

push @tests, [ { 'date' => $date, 'zip' => $zip } ];
push @exp,   [
"{
  date => 2010010100:00:00,
  zip  => [
    a.txt,
    b.txt
  ]
}
"];

$foo01 = new PPOtest01;
$foo02 = new PPOtest02;
$foo03 = new PPOtest03;

push @tests, [ { 'foo01' => $foo01,
                 'foo02' => $foo02,
                 'foo03' => $foo03,
               } ];
push @exp,   [
"{
  foo01 => *** NO FUNCTION ***,
  foo02 => [
    a02,
    b02
  ],
  foo03 => [
    a03,
    b03
  ]
}
"];

$foo04 = new PPOtest04;
$foo05 = new PPOtest05;

push @tests, [ { 'foo04' => $foo04,
                 'foo05' => $foo05,
               } ];
push @exp,   [
"{
  foo04 => *** NO FUNCTION ***,
  foo05 => 2
}
"];

$foo06 = new PPOtest06;
$foo07 = new PPOtest07;

push @tests, [ { 'foo06' => $foo06,
                 'foo07' => $foo07,
               } ];
push @exp,   [
"{
  foo06 => ape,
  foo07 => [
    pea,
    ape,
    bar
  ]
}
"];

$foo08 = new PPOtest08;

push @tests, [ { 'foo08' => $foo08,
               } ];
push @exp,   [
"{
  foo08 => {
    a08 => foo,
    b08 => bar
  }
}
"];

$foo09 = new PPOtest09;
$foo10 = new PPOtest10;

push @tests, [ { 'foo09' => $foo09,
                 'foo10' => $foo10,
               } ];
push @exp,   [
"{
  foo09 => {
    a09 => foo,
    b09 => bar
  },
  foo10 => {
    a10 => foo,
    b10 => bar
  }
}
"];

$foo11 = new PPOtest11;
$foo12 = new PPOtest12;

sub vals11 {
  my ($obj,@keys) = @_;

   my @ret;
   foreach my $key (@keys) {
      push(@ret,$$obj{$key});
   }
   return @ret;
}

push @tests, [ { 'foo11' => $foo11,
                 'foo12' => $foo12,
               } ];
push @exp,   [
"{
  foo11 => [
    pea,
    ape,
    bar
  ],
  foo12 => [
    pea,
    ape,
    bar
  ]
}
"];

$foo13 = new PPOtest13;

push @tests, [ { 'foo13' => $foo13,
               } ];
push @exp,   [
"{
  foo13 => PPOtest13=HASH(1x000000) [
    a13,
    b13
  ]
}
"];

$t->tests(func     => \&test,
          tests    => \@tests,
          expected => \@exp);
$t->done_testing();

package PPOtest01;

sub new {
   my $self = { 'a01' => 'foo',
                'b01' => 'bar' };
   bless $self;
   return $self;
}

package PPOtest02;

sub new {
   my $self = { 'a02' => 'foo',
                'b02' => 'bar' };
   bless $self;
   return $self;
}

sub members {
   my($self) = @_;

   return sort keys %$self;
}

package PPOtest03;

sub new {
   my $self = { 'a03' => 'foo',
                'b03' => 'bar' };
   bless $self;
   return $self;
}

sub members {
   my($self) = @_;
   my @ele = sort keys %$self;

   return \@ele;
}

package PPOtest04;

sub new {
   my $self = { 'a04' => 'foo',
                'b04' => 'bar' };
   bless $self;
   return $self;
}

package PPOtest05;

sub new {
   my $self = { 'a05' => 'foo',
                'b05' => 'bar' };
   bless $self;
   return $self;
}

sub count {
   my($self) = @_;

   return scalar(keys %$self);
}

package PPOtest06;

sub new {
   my $self = { 'a06' => 'foo',
                'b06' => 'bar',
                'c06' => 'ape',
                'd06' => 'pea',
                'e06' => 'jar',
                'f06' => 'pup' };
   bless $self;
   return $self;
}

sub val {
   my($self,$key) = @_;

   return $$self{$key};
}

package PPOtest07;

sub new {
   my $self = { 'a07' => 'foo',
                'b07' => 'bar',
                'c07' => 'ape',
                'd07' => 'pea',
                'e07' => 'jar',
                'f07' => 'pup' };
   bless $self;
   return $self;
}

sub vals {
   my($self,@keys) = @_;

   my @ret;
   foreach my $key (@keys) {
      push(@ret,$$self{$key});
   }
   return @ret;
}

package PPOtest08;

sub new {
   my $self = { 'a08' => 'foo',
                'b08' => 'bar' };
   bless $self;
   return $self;
}

package PPOtest09;

sub new {
   my $self = { 'a09' => 'foo',
                'b09' => 'bar' };
   bless $self;
   return $self;
}

sub data {
   my($self) = @_;

   my %ret;
   foreach my $key (keys %$self) {
      my $val = $$self{$key};
      $ret{$key} = $val;
   }
   return %ret;
}

package PPOtest10;

sub new {
   my $self = { 'a10' => 'foo',
                'b10' => 'bar' };
   bless $self;
   return $self;
}

sub data {
   my($self) = @_;

   my %ret;
   foreach my $key (keys %$self) {
      my $val = $$self{$key};
      $ret{$key} = $val;
   }
   return %ret;
}

package PPOtest11;

sub new {
   my $self = { 'a11' => 'foo',
                'b11' => 'bar',
                'c11' => 'ape',
                'd11' => 'pea',
                'e11' => 'jar',
                'f11' => 'pup' };
   bless $self;
   return $self;
}

package PPOtest12;

sub new {
   my $self = { 'a12' => 'foo',
                'b12' => 'bar',
                'c12' => 'ape',
                'd12' => 'pea',
                'e12' => 'jar',
                'f12' => 'pup' };
   bless $self;
   return $self;
}

sub vals12 {
  my ($self,@keys) = @_;

   my @ret;
   foreach my $key (@keys) {
      push(@ret,$$self{$key});
   }
   return @ret;
}

package PPOtest13;

sub new {
   my $self = { 'a13' => 'foo',
                'b13' => 'bar' };
   bless $self;
   return $self;
}

sub members {
   my($self) = @_;

   return sort keys %$self;
}

#Local Variables:
#mode: cperl
#indent-tabs-mode: nil
#cperl-indent-level: 3
#cperl-continued-statement-offset: 2
#cperl-continued-brace-offset: 0
#cperl-brace-offset: 0
#cperl-brace-imaginary-offset: 0
#cperl-label-offset: -2
#End:

