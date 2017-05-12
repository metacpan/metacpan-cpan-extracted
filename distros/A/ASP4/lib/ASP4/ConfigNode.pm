
package
ASP4::ConfigNode;

use strict;
use warnings 'all';
use Carp 'confess';


sub new
{
  my ($class, $ref) = @_;
  local $SIG{__DIE__} = \&Carp::confess;
  my $s = bless $ref, $class;
  $s->init_keys();
  $s;
}# end new()


sub init_keys
{
  my $s = shift;
  
  foreach my $key ( grep { ref($s->{$_}) eq 'HASH' } keys(%$s) )
  {
    if( $key eq 'web' )
    {
      require ASP4::ConfigNode::Web;
      $s->{$key} = ASP4::ConfigNode::Web->new( $s->{$key} );
    }
    elsif( $key eq 'system' )
    {
      require ASP4::ConfigNode::System;
      $s->{$key} = ASP4::ConfigNode::System->new( $s->{$key} );
    }
    else
    {
      $s->{$key} = __PACKAGE__->new( $s->{$key} );
    }# end if()
  }# end foreach()
}# end init_keys()


sub AUTOLOAD
{
  my $s = shift;
  our $AUTOLOAD;
  my ($name) = $AUTOLOAD =~ m/([^:]+)$/;
  
  confess "Unknown method or property '$name'" unless exists($s->{$name});
  
  # Read-only:
  $s->{$name};
}# end AUTOLOAD()


sub DESTROY
{
  my $s = shift;
  undef(%$s);
}# end DESTROY()

1;# return true:

