
package Apache2::ASP::ASPDOM::Node;

use strict;
use warnings 'all';
use Carp 'confess';
use Scalar::Util 'weaken';


#==============================================================================
sub new
{
  my ($class, %args) = @_;
  
  my $s = bless {
    %args,
    childNodes          => [ ],
    events => {
      before_appendChild  => [ ],
      after_appendChild   => [ ],
    },
  }, $class;
  weaken($s->{parentNode}) if $s->{parentNode};
  return $s;
}# end new()


#==============================================================================
sub id { $_[0]->{id} }
sub tagName { $_[0]->{tagName} }


#==============================================================================
sub addHandler
{
  my ($s, $event, $code) = @_;
  
  confess "Unknown event '$event'" unless exists($s->{events}->{$event});
  
  return if grep { "$_" eq "$code" } @{$s->{events}->{$event}};
  push @{$s->{events}->{$event}}, $code;
}# end addHandler()


#==============================================================================
sub removeHandler
{
  my ($s, $event, $code) = @_;
  
  confess "Unknown event '$event'" unless exists($s->{events}->{$event});
  
  for( 0...@{$s->{events}->{$event}} - 1 )
  {
    splice( @{$s->{events}->{$event}}, $_, 1 )
      if "$s->{events}->{$event}->[$_]" eq "$code";
  }# end for()
}# end addHandler()


#==============================================================================
sub childNodes
{
  @{$_[0]->{childNodes}} or return;
  @{$_[0]->{childNodes}}
}# end childNodes()


#==============================================================================
sub parentNode
{
  my $s = shift;
  
  @_ ? weaken($s->{parentNode} = shift) : $s->{parentNode};
}# end parentNode()


#==============================================================================
sub appendChild
{
  my ($s, $child) = @_;
  
  # Call "before" handlers?
  foreach( @{$s->{events}->{before_appendChild}} )
  {
    local $SIG{__DIE__} = \&confess;
    $_->( $s, $child );
  }# end foreach()
  
  # Add the child:
  $child->parentNode( $s );
  push @{$s->{childNodes}}, $child;
  
  # Call "after" handlers?:
  foreach( @{$s->{events}->{after_appendChild}} )
  {
    local $SIG{__DIE__} = \&confess;
    $_->( $s, $child );
  }# end foreach()
  
  $child;
}# end appendChild()


#==============================================================================
sub removeChild
{
  my ($s, $child) = @_;
  
  for( 0...@{$s->{childNodes}} - 1 )
  {
    if( "$s->{childNodes}->[$_]" eq "$child" )
    {
      splice( @{$s->{childNodes}}, $_, 1 );
      last;
    }# end if()
  }# end for()
}# end removeChild()


#==============================================================================
sub getElementById
{
  my ($s, $id) = @_;
  
  my ($match) = grep {
    $_->id eq $id
  } $s->childNodes;
  
  return $match if $match;
  
  foreach my $child ( $s->childNodes )
  {
    $match = $child->getElementById( $id );
    return $match if $match;
  }# end foreach()
}# end getElementById()

1;# return true:

__END__

$doc->getElementById("div1")->addHandler( before_appendChild => sub {
  my ($self, $child) = @_;
  
});




