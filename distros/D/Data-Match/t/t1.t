#!/usr/bin/perl

# $Id: t1.t,v 1.8 2002/12/17 22:30:30 stephens Exp $

use strict;
use Test;

my @tests;
my $n_tests;
my $verbose = do { no warnings; $ENV{'TEST_VERBOSE'} > 1 };

BEGIN { 
  print join(', ', @ARGV), "\n";

my $tests = q{
#0
    match(undef, undef);
  ! match(1, undef);
    match(1, 1);
  ! match(2, 3);
  ! match('a', 'b');
#5
    match('x', 'x');
  ! match('x', 'y');
  ! match('x', 0);
    match('x', BIND('x'));
    match(undef, BIND('x'));
#10
    match([], []);
    match([ 1 ], [ 1 ]);
  ! match([ 1 ], [ ]);
  ! match([ ],   [ 1 ]);
  ! match([ 1, 2 ], [ 1 ]);
#15
  ! match([ 1 ],    [ 1, 2 ]);

    match({}, {});
    match({ 'a'=>1 }, { 'a' => 1 });
  ! match({ },          { 'a' => 1 });
  ! match({ 'a' => 1 }, { });
#20
  ! match({ 'a' => 1 }, { 'b' => '1' });
  ! match({ 'a' => 1 }, { 'a' => 2 });
  ! match({ 'a' => 1 }, { 'c' => 5 });
    match({ 'a'=>1, 'b'=>[ 1 ] }, { 'a'=>1, 'b'=>[ ANY() ] });

    match([ 1, 2, 3 ], BIND('x'));
#25
    match([ 1, 2, 3 ], [ BIND('x'), BIND('y'), 3 ]);
  ! match([ 1, 2, 3 ], [ BIND('x'), BIND('y'), BIND('x') ]);
    match([ 1, 2, 1 ], [ BIND('x'), ANY(), BIND('x') ]);
  ! match([ 1, 2, 4 ], [ BIND('x'), ANY(), BIND('x') ]);
    match([ 1, [ 1, 2, 1 ], 2 ], [ ANY(), [ BIND('x'), ANY, BIND('x') ], REST ]);
#30
    match([ [ 1 ], 2, [ 1 ] ], [ BIND('x'), ANY(), BIND('x') ]);
    match([ { 'a'=>1 }, 2, { 'a'=>1 } ], [ BIND('x'), ANY(), BIND('x') ]);
  ! match([ { 'a'=>1 }, 2, { 'b'=>1 } ], [ BIND('x'), ANY(), BIND('x') ]);

    match({ 'a' => 1, 'b' => 2 }, EACH(COLLECT('x', { 'a' => ANY })));

    match([ 1, 2, 3 ], COLLECT('x'));
#35
    match([ 1, 2, 3 ], [ COLLECT('x'), ANY(), COLLECT('x') ]);
  ! match([ 1, 2, 3 ], [ COLLECT('x'), 5, COLLECT('x') ]);

    match([ 1, 2, 4 ], ISA('ARRAY'));
  ! match([ 1, 2, 4 ], ISA('HASH'));

    match([ 'foo', 'bar', 'baz' ], EACH(COLLECT('x', REGEX(q{z$}))));
#40
  ! match([ 'foo', 'bar', 'baz' ], EACH(COLLECT('x', REGEX(q{^foobar$}))));

    match([ 1, 2, 3, 4 ],           EACH(COLLECT('x', OR(2, 3))) );
    match([ 1, 2, 3, 4 ],           EACH(COLLECT('x', OR('foo', 3))) );
  ! match([ 1, 2, 3, 4 ],           EACH(COLLECT('x', OR('foo', 'bar'))) );

    match(0,           NOT());
#45
  ! match(1,           NOT());
    match([ 1, 2, 3, 4 ],           EACH(COLLECT('x', NOT(OR(2, 3)))) );

    match([    2, 3    ],           ALL(COLLECT('x', OR(2, 3))) );
  ! match([ 1, 2, 3, 4 ],           ALL(COLLECT('x', OR(2, 3))) );
    match([ 1,       4 ],           ALL(COLLECT('x', NOT(OR(2, 3)))) );

    match([ 1, 2, 4 ], BIND('x', ISA('ARRAY')));
  ! match([ 1, 2, 4 ], BIND('x', ISA('HASH')));

  ! match([],           REST() );
    match([],          [ REST() ] );
    match([ 1, 2 ],    [ REST() ]);
    match([ 1, 2, 3 ], [ 1, 2, REST() ]);
    match([ 1, 2, 3, 4 ], [ 1, 2, REST(BIND('r')) ]);

  ! match({}                 , REST() );
    match({}                 , { REST() => REST(BIND('x')) } );
    match({ 'a'=>1, 'b'=>2 } , { REST() => REST(BIND('x')) } );
    match({ 'a'=>1, 'b'=>2, 'c'=>3 }, { 'a'=>1, 'b'=>2, REST() => REST(BIND('x')) });
  ! match({ 'a'=>1, 'b'=>2, 'c'=>3 }, { 'a'=>1, 'd'=>4, REST() => REST(BIND('x')) });

    match([ 1, 2, 3 ], EACH(COLLECT('x', 2)));
  ! match([ 1, 2, 3 ], EACH(COLLECT('x', 5)));
    match([ 1, 2, 3, 2, 5 ], EACH(COLLECT('x', 2)));

    match({ 'a'=>1, 'b'=>2, 'c'=>3 }, EACH(COLLECT('x', { 'c' => 3 })));
    match({ 'a'=>1, 'b'=>2, 'c'=>3 }, EACH(COLLECT('x', { ANY() => 3 })));
  ! match({ 'a'=>1, 'b'=>2, 'c'=>3 }, EACH(COLLECT('x', { ANY() => 5 })));
    match({ 'a'=>1, 'b'=>2, 'c'=>3, 'd'=>2, 'e'=>5 }, EACH(COLLECT('x', { ANY() => 2})));

    match([ 1, 2, 3 ],       FIND(COLLECT('x', 2)));
  ! match([ 1, 2, 3 ],       FIND(COLLECT('x', 5)));
    match([ 1, 2, 3, 2, 5 ], FIND(COLLECT('x', 2)));
    match([ 1, 2, [ 1, 2, [ 1, 2 ] ], 3 ],   FIND(COLLECT('x', 2)));
    match([ 1, 2, [ 1, 2, [ 1, 2 ] ], 3 ],   FIND(COLLECT('x', [ 1, 2 ])));
    match([ 1, 2, [ 'a', 2, [ 1, 2 ] ], 3 ], FIND(COLLECT('x', [ 1, REST() ])));
  ! match([ 1, 2, [ 1, 2, [ 1, 2 ] ], 3 ],   FIND(COLLECT('x', 5)));
  ! match([ 1, 2, [ 1, 2, [ 1, 2 ] ], 3 ],   FIND(COLLECT('x', 5)));

  ! match( '', LENGTH() );
    match( 'x', LENGTH() );
  ! match( [], LENGTH() );
    match( [ 'x' ], LENGTH() );
  ! match( {}, LENGTH() );
    match( { 'a'=>1 }, LENGTH() );
    match( [ 1, 2, 3 ], LENGTH() );
    match( [ 1, 2, 3 ],    [ 1, 2, REST(LENGTH())] );
  ! match( [ 1, 2, 3 ],    [ 1, 2, 3, REST(LENGTH())] );
    match( [ 1, 2, 3, 4 ], [ 1, 2, REST(LENGTH(EXPR(q{$_ > 1}))) ] );
  ! match( [ 1, 2, 3 ],    [ 1, 2, REST(LENGTH(EXPR(q{$_ > 1}))) ] );
  ! match( [ 1, 2 ],       [ 1, 2, REST(LENGTH(EXPR(q{$_ > 1}))) ] );

    match( 1, EXPR(q{$_ > 0}) );
  ! match( 1, EXPR(q{$_ > 1}) );
    match( [ 1, 2, 3 ], EACH(COLLECT('x', EXPR(q{$_ > 1}))) );

    match( [ 1, 'x', [ 2, 'x', [ 3, 'x'], [ 4, [ 5, [ 'x' ] ] ] ] ], 
	   FIND(DEPTH(EXPR(q{$_ >= 3})), COLLECT('x', 'x'))
	   );

    match( [ 1, 'x', [ 2, 'x', [ 3, 'x'], [ 4, [ 5, [ 'x' ] ] ] ] ], 
	   FIND(COLLECT('x', EXPR(q{! ref}))), 
	   { 'no_collect_path' => 1 }
	   );
 
    match( [ 1, 'x', [ 2, 'x', { 3, 'x'}, [ 4, { 5, [ 'x' ] }, 6, { 'x' => 7, 'y' => 8 } ] ] ], 
	   FIND(COLLECT('x', EXPR(q{! ref}))), 
	   { 'no_collect_path' => 1 }
	   );

    # circular structures
    do {
      my $x = [ 1, 2, [ 1, 2 ], 3 ]; $x->[2][1] = $x; #
      match($x, BIND('x', [ ANY, ANY, [ ANY, ANY ], ANY ]) ); #
    };

    do {
      my $x = [ 1, 2, [ 1, 2 ], 3 ]; $x->[2][1] = $x; #
      match($x, BIND('x', [ ANY, ANY, [ ANY, BIND('x') ], ANY ]) ); #
    };

    # slice mutation.
    do {
      my $a = [ 1, 2, 3, 4 ]; #
      my $p = [ 1, ANY, REST(BIND('s')) ]; #
      my $r = matches($a, $p); # TRUE
      ok($r); # TRUE
      ok(Compare($r->{'BIND'}{'s'}{'v'}[0], [ 3, 4 ])); # TRUE
      $r->{'BIND'}{'s'}{'v'}[0][0] = 'x'; #
      match($a, [ 1, 2, 'x', 4 ]); # TRUE
    };

# RANG operators: NOT FINISHED.

  ! match( [ ],                  [ 1, 2, QUES( ANY(), 4 ) ] );
  ! match( [ 1 ],                [ 1, 2, QUES( ANY(), 4 ) ] );
    match( [ 1, 2 ],             [ 1, 2, QUES( ANY(), 4 ) ] );
  ! match( [ 1, 2, 3 ],          [ 1, 2, QUES( ANY(), 4 ) ] );
    match( [ 1, 2, 3, 4 ],       [ 1, 2, QUES( ANY(), 4 ) ] );
  ! match( [ 1, 2, 3, 4, 3 ],    [ 1, 2, QUES( ANY(), 4 ) ] );
X    match( [ 1, 2, 3, 4, 3 ],    [ 1, 2, QUES( ANY(), 4 ), 3 ] );
  ! match( [ 1, 2, 3, 4, 3, 4 ], [ 1, 2, QUES( ANY(), 4 ) ] );

  ! match( [ ],                  [ 1, 2, PLUS( ANY(), 4 ) ] );
  ! match( [ 1 ],                [ 1, 2, PLUS( ANY(), 4 ) ] );
  ! match( [ 1, 2 ],             [ 1, 2, PLUS( ANY(), 4 ) ] );
  ! match( [ 1, 2, 3 ],          [ 1, 2, PLUS( ANY(), 4 ) ] );
    match( [ 1, 2, 3, 4 ],       [ 1, 2, PLUS( ANY(), 4 ) ] );
X    match( [ 1, 2, 3, 4, 5 ],    [ 1, 2, PLUS( ANY(), 4 ), 5 ] );
X  ! match( [ 1, 2, 3, 4, 3 ],    [ 1, 2, PLUS( ANY(), 4 ) ] );
X    match( [ 1, 2, 3, 4, 3, 4 ], [ 1, 2, PLUS( ANY(), 4 ) ] );
X    match( [ 1, 2, 3, 4, 3, 4, 5 ], [ 1, 2, PLUS( ANY(), 4 ), 5 ] );

 };
#)emacs

  @tests = split(/;\s*\n/s, $tests);
  grep(s/^\s+//s, @tests);
  grep(s/^\#.*//s, @tests);
  @tests = grep(length $_, @tests);
	
  # Get base number of tests.
  $n_tests = @tests;

  # Count embedded ok()'s.
  for my $t ( @tests ) {
    my @oks = $t =~ /(ok[(])/g;
    $n_tests += @oks;
  }

  #warn "n_tests=$n_tests";

  plan tests => $n_tests;
};

use Data::Match qw(:all);
use Data::Compare;


sub UNIT_TEST
{
  my $n_passed = 0;

  use Data::Dumper;

  #$debug = 1;
  #$DB::single = 1;

  for my $test ( @tests ) {
    my ($opts, $invert, $expr) = ( $test =~ /^\s*([VX])?\s*(!)?\s*(.*)\s*$/s);
    next unless do { no warnings; length $expr };

    $opts ||= '';

    # A "V" before the test case forces
    # printing of the test case and result, 
    # regardless of $verbose.
    my $tv = $opts =~ /V/;
    $tv ||= $verbose;

    # A 'X' before a test eXcludes it.
    if ( $opts =~ /X/ ) {
      # Pretend it and all embedded ok()'s passed.
      ok(1);
      map(ok(1), $expr =~ /(ok[(])/g);
      next;
    }

    # $DB::single = 1;
    my $rtn = eval "[ $expr ];";
    if ( $@ or ref($rtn) ne 'ARRAY' or @$rtn < 2 ) {
      print STDERR '  EVAL ERROR: ', $test, "\n";
      die "$@: $expr";
    }

    my ($matched, $results) = @$rtn;
    my $passed = $matched;
    $passed = ! $passed if $invert;

    if ( $results ) {
      # Validate the BIND and COLLECT values and paths.
      for my $ck ( $results->{'_BIND'}, $results->{'_COLLECT'} ) {
	if ( my $c = $ck && $results->{$ck} ) {
	  for my $k ( keys %$c ) {
	    my $e = $c->{$k};
	    next unless $e->{'p'};
	    for my $i ( 0 .. $#{$e->{'v'}} ) {
	      my $v = $e->{'v'}[$i];
	      my $p = $e->{'p'}[$i];

	      my $ps = $results->match_path_str($p);
	      my $pv = $results->match_path_get($p);

	      my $path_ok = Compare($pv, $v);
	      print "  PATH $ps ($pv) ne $v\n" if ! $path_ok;

	      $passed &&= $path_ok;
	    }
	  }
	}
      }
 
      # Remove redundant results from display.
      delete $results->{'depth'};
      delete $results->{'path'};
      delete $results->{'root'};
      delete $results->{'pattern'};
    }

    # Print results?
    if ( $tv || ! $passed ) {
      print '  ', $test, "\n";
      print " return ", Data::Dumper->new([ $matched, $results ], [ '$matched', '$results' ])->Indent(0)->Purity(1)->Terse(1)->Dump(), "\n\n";
    }

    # Did it pass?
    ok($passed);

    ++ $n_passed if $passed;
  }

  print STDERR "\n$n_passed passed / $n_tests tests \n" if $verbose;

  $n_passed == $n_tests ? 0 : 1;
}


UNIT_TEST();

1;

### Keep these comments at end of file: kurtstephens@acm.org 2001/12/28 ###
### Local Variables: ###
### mode:perl ###
### perl-indent-level:2 ###
### perl-continued-statement-offset:0 ###
### perl-brace-offset:0 ###
### perl-label-offset:0 ###
### End: ###

