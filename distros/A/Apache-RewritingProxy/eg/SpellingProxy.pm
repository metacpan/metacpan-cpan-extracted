package Apache::SpellingProxy;

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
  my $r = shift;
  my $string = shift;
  my %subWords;
  #Simply put common mispellings  in the hash below with their proer
  # spellings and you will have a little proxy that corrects the errors.
  # Not by any means useful, just a 5 minute script to show how different
  # text handlers work.
  $subWords{teh} = 'the';
  $subWords{the the} = 'the';
  $subWords{lousiville} = 'Louisville';
  $subWords{Microsoft} = 'Micro$oft';
  $subWords{Windows} = 'Windoze';

  my $naughty;
  foreach $naughty (sort keys(%subWords))
    {
    $string =~ s/\b$naughty/$subWords{$naughty}/ig;
    }
  return($string);
  }

1;
