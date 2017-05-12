
package dev::api_inside_handler;

use strict;
use warnings 'all';
use base 'ASP4::FormHandler';
use vars __PACKAGE__->VARS;
use ASP4::API;

sub run
{
  my ($s, $context) = @_;
  
  my $api = ASP4::API->new();
  my $res = $api->ua->get("/static.txt");
  $Response->Write( $res->content );
}# end run()

1;# return true:

