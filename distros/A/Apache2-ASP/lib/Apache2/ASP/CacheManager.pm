
package Apache2::ASP::CacheManager;

use strict;
use warnings 'all';
use Digest::MD5 'md5_hex';
use Storable qw( freeze thaw );
use HTTP::Date qw( time2iso str2time );


#==============================================================================
sub new
{
  my ($class, %args) = @_;
  
  return bless \%args, $class;
}# end new()


#==============================================================================
sub context
{
  Apache2::ASP::HTTPContext->current;
}# end context()


#==============================================================================
sub dbh
{
  my $s = shift;
  
  $s->context->application->db_Applications;
}# end dbh()


#==============================================================================
sub create
{

}# end create()


#==============================================================================
sub retrieve
{

}# end retrieve()


#==============================================================================
sub verify_cache_id
{

}# end verify_cache_id()


1;# return true:

