
package Apache2::ASP::Test::UploadObject;

use strict;
use warnings 'all';

sub new
{
  my $class = shift;
  return bless { @_ }, $class;
}# end new()


sub AUTOLOAD
{
  my $s = shift;
  our $AUTOLOAD;
  
  my ($key) = $AUTOLOAD =~ m/::([^:]+)$/;
  if( @_ )
  {
    return $s->{$key} = shift(@_);
  }
  else
  {
    return $s->{$key};
  }# end if()
}# end AUTOLOAD()

1;# return true:


