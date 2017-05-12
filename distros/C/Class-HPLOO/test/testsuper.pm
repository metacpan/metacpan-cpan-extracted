
use Class::HPLOO base ;

class TestSuper extends TestSuper2 {

  sub TestSuper {
    $this->{2} = $this->SUPER ;
    $this->{n2} = $CLASS->SUPER ;
    return $this ;
  }

  sub test {
    return( 't1' , $this->SUPER) ;
  }

}


class TestSuper2 extends TestSuper3 {

  sub TestSuper2 {
    $this->{3} = $this->SUPER if $this ;
    $this->{n3} = $CLASS->SUPER ;
    return $this ;    
  }

  sub test {
    return( 't2' , $this->SUPER) ;
  }

}

class TestSuper3 {
  
  vars($id) ;
  
  sub TestSuper3 {
    $this->{id} = ++$id ;
    return $this ;
  }

  sub test {
    return( 't3' ) ;
  }

}





