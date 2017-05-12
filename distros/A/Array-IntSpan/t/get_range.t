# -*- cperl-mode -*-

use strict ;
use warnings FATAL => qw(all);
use ExtUtils::testlib;
use Test::More tests => 50 ;
use Data::Dumper ;

use Array::IntSpan;
my $trace = shift || 0 ;

# test min max
is(Array::IntSpan::min(9,10), 9,'min test 9,10') ;
is(Array::IntSpan::max(9,10),10,'max test 9,10') ;


my @expect= ([1,3,'ab'],[5, 7, 'cd'], [13, 26, 'ef']) ;
my $r = Array::IntSpan->new(@expect) ;

diag(Dumper $r) if $trace ;

ok ( defined($r) , 'Array::IntSpan new() works') ;
is_deeply( $r , \@expect, 'new content ok') ;


foreach my $t (
               [[32,34],[]],
               [[4,4],[]],
               [[24,26],[[24,26,'ef']]],
               [[24,29],[[24,26,'ef']]],
               [[10,16],[[13,16,'ef']]],
               [[20,24],[[20,24,'ef']]],
               [[0,9],[[1,3,'ab'],[5,7,'cd']]],
               [[0,6],[[1,3,'ab'],[5,6,'cd']]],
              )
  {
    my $new = $r->get_range(@{$t->[0]}) ;
    is_deeply($new, $t->[1], "get_range @{$t->[0]}") || 
      diag("From ".Dumper($r)."Got ".Dumper ($new)) ;
    is(@$r, 3, 'check nb of items in range') || diag(Dumper $r);
  }

my $fill = 'fi' ;

foreach my $t (
               [
                [32,34],
                [[32,34,$fill]],
                [@expect,[32,34,$fill]]
               ],
               [
                [0,0],
                [[ 0, 0,$fill]],
                [[0,0,$fill],@expect]
               ],
               [
                [5,5],
                [[ 5, 5,'cd']],
                [[1,3,'ab'],[ 5, 5,'cd'],[6, 7, 'cd'], [13, 26, 'ef']]
               ],
               [
                [24,26],
                [[24,26,'ef' ]],
                [[1,3,'ab'],[5, 7, 'cd'], [13, 23,'ef'],[24,26, 'ef']]
               ],
               [
                [24,29],
                [[24,26,'ef'],[27,29,$fill]],
                [[1,3,'ab'],[5, 7, 'cd'], [13, 23,'ef'],[24,26,'ef'],[27,29,$fill]]
               ],
               [
                [10,16],
                [[10,12,$fill],[13,16,'ef']],
                [[1,3,'ab'],[5, 7, 'cd'], [10,12,$fill],,[13,16,'ef'],[17, 26, 'ef']]
               ],
               [
                [20,24],
                [[20,24,'ef']],
                [[1,3,'ab'],[5, 7,'cd'],[13,19,'ef'],[20,24,'ef'],[25,26,'ef']]
               ],
               [
                [0,9],
                [[0,0,$fill],[1,3,'ab'],[4,4,$fill],[5,7,'cd'],[8,9,$fill]],
                [[0,0,$fill],[1,3,'ab'],[4,4,$fill],[5,7,'cd'],[8,9,$fill], [13, 26, 'ef']]
               ],
               [
                [0,6],
                [[0,0,$fill],[1,3,'ab'],[4,4,$fill],[5,6,'cd']],
                [[0,0,$fill],[1,3,'ab'],[4,4,$fill],[5,6,'cd'],[7,7,'cd'], [13, 26, 'ef']]
               ],
               [
                [2,5],
                [[2,3,'ab'],[4,4,$fill],[5, 5, 'cd']],
                [[1,1,'ab'],[2,3,'ab'],[4,4,$fill],[5, 5, 'cd'],[6, 7, 'cd'], [13, 26, 'ef']]
               ]
              )
  {
    my $r2 = Array::IntSpan->new(@expect) ;
    my $old = Dumper($r2) ;
    my $new = $r2->get_range(@{$t->[0]}, $fill) ;
    is_deeply($new, $t->[1], "get_range with fill @{$t->[0]}") || 
      diag("From ".$old."Got ".Dumper ($new)) ;
    is_deeply($r2, $t->[2], "range after get_range with fill") || 
      diag("From ".$old."Expected ".Dumper($t->[2])."Got ".Dumper ($r2)) ;
  }

my $sub = sub { "sfi"};
$fill = &$sub ;

foreach my $t (
               [[30,39],[[30,39,$fill]],[@expect,[30,39,$fill]]],
               [
                [0,9],
                [[0,0,$fill],[1,3,'ab'],[4,4,$fill],[5,7,'cd'],[8,9,$fill]],
                [[0,0,$fill],[1,3,'ab'],[4,4,$fill],[5,7, 'cd'],[8,9,$fill], [13, 26, 'ef']]
               ],
              )
  {
    my $r2 = Array::IntSpan->new(@expect) ;
    my $old = Dumper($r2) ;
    my $new = $r2->get_range(@{$t->[0]}, $sub) ;
    is_deeply($new, $t->[1], "get_range with fill sub @{$t->[0]}") || 
      diag("From ".$old."Got ".Dumper ($new)) ;
    is_deeply($r2, $t->[2], "range after get_range with sub") || 
      diag("From ".$old."Expected ".Dumper($t->[2])."Got ".Dumper ($r2)) ;
  }

@expect=([9,9,'ab'],[10,10,'bc'],[11,11,'cd'],[12,12,'ef']);
foreach my $t (
               [
                [9,10],
                [[9,9,'ab'],[10,10,'bc']],
                [@expect]
               ],
               [
                [9,12],
                [@expect],
                [@expect]
               ]
              )
  {
    my $r2 = Array::IntSpan->new(@expect) ;
    my $old = Dumper($r2) ;
    my $new = $r2->get_range(@{$t->[0]}, $sub) ;
    is_deeply($new, $t->[1], "get_range with fill sub @{$t->[0]}") || 
      diag("From ".$old."Got ".Dumper ($new)) ;
    is_deeply($r2, $t->[2], "range after get_range with sub") || 
      diag("From ".$old."Expected ".Dumper($t->[2])."Got ".Dumper ($r2)) ;
  }

@expect= ([1,3,'ab'],[5, 5, 'cd'], [13, 26, 'ef']) ;
my $rs = Array::IntSpan->new(@expect) ;

is_deeply([ $rs->get_range_list ], [[1,3],[5, 5], [13, 26] ], "get_ranges in list context");
is_deeply(scalar $rs->get_range_list, '1-3, 5, 13-26', "get_ranges in scalar context");

diag(Dumper $r) if $trace ;
