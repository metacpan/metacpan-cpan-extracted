#!/usr/bin/perl

# $Id: t3.t,v 1.3 2002/04/22 06:36:58 stephens Exp $

# Test for Data::Match::Slice::{Array,Hash}

use strict;
use Test;

my $verbose = do { no warnings; $ENV{TEST_VERBOSE} > 1 };

BEGIN { 
  plan tests => 15;
};

use Data::Match qw(:all);
use Data::Compare;

##############################################################

my @ai = ( 0 .. 6 );
my @a = @ai;

my $x = matches(\@a, [ 0, 1, 2, REST(BIND('x')) ]);

#0
ok( $x);
ok( UNIVERSAL::isa($x, 'HASH') );
ok( $x->{'BIND'} );
ok( $x->{'BIND'}{'x'} );
ok( $x->{'BIND'}{'x'}{'v'} );
#5
ok( $x->{'BIND'}{'x'}{'v'}[0] );
ok( ref($x->{'BIND'}{'x'}{'v'}[0]) eq 'ARRAY' );
ok( ref($x->{'BIND'}{'x'}{'v'}[0]) eq 'ARRAY' );
ok( scalar(@{$x->{'BIND'}{'x'}{'v'}[0]}) == 4 ); 
  warn scalar(@{$x->{'BIND'}{'x'}{'v'}[0]}) if ( $verbose );
  my @x = ( 'a', 'b' ); 
ok( push(@{$x->{'BIND'}{'x'}{'v'}[0]}, @x) );
#10
ok( scalar(@{$x->{'BIND'}{'x'}{'v'}[0]}) == 6 );  
  warn scalar(@{$x->{'BIND'}{'x'}{'v'}[0]}) if ( $verbose );
ok( scalar(@a) == 9 ); 
  warn scalar(@a) if ( $verbose );
ok( $a[-1] eq $x[-1] );
ok( $a[-2] eq $x[-2] );
ok( Compare([ @ai, @x ], \@a) );
#15

1;

### Keep these comments at end of file: kurtstephens@acm.org 2001/12/28 ###
### Local Variables: ###
### mode:perl ###
### perl-indent-level:2 ###
### perl-continued-statement-offset:0 ###
### perl-brace-offset:0 ###
### perl-label-offset:0 ###
### End: ###

