use Authen::Tcpdmatch::Tcpdmatch;
use Test::More;

BEGIN { plan tests=> 15 }



##############################################################  SERVICES

ok      check( 'ALL: red'                  =>   qw(  tcp  red  ));
ok      check( 'irc ALL: red'              =>   qw(  tcp  red  ));
is    +(check( 'ALL EXCEPT tcp: red'       =>   qw(  tcp  red  ))),  undef;
ok      check( 'tcp EXCEPT irc, chat: red' =>   qw(  tcp  red  ));
ok      check( 'ALL: ALL'                  =>   qw(  tcp  red  ));
ok      check( 'ALL: LOCAL'                =>   qw(  tcp  red  ));


##############################################################  REMOTES

ok      check( 'tcp: LOCAL'                =>   qw(  tcp  red   ));
is    +(check( 'tcp: LOCAL'                =>   qw(  tcp  r.edu ))) , undef ;
ok      check( 'tcp: LOCAL, red'           =>   qw(  tcp  red   ));
ok      check( 'tcp: red LOCAL'            =>   qw(  tcp  red   ));
is    +(check( 'tcp: red LOCAL'            =>   qw(  tcp  r.edu ))) , undef ;
  
is    +(check( 'tcp: ALL EXCEPT red  '     =>   qw(  tcp  red   ))),  undef;
ok      check( 'tcp: ALL EXCEPT ntro '     =>   qw(  tcp  red   ));

is    +(check( 'tcp EXCEPT ALL: red'       =>   qw(  tcp  red   ))),  undef;
is    +(check( 'tcp: ALL EXCEPT LOCAL'     =>   qw(  tcp  red   ))),  undef;

