
use warnings FATAL => qw(all);
use ExtUtils::testlib;
use Test::More tests => 18 ;
use Data::Dumper ;

use Array::IntSpan;

my $trace = shift || 0 ;

my @expect= ([1,3,'ab'],[5, 7, 'cd'], [13, 26, 'ef']) ;
my $r = Array::IntSpan->new(@expect) ;

diag(Dumper $r) if $trace ;

ok ( defined($r) , 'Array::IntSpan new() works') ;
is_deeply( $r , \@expect, 'new content ok') ;

foreach my $t (
               [[32,34,'oops'],[]],
               [[4,4,'oops'],[]],
               [[24,26,'oops'],[[24,26,'ef']]],
               [[24,29,'oops'],[[24,26,'ef']]],
               [[10,16,'oops'],[[13,16,'ef']]],
               [[20,24,'oops'],[[20,24,'ef']]],
               [[0,9,'oops'],[[1,3,'ab'],[5,7,'cd']]],
               [[0,6,'oops'],[[1,3,'ab'],[5,6,'cd']]],
              )
  {
    my @clobbered = $r->clobbered_items(@{$t->[0]}) ;
    is(@$r, 3, 'check nb of items in range') || diag(Dumper $r);
    is_deeply(\@clobbered, $t->[1], "clobbered_items @{$t->[0]}") || 
      diag(Dumper \@clobbered) ;
  }

