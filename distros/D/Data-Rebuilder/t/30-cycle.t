
BEGIN{ require "t/lib/t.pl"; &init; }
use Test::More tests => 12;
use Scalar::Util qw( refaddr );


## ArrayRef
{
  my $b = Data::Rebuilder->new;
  my $a = [0 , [1, my $last = [2, undef]]];
  $last->[1] = $a;
  my $c = $b->_t($a);
  print "$@\n" if $@;
  for( my $i = 0; $c && $i < 5; $i++){
    $c = $c->[1];
  }
  is( $c->[0] , 2 , "cycled (ArrayRef)");
}


{
  my $b = Data::Rebuilder->new;
  my $x = [ 123 ];
  $x->[1] = \$x->[0];
  my $c = $b->_t($x);
  is( ${$c->[1]}, $c->[0] );
  $c->[0] = 'HOGE';
  is( ${$c->[1]}, $c->[0] );
}

{
  my $b = Data::Rebuilder->new;
  my $x = [];
  $x->[0] = \$x;
  my $y = $b->_t($x);
  is( refaddr( $y->[0] ) , refaddr( ${$y->[0]}->[0] ) );
}

## HashRef
{
  my $b = Data::Rebuilder->new;
  my $a = { car => 0 ,
            cdr => { car => 1,
                     cdr => my $last = { car => 2,
                                         cdr => undef }}};
  $last->{cdr} = $a;
  my $c = $b->_t($a);
  for( my $i = 0; $c && $i < 5; $i++){
    $c = $c->{cdr};
  }
  is( $c->{car} , 2 , "cycled (HashRef)");
}

{
  my $b = Data::Rebuilder->new;
  my $x = { abc => 123 , def => undef };
  $x->{def} = \$x->{abc};
  my $c = $b->_t($x);
  is( $c->{abc} , ${$c->{def}});
  $c->{abc} = 999;
  is( $c->{abc} , ${$c->{def}});
}

{
  my $b = Data::Rebuilder->new;
  my $x = {};
  $x->{foo} = \$x;
  my $y = $b->_t($x);
  is( refaddr( $y->{foo} ) , refaddr( ${$y->{foo}}->{foo} ) );
}


## ScaalrRef
{
  my $b = Data::Rebuilder->new;
  my $x = undef;
  my $y = \$x;
  $x = \$y;
  my $c = $b->_t($x);
  is( refaddr($c), refaddr($$$c) );
}

{
  my $b = Data::Rebuilder->new;
  my $x = undef;
  $x = \$x;
  my $c = $b->_t($x);
  is( refaddr($c), refaddr($$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$c) );
}


## CodeRef
{
  my $b = Data::Rebuilder->new;
  my $fact;  $fact = sub{
    my $n = shift;
    return $n if $n == 1 ;
    $n * $fact->($n - 1);
  };
  my $r = $b->_t( $fact );
  is($fact->(10), $r->(10));
}

{
  my $b = Data::Rebuilder->new;
  my $o = {};
  $o->{fact} = sub{
    my $n = shift;
    return $n if $n == 1 ;
    $n * $o->{fact}->($n - 1);
  };
  my $r = $b->_t( $o );
  is($o->{fact}->(10), $r->{fact}->(10));
}

