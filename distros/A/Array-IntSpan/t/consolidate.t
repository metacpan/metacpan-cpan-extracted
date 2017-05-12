
use warnings FATAL => qw(all);
use ExtUtils::testlib;
use Test::More tests => 27 ;
use Data::Dumper ;

use Array::IntSpan;

my $trace = shift || 0 ;

my @expect= ([1,3,'ab'], [6, 7, 'cd'], [8, 13, 'ef'], [14, 14, 'ef']) ;
my $r = Array::IntSpan->new(@expect) ;

diag(Dumper $r) if $trace ;

ok ( defined($r) , 'Array::IntSpan new() works') ;
is_deeply( $r , \@expect, 'new content ok') ;

$r->consolidate ;

@expect= ([1,3,'ab'], [6, 7, 'cd'], [8, 14, 'ef']) ;
is_deeply( $r , \@expect, 'consolidate ok') || diag(Dumper $r);
diag(Dumper $r) if $trace ;

my @sub = ( sub {"c:".$_[2];},
            sub {print "set called with @_\n";} );

foreach my $t (
               [[5,5,'cd'],0,[[1,3,'ab'], [5, 7, 'cd'], [8, 14, 'ef']]],
               [[13,16,'ef'],1,[[1,3,'ab'], [5, 7, 'cd'], [8, 16, 'ef']]],
               [[24,26,'ef'],0,[[1,3,'ab'], [5, 7, 'cd'], [8, 16, 'ef'],[24,26,'ef']]] ,
               [[19,22,'ef'],0,[[1,3,'ab'], [5, 7, 'cd'], [8, 16, 'ef'],[19,22,'ef'],[24,26,'ef']]],
               [[23,23,'efa'],0,[[1,3,'ab'], [5, 7, 'cd'], [8, 16, 'ef'],[19,22,'ef'],[23,23,'efa'],[24,26,'ef']]],
               [[23,23,'ef'],1,[[1,3,'ab'], [5, 7, 'cd'], [8, 16, 'ef'],[19,26,'ef']]],
               [[17,18,'efb'],0,[[1,3,'ab'], [5, 7, 'cd'], [8, 16, 'ef'],[17,18,'efb'],[19,26,'ef']]],
               [[17,18,'ef'],1,[[1,3,'ab'], [5, 7, 'cd'], [8 ,26,'ef']]],
               [[8,12,undef],1,[[1,3,'ab'], [5, 7, 'cd'], [13 ,26,'ef']]],
               [[8,12,'gh',@sub],0,[[1,3,'ab'], [5, 7, 'cd'],[8,12,'gh'], [13 ,26,'ef']]],
               [[13,20,'gh',@sub],1,[[1,3,'ab'], [5, 7, 'cd'],[8,20,'gh'], [21 ,26,'c:ef']]],
               [[6,7,'gh',@sub],1,[[1,3,'ab'], [5, 5, 'c:cd'],[6,20,'gh'], [21 ,26,'c:ef']]],
              )
  {
    my @range = @{$t->[0]} ;
    is ($r->set_consolidate_range(@range),$t->[1], 
        "set_consolidate_range @range[0,1]") ;
    is_deeply($r, $t->[2], "result of @range[0,1]") || 
      diag("Got ".Dumper($r)) ;
  }

