use  Authen::Tcpdmatch::Tcpdmatch;
use  Test::More;

BEGIN { plan tests=> 18 }


ok       check( "tcp : red"                 =>  qw(   tcp   red           ));
ok       check( "tcp : red \n ftp : ntro"   =>  qw(   tcp   red           )) ;
is    +( check( ''                          =>  qw(   tcp   red           ))),  undef ;
is    +( check( 'chat irc :  red'           =>  qw(   irc   hh            ))),  undef ;
ok       check( 'chat irc EXCEPT ftp : red' =>  qw(   irc   red           ));
is    +( check( 'chat irc EXCEPT irc : red' =>  qw(   irc   red           ))),  undef ;
ok       check( 'irc ALL  :  red'           =>  qw(   irc   red           ));
ok       check( 'irc ALL  :  red'           =>  qw(   ftp   red           ));
ok       check( 'irc ALL  :  red'           =>  qw(   ftp   red           ));
ok       check( 'irc      :  LOCAL'         =>  qw(   irc   red           ));
is    +( check( 'irc      :  LOCAL'         =>  qw(   irc   red.haw.org   ))),  undef;
ok       check( 'irc      : .haw.org'       =>  qw(   irc   red.haw.org   ));
is    +( check( 'irc      : .haw.org'       =>  qw(   ftp   red.haw.org   ))),  undef ;
ok       check( 'irc      :  192.168.'      =>  qw(   irc   192.168.0.1   ));
ok       check( 'irc      :  192.168.'      =>  qw(   irc   192.168.0.1   ));
ok       check( 'ALL: 192.168.0.1/24'       =>  qw(   tcp   192.168.0.6   ));
is    +( check( 'ALL: 192.168.0.1/24'       =>  qw(   tcp   192.168.2.1   ))) , undef;
ok       check( <<'MASSAGE' ,   qw(  tcp  red )) ;
#afa
  
tcp : red
chat: ntro
MASSAGE


__END__
ok      check( <<'MASSAGE' ,   qw(   tcp  red )) ;
#afa

irc   red
tcp : red
chat: ntro
MASSAGE

