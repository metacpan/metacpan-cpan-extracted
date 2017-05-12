
#########################

use Test;
BEGIN { plan tests => 7 };
use AutoSession;
ok(1); # If we made it this far, we're ok.

#########################

  my $SESSION = AutoSession->new(
  id        => 'IDFOO' ,
  driver    => 'file' ,
  directory => './' ,
  expire    => 60*60*24 ,
  #base64    => 1 ,
  ) ;

  ok( ref($$SESSION->{driver}) , 'AutoSession::Driver::File');
    
  ## Ensure that the session is clean/new (withoout keys).
  ## This will delete existent keys:
  $SESSION->clean ;
  
  ## the session id:
  my $id = $SESSION->id ;
  ok($id , 'IDFOO');
  
  ## The file path of the session (Drive file):
  my $file = $SESSION->local ;
  ok($file , './SESSION-IDFOO.tmp');
  
  ## Create/set the keys
  $SESSION->{key1} = 'k1' ;
  $SESSION->{key2} = 'k2' ;
  
  ok($SESSION->{key1} , 'k1');
  ok($SESSION->{key2} , 'k2');

  $SESSION->{sub0}{sub1} = 'sb01' ;
  $SESSION->save ;
  $SESSION->load ;
  
  ok($SESSION->{sub0}{sub1} , 'sb01');

  $SESSION->delete ;

#########################

