use Authen::Tcpdmatch::Tcpdmatch;
use Test::More;

BEGIN { plan tests=> 9 }




ok     check( 'ALL: .1'              =>    qw(   tcp  192.168.0.1  ));
ok     check( 'ALL: .0.1'            =>    qw(   tcp  192.168.0.1  ));
ok     check( 'ALL: .168.0.1'        =>    qw(   tcp  192.168.0.1  ));


is   +(check( 'ALL: .2'              =>    qw(   tcp   192.168.0.1  ))),  undef;
is   +(check( 'ALL: .0.2'            =>    qw(   tcp   192.168.0.1  ))),  undef;
is   +(check( 'ALL: .168.0.2'        =>    qw(   tcp   192.168.0.1  ))),  undef;

ok     check( 'ALL: red .1'          =>    qw(   tcp   192.168.0.1  ));
is   +(check( 'ALL: red .2'          =>    qw(   tcp   292.168.0.1  ))),  undef;


## Extra 

is   +(check( 'ALL: ..1'             =>    qw(   tcp   192.168.0.1  ))),  undef;

