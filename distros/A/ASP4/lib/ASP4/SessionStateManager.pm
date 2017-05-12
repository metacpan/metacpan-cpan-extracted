
package ASP4::SessionStateManager;

use strict;
use warnings 'all';
use base 'Ima::DBI::Contextual';
use HTTP::Date qw( time2iso time2str str2time );
use Time::HiRes 'gettimeofday';
use Digest::MD5 'md5_hex';
use Storable qw( freeze thaw );
use Scalar::Util 'weaken';
use ASP4::ConfigLoader;


sub new
{
  my ($class, $r) = @_;
  my $s = bless { }, $class;
  my $conn = context()->config->data_connections->session;
  
  local $^W = 0;
  $class->set_db('Session',
    $conn->dsn,
    $conn->username,
    $conn->password
  );
  
  my $id = $s->parse_session_id();
  unless( $id && $s->verify_session_id( $id, $conn->session_timeout ) )
  {
    $s->{SessionID} = $s->new_session_id();
    $s->write_session_cookie($r);
    return $s->create( $s->{SessionID} );
  }# end unless()
  
  return $s->retrieve( $id );
}# end new()

sub context { ASP4::HTTPContext->current }

sub is_read_only
{
  my ($s, $val) = @_;
  
  if( defined($val) )
  {
    $s->{____is_read_only} = $val;
  }
  else
  {
    return $s->{____is_read_only};
  }# end if()
}# end is_readonly()


sub parse_session_id
{
  my $session_config = context()->config->data_connections->session;
  my $cookie_name = $session_config->cookie_name;
  my ($id) = ($ENV{HTTP_COOKIE}||'') =~ m/\b\Q$cookie_name\E\=([a-f0-9]{32,32})/s;

  return $id;
}# end parse_session_id()


sub new_session_id { md5_hex( join ':', ( context()->config->web->www_root, $$, gettimeofday() ) ) }


sub write_session_cookie
{
  my ($s, $r) = @_;
  
  my $config = context()->config->data_connections->session;
  my $domain = "";
  unless( $config->cookie_domain eq '*' )
  {
    $domain = "domain=" . ( $config->cookie_domain || $ENV{HTTP_HOST} ) . ";";
  }# end unless()
  my $name = $config->cookie_name;
  
  my @cookie = (
    'Set-Cookie' => "$name=$s->{SessionID}; path=/; $domain"
  );
  context()->headers_out->push_header( @cookie );
  @cookie;
}# end write_session_cookie()


sub verify_session_id
{
  my ($s, $id, $timeout ) = @_;
  
  my $is_active;
  if( $timeout eq '*' )
  {
    local $s->db_Session->{AutoCommit} = 1;
    my $sth = $s->db_Session->prepare(<<"");
      SELECT count(*)
      FROM asp_sessions
      WHERE session_id = ?

    $sth->execute( $id );
    ($is_active) = $sth->fetchrow();
    $sth->finish();
  }
  else
  {
    my $range_start = time() - ( $timeout * 60 );
    local $s->db_Session->{AutoCommit} = 1;
    my $sth = $s->db_Session->prepare(<<"");
      SELECT count(*)
      FROM asp_sessions
      WHERE session_id = ?
      AND modified_on - created_on < ?

    $sth->execute( $id, $timeout );
    ($is_active) = $sth->fetchrow();
    $sth->finish();
  }# end if()

  return $is_active;
}# end verify_session_id()


sub create
{
  my ($s, $id) = @_;
  
  local $s->db_Session->{AutoCommit} = 1;
  my $sth = $s->db_Session->prepare_cached(<<"");
    delete from asp_sessions
    where session_id = ?

  $sth->execute( $id );

  $sth = $s->db_Session->prepare_cached(<<"");
    INSERT INTO asp_sessions (
      session_id,
      session_data,
      created_on,
      modified_on
    )
    VALUES (
      ?, ?, ?, ?
    )

  my $time = time();
  my $now = time2iso($time);
  $s->{__lastMod} = $time;
  
  $s->sign();
  
  my %clone = %$s;
  
  $sth->execute(
    $id,
    freeze( \%clone ),
    $now,
    $now,
  );
  $sth->finish();
  
  return $s->retrieve( $id );
}# end create()


sub retrieve
{
  my ($s, $id) = @_;

  local $s->db_Session->{AutoCommit} = 1;
  my $sth = $s->db_Session->prepare_cached(<<"");
    SELECT session_data, modified_on
    FROM asp_sessions
    WHERE session_id = ?

  my $now = time2iso();
  $sth->execute( $id );
  my ($data, $modified_on) = $sth->fetchrow;
  $data = thaw($data) || { SessionID => $id };
  $sth->finish();
  
  $s->{$_} = $data->{$_} for keys %$data;
  
  return $s;
}# end retrieve()


sub save
{
  my ($s) = @_;
  
  return unless $s->{SessionID};
  no warnings 'uninitialized';
#  $s->{__lastMod} = time();
  $s->sign;
  
  local $s->db_Session->{AutoCommit} = 1;
  my $sth = $s->db_Session->prepare_cached(<<"");
    UPDATE asp_sessions SET
      session_data = ?,
      modified_on = ?
    WHERE session_id = ?

  my %clone = %$s;
  delete $clone{____is_read_only};
  my $data = freeze( \%clone );
  
  $sth->execute( $data, time2iso(), $s->{SessionID} );
  $sth->finish();
  
  1;
}# end save()


sub sign
{
  my $s = shift;
  
  $s->{__signature} = $s->_hash;
}# end sign()


sub _hash
{
  my $s = shift;
  
  no warnings 'uninitialized';
  md5_hex(
    join ":", 
      map { "$_:$s->{$_}" }
        grep { $_ ne '__signature' && $_ ne '____is_read_only' } sort keys(%$s)
  );
}# end _hash()


sub is_changed
{
  my $s = shift;
  
  no warnings 'uninitialized';
  $s->_hash ne $s->{__signature};
}# end is_changed()


sub reset
{
  my $s = shift;
  
  delete($s->{$_}) for grep { $_ ne 'SessionID' } keys %$s;
  $s->save;
  return;
}# end reset()


sub DESTROY
{
  my $s = shift;
  
  return undef(%$s) unless $s->{SessionID};
  
  unless( $s->is_read_only )
  {
    $s->save;# if $s->is_changed;
  }# end unless()
  undef(%$s);
}# end DESTROY()

1;# return true:

=pod

=head1 NAME

ASP4::SessionStateManager - Per-user state persistence

=head1 SYNOPSIS

  You've seen this page <%= $Session->{counter}++ %> times before.

=head1 DESCRIPTION

Web applications require session state management - and the simpler, the better.

C<ASP4::SessionStateManager> is a simple blessed hash.  When it goes out of scope,
it is saved to the database (or whatever).

If no changes were made to the session, it is not saved.

=head1 PUBLIC PROPERTIES

=head2 is_read_only( 1:0 )

Starting with version 1.044, setting this property to a true value will prevent
any changes made to the contents of the session during the current request from
being saved at the end of the request.

B<NOTE:> A side-effect is that calling C<< $Session->save() >> after calling C<< $Session->is_read_only(1) >>
will B<*NOT*> prevent changes from being saved B<ON PURPOSE>.  Explicitly calling C<< $Session->save() >>
will still cause the session data to be stored.  Setting C<< $Session->is_read_only(1) >> will only
prevent the default behavior of saving session state at the end of each successful request.

=head1 PUBLIC METHODS

=head2 save( )

Causes the session data to be saved. (Unless C<< $Session->is_read_only(1) >> is set.)

=head2 reset( )

Causes the session data to be emptied.

=head1 BUGS

It's possible that some bugs have found their way into this release.

Use RT L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=ASP4> to submit bug reports.

=head1 HOMEPAGE

Please visit the ASP4 homepage at L<http://0x31337.org/code/> to see examples
of ASP4 in action.

=cut

