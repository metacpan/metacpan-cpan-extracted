
package
ASP4::SessionStateManager::InMemory;

use strict;
use warnings 'all';
use base 'ASP4::SessionStateManager';

my $cache = {};

sub new
{
  my ($class, $r) = @_;
  
  my $id = $class->parse_session_id();
  my $s = bless {SessionID => $id}, $class;
  my $conn = ASP4::ConfigLoader->load->data_connections->session;
  unless( $id && $s->verify_session_id( $id, $conn->session_timeout ) )
  {
    $s->{SessionID} = $s->new_session_id();
    $s->write_session_cookie($r);
    return $s->create( $s->{SessionID} );
  }# end unless()
  
  return $s->retrieve( $id );
}# end new()


sub now { time() }


sub verify_session_id
{
  my ($s, $id, $ttl) = @_;
  
  exists $cache->{$id};
}# end verify_session_id()


sub retrieve
{
  my ($s, $id) = @_;
  
  return $cache->{$id}
    if exists $cache->{$id};
}# end retrieve()


sub create
{
  my ($s, $id) = @_;
  
  $cache->{$id} = $s;
  $s->save;
  return $s;
}# end create()


sub save
{
  my ($s) = @_;
  
  1;
}# end save()


sub reset
{
  my $s = shift;
  
  map { delete($s->{$_}) } grep { $_ ne 'SessionID' } keys %$s;
  $s->save;
  return;
}# end reset()

1;# return true:

