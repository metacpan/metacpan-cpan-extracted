#!/usr/bin/perl

use warnings;
use strict;
use Test::Inter;
$::ti = new Test::Inter $0;
require "tests.pl";

$ENV{'TZ'} = 'America/Chicago';

our %obj = ();
our %dmb = ();
our %dmt = ();

sub test {
   my($label,$op,@args)=@_;
   my $new;

   if ($op eq 'new') {
      my($type,@a) = @args;
      if (@a  &&  exists $obj{$a[0]}) {
         my $o = $obj{$a[0]};
         shift(@a);
         unshift(@a,$o);
      }
      if ($type eq 'Base') {
         $new = new Date::Manip::Base @a;
      } elsif ($type eq 'TZ') {
         $new = new Date::Manip::TZ @a;
      } elsif ($type eq 'Date') {
         $new = new Date::Manip::Date @a;
      } elsif ($type eq 'Delta') {
         $new = new Date::Manip::Delta @a;
      } elsif ($type eq 'Recur') {
         $new = new Date::Manip::Recur @a;
      }

   } elsif ($op eq 'new_config') {
      my $o = $obj{$args[0]};
      shift(@args);
      $new  = $o->new_config(@args);

   } elsif ($op eq 'base') {
      my $o = $obj{$args[0]};
      shift(@args);
      $new  = $o->base(@args);

   } elsif ($op eq 'tz') {
      my $o = $obj{$args[0]};
      shift(@args);
      $new  = $o->tz(@args);

   } elsif ($op eq 'config') {
      my $o = $obj{$args[0]};
      shift(@args);
      $o->config(@args);
      return (0);

   } elsif ($op eq 'get_config') {
      my $o = $obj{$args[0]};
      shift(@args);
      my @ret = $o->get_config(@args);
      if (@ret > 3) {
         @ret = @ret[0..2];
      }
      return @ret;

   } elsif (exists $obj{$op}) {
      my $o = $obj{$op};
      $new = $o->new(@args);
   }

   if (! defined $new) {
      return (undef);
   }

   my($dmb,$dmt);
   if (ref($new) eq 'Date::Manip::Base') {
      $dmb = $new;
      $dmt = '---';
   } elsif (ref($new) eq 'Date::Manip::TZ') {
      $dmb = $new->base();
      $dmt = $new;
   } else {
      $dmb = $new->base();
      $dmt = $new->tz();
   }

   $obj{$label} = $new;
   my @ret;
   @ret = (ref($new));

   if (! exists $dmb{$dmb}) {
      $dmb{$dmb} = $label;
   }
   push(@ret,$dmb{$dmb});

   if ($dmt eq '---') {
      push(@ret,$dmt);
   } else {
      if (! exists $dmt{$dmt}) {
         $dmt{$dmt} = $label;
      }
      push(@ret,$dmt{$dmt});
   }

   return @ret;
}

my $tests="

### new CLASS

o0001  new  Base
   =>
   Date::Manip::Base
   o0001
   ---

o0002  new  TZ
   =>
   Date::Manip::TZ
   o0002
   o0002

o0003  new  Date
   =>
   Date::Manip::Date
   o0003
   o0003

o0004  new  Delta
   =>
   Date::Manip::Delta
   o0004
   o0004

o0005  new  Recur
   =>
   Date::Manip::Recur
   o0005
   o0005

### OBJ->new

o0006  o0001
   =>
   Date::Manip::Base
   o0006
   ---

o0007  o0002
   =>
   Date::Manip::TZ
   o0002
   o0007

o0008  o0003
   =>
   Date::Manip::Date
   o0003
   o0003

o0009  o0004
   =>
   Date::Manip::Delta
   o0004
   o0004

o0010  o0005
   =>
   Date::Manip::Recur
   o0005
   o0005

### new CLASS OBJ

o0011  new  Base  o0001
   =>
   Date::Manip::Base
   o0011
   ---

o0012  new  Date o0001
   =>
   Date::Manip::Date
   o0001
   o0012

o0013  new  Date o0002
   =>
   Date::Manip::Date
   o0002
   o0002

### new_config

o0014  new_config  o0001
   =>
   Date::Manip::Base
   o0014
   ---

o0015  new_config  o0002
   =>
   Date::Manip::TZ
   o0015
   o0015

o0016  new_config  o0003
   =>
   Date::Manip::Date
   o0016
   o0016

o0017  new_config  o0004
   =>
   Date::Manip::Delta
   o0017
   o0017

o0018  new_config  o0005
   =>
   Date::Manip::Recur
   o0018
   o0018

o0019  new_config  o0003 now
   =>
   Date::Manip::Date
   o0019
   o0019

o0020  new_config  o0003 [ forcedate now,America/New_York ]
   =>
   Date::Manip::Date
   o0020
   o0020

o0021  new_config  o0003 now [ forcedate now,America/New_York ]
   =>
   Date::Manip::Date
   o0021
   o0021

### base/tz

o0022  base o0001
   =>
   __undef__

o0023  base o0002
   =>
   Date::Manip::Base
   o0002
   ---

o0024  base o0003
   =>
   Date::Manip::Base
   o0003
   ---

o0022  tz o0001
   =>
   __undef__

o0023  tz o0002
   =>
   __undef__

o0024  tz o0003
   =>
   Date::Manip::TZ
   o0003
   o0003

### misc

o0100  new  Date  now noiso8601
   =>
   Date::Manip::Date
   o0100
   o0100

o0101  new  Date  now [ forcedate now,America/New_York ]
   =>
   Date::Manip::Date
   o0101
   o0101

o0102  new  Date  now noiso8601 [ forcedate now,America/New_York ]
   =>
   Date::Manip::Date
   o0102
   o0102

o0103  new  Date  o0102 now noiso8601
   =>
   Date::Manip::Date
   o0102
   o0102

o0104  new  Date o0102  now [ forcedate now,America/New_York ]
   =>
   Date::Manip::Date
   o0104
   o0104

o0105  new  Date o0102  now noiso8601 [ forcedate now,America/New_York ]
   =>
   Date::Manip::Date
   o0105
   o0105

o0106  new  TZ  [ forcedate now,America/New_York ]
   =>
   Date::Manip::TZ
   o0106
   o0106

o0107  new  TZ o0102  [ forcedate now,America/New_York ]
   =>
   Date::Manip::TZ
   o0107
   o0107

o0108  new  Date o0101  now noiso8601 [ forcedate now,America/New_York ]
   =>
   Date::Manip::Date
   o0108
   o0108

o0109  new  Base o0101  [ defaults 1 ]
   =>
   Date::Manip::Base
   o0109
   ---

### config/get_config

- get_config o0001 yytoyyyy   => 89

- config o0001 yytoyyyy c18   => 0

- get_config o0001 yytoyyyy   => c18

- get_config o0002 yytoyyyy   => 89

- config o0002 yytoyyyy c18   => 0

- get_config o0002 yytoyyyy   => c18

- get_config o0003 yytoyyyy   => 89

- config o0003 yytoyyyy c18   => 0

- get_config o0003 yytoyyyy   => c18

- get_config o0004 yytoyyyy defaulttime => 89 midnight

- get_config o0004            => dateformat defaults defaulttime

";

$::ti->tests(func  => \&test,
             tests => $tests);
$::ti->done_testing();

#Local Variables:
#mode: cperl
#indent-tabs-mode: nil
#cperl-indent-level: 3
#cperl-continued-statement-offset: 2
#cperl-continued-brace-offset: 0
#cperl-brace-offset: 0
#cperl-brace-imaginary-offset: 0
#cperl-label-offset: 0
#End:
