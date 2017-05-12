
package Apache2::ASP::ApplicationStateManager::Memcached;

use strict;
use warnings 'all';
use base 'Apache2::ASP::ApplicationStateManager';
use Cache::Memcached;
use Digest::MD5 'md5_hex';


#==============================================================================
sub new
{
  my ($class, %args) = @_;
  
  my $s = bless { }, $class;
  
  if( my $res = $s->retrieve )
  {
    return $res;
  }
  else
  {
    return $s->create;
  }# end if()
}# end new()


#==============================================================================
sub memd
{
  my $s = shift;

  $s->{memd} ||= new Cache::Memcached {
    'servers' => [
      split(/,\s*/, $s->context->config->data_connections->session->dsn )
    ],
    namespace => 'app' . $s->context->config->web->application_name,
  };
  $s->{memd};
}# end memd()


#==============================================================================
sub retrieve
{
  my ($s) = @_;
  
  my $got = $s->memd->get( $s->context->config->web->application_name );
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
          grep { $_ !~ m/^(memd|__signature)/ } sort keys(%$s)
    );
  };
  
  $s->memd->set(
    $s->context->config->web->application_name => $s
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
                grep { $_ !~ m/^(memd|__signature)/ } sort keys(%$s)
  )};
  eval {
    $s->{__signature} = md5_hex(
      join ":",
        map { "$_:$s->{$_}" } 
          grep { $_ !~ m/^(memd|__signature)/ } sort keys(%$s)
    );
  };
  
  $s->memd->set(
    $s->context->config->web->application_name => $s,
  );
  1;
}# end save()


1;# return true:

