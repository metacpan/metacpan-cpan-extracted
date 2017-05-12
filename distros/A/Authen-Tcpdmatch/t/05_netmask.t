use Authen::Tcpdmatch::Tcpdmatch;
use Test::More;

BEGIN { plan tests=>  11 } 




ok      check( 'ALL: 192.168.0.1'             =>  qw(     tcp   192.168.0.1  ));
is   +( check( 'ALL: 192.168.0.1'             =>  qw(     tcp   192.168.0.2  ))),  undef;


ok      check( 'ALL: 192.168.0.1/24'          =>  qw(     tcp   192.168.0.6  ));
is   +( check( 'ALL: 192.168.0.1/24'          =>  qw(     tcp   192.168.2.1  ))),  undef;
is   +( check( 'ALL: 999.3.0.1/24'            =>  qw(     tcp   192.168.2.1  ))),  undef;
is   +( check( 'ALL: 999.3.0.1/24'            =>  qw(     tcp   192.8.0.1    ))),  undef;
is   +( check( 'ALL: 192.168.0.1/24'          =>  qw(     tcp   192.168.2.1  ))),  undef;
ok      check( 'ALL: 192.168.0.1/8'           =>  qw(     tcp   192.168.0.1  ));


ok    check( 'ALL: 192.168.0.1/255.255.255.0' =>  qw(   tcp   192.168.0.2  ));
ok    check( 'ALL: 192.168.0.1/255.255.0.0'   =>  qw(   tcp   192.168.2.2  ));
is  +(check( 'ALL: 192.168.0.1/255.255.255.0' =>  qw(   tcp   192.162.0.2  ))),  undef;

#is   +( check( 'ALL: 192.168.0.1/999'        =>  qw(    tcp   192.8.0.1  ))),  undef;
