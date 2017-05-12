use Authen::Tcpdmatch::Tcpdmatch;
use Test::More;

BEGIN { plan tests=> 6 }



ok     check( "tcp : red \n ftp   : ntro" ,   qw(  tcp  red  )) ;
ok     check( "tcp : red \n ftp   : ntro" ,   qw(  ftp  ntro )) ;
ok     check( "tcp : red \n\n ftp : ntro" ,   qw(  ftp  ntro )) ;

is   +(check( "tcp : red \n ftp : ntro" ,   qw(  tcp  ntro ))),  undef ;
is   +(check( "tcp : red \n ftp : ntro" ,   qw(  ftp  red  ))),  undef ;

ok     check( <<'' ,   qw(  tcp  red )) ;
#afa
tcp : red

__END__
ok     check( "tcp   red \n\n ftp : ntro" ,   qw(  ftp  ntro )) ;
ok     check( "tcp : red \n ftp     ntro" ,   qw(  tcp  red )) ;
