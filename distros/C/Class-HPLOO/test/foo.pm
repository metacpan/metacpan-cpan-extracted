
use Class::HPLOO ;#qw(nice) ;

class foo {

  vars ($global) ;
  $global = "123456789" ;
  
  sub test( $arg ) {
    my $ret ;
    $ret .= ref($this) . "$arg\n" ;
    $ret .= "--------------\n" ;
    $ret .= <% html_test>( 123 ) ;
    $ret .= "--------------\n" ;
    $ret .= <% html_test2>( 123 , 456 , 789 ) ;
    $ret .= "--------------\n" ;
    return $ret ;
  }
  
<% html_test
  MOHHHH $global
%>
  
<% html_test2(@list)
  MOHHHH @list
%>
}


