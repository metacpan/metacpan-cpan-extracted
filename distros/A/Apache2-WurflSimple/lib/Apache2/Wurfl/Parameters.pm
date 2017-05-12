 package Apache2::Wurfl::Parameters;
  
use strict;
use warnings FATAL => 'all';
  
use Apache::Test;
use Apache::TestUtil;
  
use Apache2::Const -compile => qw(OR_ALL ITERATE);
  
use Apache2::CmdParms ();
use Apache2::Module ();
use Apache2::Directive ();


my @directives = (
  {
    name      =>     'WurflAPIKey'
  }
);

 Apache2::Module::add(__PACKAGE__, \@directives);
 
 sub WurflAPIKey {
     my ($self, $param, $arg) = @_;
     die  sprintf "error: WurflAPIKey expect a value" unless $arg;
     $self->{WurflAPIKey} =  $arg;
     
 }

1;