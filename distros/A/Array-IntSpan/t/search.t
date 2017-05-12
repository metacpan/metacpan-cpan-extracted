
use warnings FATAL => qw(all);
use ExtUtils::testlib;
use Test::More tests => 9 ;
use Data::Dumper ;

use Array::IntSpan;

my $trace = shift || 0 ;

my @expect= ([1,3,'ab'],[6,9,'cd']) ;
my $r = Array::IntSpan->new(@expect) ;

diag(Dumper $r) if $trace ;

ok ( defined($r) , 'Array::IntSpan new() works') ;
is_deeply( $r , \@expect, 'new content ok') ;

foreach my $a ( [2,0], [3,0], [4,1], [4,1], [6,1], [9,1] , [10,2])
  {
    is($r->search(0,2,$a->[0]), $a->[1], "search(0,2,$a->[0], $a->[1] )");
  }

