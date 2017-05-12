use Authen::Tcpdmatch::Tcpdmatch;
use Test::More;

BEGIN { plan tests=> 13 }



ok     check( 'ALL: 192.'            =>   qw(  tcp  192.168.0.1  ));
ok     check( 'ALL: 192.168.'        =>   qw(  tcp  192.168.0.1  ));
ok     check( 'ALL: 192.168.0.'      =>   qw(  tcp  192.168.0.1  ));


is   +(check( 'ALL: 192.'            =>   qw(  tcp   292.168.0.1  ))),  undef;
is   +(check( 'ALL: 192x'            =>   qw(  tcp   292.168.0.1  ))),  undef;
is   +(check( 'ALL: 192.168.'        =>   qw(  tcp   292.168.0.1  ))),  undef;
is   +(check( 'ALL: 192.168.0'       =>   qw(  tcp   292.168.0.1  ))),  undef;

ok     check( 'ALL: red 192.168.'    =>   qw(  tcp   192.168.0.1  ));
is   +(check( 'ALL: red 192.168.'    =>   qw(  tcp   292.168.0.1  ))),  undef;


## Extra 
is   +(check( 'ALL: 192..'           =>   qw(  tcp   192.168.0.1  ))),  undef;
is   +(check( 'ALL: 192.168..'       =>   qw(  tcp   192.168.0.1  ))),  undef;
is   +(check( 'ALL: 192.168.0..'     =>   qw(  tcp   192.168.0.1  ))),  undef;
is   +(check( 'ALL: ALL EXCEPT 192.' =>   qw(  tcp   192.168.0.1  ))),  undef;

