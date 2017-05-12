
package Apache2::ASP::SessionStateManager;

use strict;
use warnings 'all';
use base 'Ima::DBI';
use Digest::MD5 'md5_hex';
use Storable qw( freeze thaw );
use HTTP::Date qw( time2iso str2time );
use Scalar::Util 'weaken';


#==============================================================================
sub new
{
  my ($class, %args) = @_;
  
  my $s = bless {}, $class;
  my $conn = $s->context->config->data_connections->session;
  
  local $^W = 0;
  __PACKAGE__->set_db('Main',
    $conn->dsn,
    $conn->username,
    $conn->password
  );
  
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
sub context
{
  $Apache2::ASP::HTTPContext::ClassName->current;
}# end context()


#==============================================================================
sub parse_session_id
{
  my ($s) = @_;
  
  my $cookiename = $s->context->config->data_connections->session->cookie_name;

  no warnings 'uninitialized';
  if( my ($id) = $ENV{HTTP_COOKIE} =~ m/$cookiename\=([a-f0-9]+)/ )
  {
    return $id;
  }
  elsif( ($id) = $s->context->r->headers_in->{Cookie} =~ m/$cookiename\=([a-f0-9]+)/ )
  {
    return $id;
  }
  else
  {
    return;
  }# end if()
}# end parse_session_id()


#==============================================================================
# Returns true if the session exists and has not timed out:
sub verify_session_id
{
  my ($s, $id) = @_;

  my $range_start = time() - ( $s->context->config->data_connections->session->session_timeout * 60 );
  local $s->db_Main->{AutoCommit} = 1;
  my $sth = $s->db_Main->prepare_cached(<<"");
    SELECT COUNT(*)
    FROM asp_sessions
    WHERE session_id = ?
    AND modified_on BETWEEN ? AND ?

  $sth->execute( $id, time2iso($range_start), time2iso() );
  my ($active) = $sth->fetchrow();
  $sth->finish();
  
  return $active;
}# end verify_session_id()


#==============================================================================
sub create
{
  my ($s, $id) = @_;
  
  local $s->db_Main->{AutoCommit} = 1;
  my $sth = $s->db_Main->prepare_cached(<<"");
    INSERT INTO asp_sessions (
      session_id,
      session_data,
      created_on,
      modified_on
    )
    VALUES (
      ?, ?, ?, ?
    )

  my $now = time2iso();
  
  no warnings 'uninitialized';
  $s->{__signature} = md5_hex(
    join ":", 
      map { "$_:$s->{$_}" }
        grep { $_ ne '__signature' } sort keys(%$s)
  );
  
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


#==============================================================================
sub retrieve
{
  my ($s, $id) = @_;
  
  local $s->db_Main->{AutoCommit} = 1;
  my $sth = $s->db_Main->prepare_cached(<<"");
    SELECT session_data, modified_on
    FROM asp_sessions
    WHERE session_id = ?

  my $now = time2iso();
  $sth->execute( $id );
  my ($data, $modified_on) = $sth->fetchrow;
  $data = thaw($data) || { SessionID => $id };
  $sth->finish();

  my $seconds_since_last_modified = time() - str2time($modified_on);
  my $timeout_seconds = $s->context->config->data_connections->session->session_timeout * 60;
  if( $seconds_since_last_modified >= 1 && $seconds_since_last_modified < $timeout_seconds )
  {
    local $s->db_Main->{AutoCommit} = 1;
    my $sth = $s->db_Main->prepare_cached(<<"");
    UPDATE asp_sessions SET
      modified_on = ?
    WHERE session_id = ?

    $sth->execute( time2iso(), $id );
    $sth->finish();
  }# end if()
  
  undef(%$s);
  $s = bless $data, ref($s);
  weaken($s);
  
  no warnings 'uninitialized';
  
  my @keys = sort keys(%$s);
  
  my $sig = md5_hex(
    join ":",
      map { "$_:$s->{$_}" } 
        grep { $_ ne '__signature' } @keys
  );
  
  $s->{__signature} = $sig;
  
  return $s;
}# end retrieve()


#==============================================================================
sub save
{
  my ($s) = @_;
  
  no warnings 'uninitialized';
  return if $s->{__signature} eq md5_hex(
    join ":", map { "$_:$s->{$_}" }
                grep { $_ ne '__signature' } sort keys(%$s)
  );
  $s->{__signature} = md5_hex(
    join ":",
      map { "$_:$s->{$_}" } 
        grep { $_ ne '__signature' } sort keys(%$s)
  );
  
  local $s->db_Main->{AutoCommit} = 1;
  my $sth = $s->db_Main->prepare_cached(<<"");
    UPDATE asp_sessions SET
      session_data = ?,
      modified_on = ?
    WHERE session_id = ?

  my %clone = %$s;
  my $data = freeze( \%clone );
  $sth->execute( $data, time2iso(), $s->{SessionID} );
  $sth->finish();
  
  1;
}# end save()


#=========================================================================
sub reset
{
  my ($s) = @_;
  
  # Remove everything *but* our important parts:
  my %saves = map { $_ => 1 } qw/ SessionID /;
  delete( $s->{$_} ) foreach grep { ! $saves{$_} } keys(%$s);
  $s->save;
}# end reset()


#==============================================================================
sub new_session_id
{
  my $s = shift;
  md5_hex( $s->context->config->web->application_name . rand() );
}# end new_session_id()


#==============================================================================
sub write_session_cookie
{
  my $s = shift;
  my $state = $s->context->config->data_connections->session;
  my $cookiename = $state->cookie_name;
  my $domain = eval { $state->cookie_domain } ? " domain=" . $state->cookie_domain . ";" : "";
  $s->context->r->err_headers_out->{'Set-Cookie'} = "$cookiename=$s->{SessionID}; path=/; $domain";
  
  # If we weren't given an HTTP cookie value, set it here.
  # This prevents subsequent calls to 'parse_session_id()' to fail:
  $ENV{HTTP_COOKIE} ||= '';
  if( $ENV{HTTP_COOKIE} !~ m/\b$cookiename\=.*?\b/ )
  {
    my @cookies = split /;/, $ENV{HTTP_COOKIE};
    push @cookies, "$cookiename=$s->{SessionID}";
    $ENV{HTTP_COOKIE} = join ';', @cookies;
  }# end if()
  
  1;
}# end write_session_cookie()


#==============================================================================
sub dbh
{
  my $s = shift;
  return $s->db_Main;
}# end dbh()


#==============================================================================
sub DESTROY
{
  my $s = shift;
  
  delete($s->{$_}) foreach keys(%$s);
}# end DESTROY()

1;# return true:

__END__

=pod

=head1 NAME

Apache2::ASP::SessionStateManager - Base class for Session State Managers.

=head1 SYNOPSIS

Within your ASP script:

  <%
    $Session->{counter}++;
    $Response->Write("You have viewed this page $Session->{counter} times.");
  %>

=head1 DESCRIPTION

The global C<$Session> object is an instance of C<Apache2::ASP::SessionStateManager>
or one of its subclasses.

It is a blessed hash that is persisted to a database.  Use it to share information across all requests for
one user.

B<NOTE:> - do not store database connections or filehandles within the C<$Session> object because they cannot be shared across
different processes or threads.

=head1 METHODS

=head2 save( )

Stores the Session object in the database.  Returns true.

=head1 CONFIGURATION

=head2 XML Config

The file C<apache2-asp-config.xml> should contain a section like the following:

  <?xml version="1.0"?>
  <config>
    ...
    <data_connections>
      ...
      <session>
        <manager>Apache2::ASP::SessionStateManager::MySQL</manager>
        <cookie_name>session-id</cookie_name>
        <cookie_domain>.example.com</cookie_domain>
        <dsn>DBI:mysql:dbname:localhost</dsn>
        <username>sa</username>
        <password>s3cr3t!</password>
        <session_timeout>30</session_timeout>
      </session>
      ...
    </data_connections>
    ...
  </config>

=head2 Database Storage

The database named in the XML config file should contain a table like the following:

  CREATE TABLE  asp_sessions (
    session_id    char(32) NOT NULL,
    session_data  blob,
    created_on    datetime default NULL,
    modified_on   datetime default NULL,
    PRIMARY KEY  (session_id)
  ) ENGINE=InnoDB DEFAULT CHARSET=latin1

=head1 BUGS

It's possible that some bugs have found their way into this release.

Use RT L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Apache2-ASP> to submit bug reports.

=head1 HOMEPAGE

Please visit the Apache2::ASP homepage at L<http://www.devstack.com/> to see examples
of Apache2::ASP in action.

=head1 AUTHOR

John Drago <jdrago_999@yahoo.com>

=head1 COPYRIGHT AND LICENSE

Copyright 2007 John Drago, All rights reserved.

This software is free software.  It may be used and distributed under the
same terms as Perl itself.

=cut

