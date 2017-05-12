
use Class::HPLOO ;

class Foo extends Bar , Baz {

  sub Foo {
    $this->{attr} = $_[0] ;
  }

  sub test_arg($arg1) {
    $this->{arg1} = $arg1 ;
  }
  
  sub test_ref($arg2 , \@list , \%opts) {
    $this->{arg2} = $arg2 ;
    $this->{l0} = @list[0] ;
    $this->{l1} = @list[1] ;
    $this->{opts} = \%opts ;
  }

}

1;


