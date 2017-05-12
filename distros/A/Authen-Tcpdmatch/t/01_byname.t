use Authen::Tcpdmatch::Tcpdmatch;
use Test::More;

BEGIN { plan tests=> 11 }




ok      check( 'tcp: red'                         =>   qw(   tcp  red  ));
is    +(check( 'irc: red'                         =>   qw(   tcp  red  ))),  undef;
ok      check( 'tcp: ntro red'                    =>   qw(   tcp  red ));

is    +(check( 'tcp EXCEPT tcp: red'              =>   qw(   tcp  red  ))),  undef;
ok      check( 'tcp EXCEPT irc, chat: red'        =>   qw(   tcp  red  ));
ok      check( 'tcp EXCEPT tcp EXCEPT tcp :red'   =>   qw(   tcp   red ));




is    +(check( 'tcp: red       EXCEPT red'         =>   qw(   tcp  red ))),  undef;
is    +(check( 'tcp: ntro red  EXCEPT red'         =>   qw(   tcp  red ))),  undef;
ok      check( 'tcp: ntro red  EXCEPT    '         =>   qw(   tcp  red ));

ok      check( "ftp: red \n tcp : red"             =>   qw(   tcp  red  ));
 
### Extra
is    +( check( ''                                 =>   qw(   tcp   red ))), undef ;

__END__
#ok      check( 'tcp  EXCEPT  : red  '             =>   qw(   tcp  red ));
#is    +(check( 'irc EXCEPT tcp EXCEPT tcp :red'   =>   qw(   tcp   red ))),  undef;
#is    +(check( 'irc EXCEPT irc EXCEPT tcp :red'   =>   qw(   tcp   red ))),  undef;
