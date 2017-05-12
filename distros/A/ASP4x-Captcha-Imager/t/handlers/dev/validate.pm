
package dev::validate;

use strict;
use warnings 'all';
use base 'ASP4::FormHandler';
use vars __PACKAGE__->VARS;
use Digest::MD5 'md5_hex';

sub run
{
  my ($s, $context) = @_;
  
  my $secret = $Config->system->settings->captcha_key;
  my $code = lc($Form->{security_code});
  
  # It should exist in the session and have the correct value:
  if( exists($Session->{asp4captcha}->{$code}) && md5_hex($code . $secret) eq $Session->{asp4captcha}->{$code} )
  {
    $Response->Write("CORRECT");
  }
  else
  {
    # Bzzzzzzzzzzt: WRONG!
    $Response->Write("WRONG");
  }# end if()
}# end run()

1;# return true:

