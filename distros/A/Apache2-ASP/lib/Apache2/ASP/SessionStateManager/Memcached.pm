
package Apache2::ASP::SessionStateManager::Memcached;

use strict;
use warnings 'all';
use base 'Apache2::ASP::SessionStateManager';
use Cache::Memcached;
use Digest::MD5 'md5_hex';


#==============================================================================
sub new
{
  my ($class, %args) = @_;
  
  my $s = bless { }, $class;
  
  # Prepare our Session:
  if( my $id = $s->parse_session_id() )
  {
    if( $s->verify_session_id( $id ) )
    {
      $s->{SessionID} = $id;
      return $s->retrieve( $id );
    }
    else
    {
      $s->{SessionID} = $s->new_session_id();
      $s->write_session_cookie();
      return $s->create( $s->{SessionID} );
    }# end if()
  }
  else
  {
    $s->{SessionID} = $s->new_session_id();
    $s->write_session_cookie();
    return $s->create( $s->{SessionID} );
  }# end if()
}# end new()


#==============================================================================
sub memd
{
  my $s = shift;

  $s->{memd} ||= new Cache::Memcached {
    'servers' => [
      split(/,\s*/, $s->context->config->data_connections->session->dsn )
    ]
  };
  $s->{memd};
}# end memd()


#==============================================================================
sub verify_session_id
{
  my ($s, $SessionID) = @_;
  
  defined( $s->memd->get( $SessionID ) );
}# end verify_session_id()


#==============================================================================
sub retrieve
{
  my ($s, $SessionID) = @_;
  
  my $got = $s->memd->get( $SessionID );
  $got->{memd} = $s->memd;
  $got = bless $got, ref($s) || $s
    unless UNIVERSAL::isa( $got, __PACKAGE__ );
  return $got;
}# end retrieve()


#==============================================================================
sub create
{
  my ($s, $SessionID) = @_;
  
  eval {
    no warnings 'uninitialized';
    $s->{__signature} = md5_hex(
      join ":", 
        map { "$_:$s->{$_}" }
          grep { $_ && $_ !~ m/^(memd|__signature)/ } sort keys(%$s)
    );
  };
  
  $s->memd->set(
    $SessionID => $s,
    $s->context->config->data_connections->session->session_timeout * 60
  );
  $s;
}# end create()


#==============================================================================
sub save
{
  my ($s) = @_;
  
  no warnings 'uninitialized';
  return if eval { $s->{__signature} eq md5_hex(
    join ":", map { "$_:$s->{$_}" }
                grep { $_ && $_ !~ m/^(memd|__signature)/ } sort keys(%$s)
  )};
  eval {
    $s->{__signature} = md5_hex(
      join ":",
        map { "$_:$s->{$_}" } 
          grep { $_ && $_ !~ m/^(memd|__signature)/ } sort keys(%$s)
    );
  };
  
  $s->memd->set(
    $s->{SessionID} => $s,
    $s->context->config->data_connections->session->session_timeout * 60
  );
  1;
}# end save()


1;# return true:

