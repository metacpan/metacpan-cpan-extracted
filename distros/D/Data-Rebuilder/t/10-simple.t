
use Test::More tests => 10;
BEGIN{ require "t/lib/t.pl"; &init; }
use FileHandle;
use Scalar::Util qw( blessed );

# CodeRef
use t::coderef;
{
  my $b = Data::Rebuilder->new;
  my $counter = t::coderef::counter();
  $counter->();
  $counter->();
  my $counter1   = $b->_t( $counter );
  is( $counter1->() , $counter->() , "freeze counter 2" );
  is( $counter1->() , $counter->() , "freeze counter 3" );
  is( $counter1->() , $counter->() , "freeze counter 4" );


  my $counterv = t::coderef::counterv();
  $b->parameterize( counterv => $counterv );
  my $counter2 =  $b->_t( $counter , counterv => do{ my $a = 8; \$a } );
  is( $counter2->() ,  8 , "parameterized 8");
  is( $counter2->() ,  9 , "parameterized 9");
  is( $counter2->() , 10 , "parameterized 10");
}


# Glob
{
  my $b = Data::Rebuilder->new;
  my $r = $b->_t(*STDIN);
  is( $r, *STDIN );
}

{
  my $b = Data::Rebuilder->new;
  my $fh = FileHandle->new;
  my $r  = $b->_t($fh);
  is( blessed $r , 'FileHandle');
  isnt(*{$r}, *{$fh});
  is( $$$fh, $$$r );
}
