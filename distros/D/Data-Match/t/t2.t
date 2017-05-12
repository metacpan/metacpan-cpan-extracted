#!/usr/bin/perl

# $Id: t2.t,v 1.3 2002/04/22 06:36:58 stephens Exp $

# Test for Data::Match::Slice::{Array,Hash}

use strict;
use Test;

BEGIN { 
  plan tests => 25;
};

use Data::Match qw(:all);
use Data::Compare;

##############################################################

my @a = ( 0 .. 6 );
my @sa;
tie @sa, 'Data::Match::Slice::Array', \@a, 3, 5;

my @hv = ( 0 .. 6 );
my $i = 'a';
my @hk = map((++ $i), @hv);
my %h; @h{@hk} = @hv;
my %hs;
my @hsk = @hk[3..4];
#$DB::single = 1;
tie %hs, 'Data::Match::Slice::Hash', \%h, \@hsk;

##############################################################

#0
ok(@sa eq 2);
ok($sa[0] eq 3);
ok($sa[1] eq 4);
ok(! defined $a[9]); 
ok(! defined $sa[2]);
#5
ok($a[-1] eq 6);
ok($sa[-1] eq 4);
  $sa[0] = 'x'; 
ok($sa[0] eq 'x');
ok($a[3] eq 'x');
ok(1);
#10
ok($h{'b'} eq 0);
ok($hs{'e'} eq $h{'e'});
ok(! defined $h{'a'});
ok(! defined $hs{'a'});
ok(! defined $hs{'b'});
#15
  $DB::single = 1;
ok(Compare([sort keys %hs], [ sort @hsk ]));
  $hs{'e'} = 'x'; 
ok($hs{'e'} eq 'x');
ok($h{'e'} eq 'x');
  $hs{'x'} = 'y';
ok($hs{'x'} eq 'y');
ok($h{'x'} eq 'y');
#20
ok(! exists $h{'foo'});
ok(exists $h{'x'});
ok(exists $hs{'x'});
ok(exists $h{'b'});
ok(! exists $hs{'b'});
#25

1;

### Keep these comments at end of file: kurtstephens@acm.org 2001/12/28 ###
### Local Variables: ###
### mode:perl ###
### perl-indent-level:2 ###
### perl-continued-statement-offset:0 ###
### perl-brace-offset:0 ###
### perl-label-offset:0 ###
### End: ###

