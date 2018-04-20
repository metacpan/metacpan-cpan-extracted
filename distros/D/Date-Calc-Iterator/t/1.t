# $Id: 1.t,v 1.1 2004/03/17 19:18:12 bronto Exp $

use Test::More tests => 4 ;
#use Test::More 'no_plan' ;
BEGIN { use_ok('Date::Calc::Iterator') };

#########################

# Create object
my $i = Date::Calc::Iterator->new(from => [2003,12,1], to => [2003,12,10]) ;

eval { $i->isa('Date::Calc::Iterator') } ;
is($@,'','new() creates object') ;

# iterate from December 1st, 2003 to December 10, 2003
{
  my @dates ;
  push @dates,$_ while $_ = $i->next ;

  is(scalar(@dates),10,'Iteration produces the expected number of items')
}

# Check if it returns an array reference in scalar context
{
  # Initialize the iterator again
  $i = Date::Calc::Iterator->new(from => [2003,12,1], to => [2003,12,10]) ;

  my $day = $i->next ;
  is(ref($day),'ARRAY','next() returns an array reference in scalar context') ;
}
