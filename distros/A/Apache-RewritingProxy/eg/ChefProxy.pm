package Apache::ChefProxy;

use strict;
use vars qw(@ISA);
use Apache::RewritingProxy;
@ISA = qw(Apache::RewritingProxy);

  
sub handler
  {
  my $r = shift;
  Apache::RewritingProxy::handler($r,\&textHandler);
  }
  

sub textHandler
  {
  # This is a half-assed rip-off of chef.x- by John Hagerman.
  # The original was a working piece of lex code that turned English into
  # Mock Swedish in the genre of the Swewdish Chef from the Muppets.
  # This code doesn't really work.
  # I just ran some stupid sed on the lex stuff and dumped it in here
  # as is.  All it does is butcher the text.
  # It does give an example of another texthandler that can be 
  # used with RewritingProxy; however.
  my %subWords;
  $subWords{an} = 'un';
  $subWords{An} =         "Un"; 
  $subWords{au} =         "oo"; 
  $subWords{Au} =         "Oo"; 
  $subWords{a} =       "e"; 
  $subWords{A}  =      "E"; 
  $subWords{ew} =    "oo"; 
  $subWords{e}  = "e-a"; 
  $subWords{e} =     "i"; 
  $subWords{E} =     "I"; 
  $subWords{f} =     "ff"; 
  $subWords{ir} =    "ur"; 
  $subWords{ow} =    "oo"; 
  $subWords{o} =     "oo"; 
  $subWords{O} =     "Oo"; 
  $subWords{o} =     "u"; 
  $subWords{the} =        "zee"; 
  $subWords{The} =        "Zee"; 
  $subWords{th}  =     "t"; 
  $subWords{tion} =  "shun"; 
  $subWords{u} =     "oo"; 
  $subWords{U} =     "Oo"; 
  $subWords{v} =          "f"; 
  $subWords{V} =          "F"; 
  $subWords{w} =          "v"; 
  $subWords{W} =          "V"; 

  my $r = shift;
  my $string = shift;
  my $old;
  foreach $old (sort keys(%subWords))
    {
    $string =~ s/$old/$subWords{$old}/g;
    }
    
  return($string);
  }
  

1;
