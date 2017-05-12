
package Apache2::ASP::ApplicationStateManager;

use strict;
use warnings 'all';
use Storable qw( freeze thaw );
use DBI;
use Scalar::Util 'weaken';
use base 'Ima::DBI';
use Digest::MD5 'md5_hex';

#==============================================================================
sub new
{
  my ($class, %args) = @_;
  
  my $s = bless { }, $class;

  my $conn = $s->context->config->data_connections->application;
  local $^W = 0;
  __PACKAGE__->set_db('Main', $conn->dsn,
    $conn->username,
    $conn->password
  );
  
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
sub context
{
  $Apache2::ASP::HTTPContext::ClassName->current;
}# end context()


#==============================================================================
sub create
{
  my $s = shift;
  
  local $s->db_Main->{AutoCommit} = 1;
  my $sth = $s->db_Main->prepare(<<"");
    INSERT INTO asp_applications (
      application_id,
      application_data
    )
    VALUES (
      ?, ?
    )

  $sth->execute(
    $s->context->config->web->application_name,
    freeze( {} )
  );
  $sth->finish();
  
  return $s->retrieve();
}# end create()


#==============================================================================
sub retrieve
{
  my $s = shift;
  
  my $sth = $s->dbh->prepare_cached(<<"");
    SELECT application_data
    FROM asp_applications
    WHERE application_id = ?

  $sth->execute( $s->context->config->web->application_name );
  my ($data) = $sth->fetchrow;
  $sth->finish();
  
  return unless $data;
  
  $data = thaw($data) || {};
  undef(%$s);
  $s = bless $data, ref($s);
  
  no warnings 'uninitialized';
  $s->{__signature} = md5_hex(
    join ":",
      map { "$_:$s->{$_}" }
        grep { $_ ne '__signature' } sort keys(%$s)
  );
  
  return $s;
}# end retrieve()


#==============================================================================
sub save
{
  my $s = shift;

  no warnings 'uninitialized';
  return if $s->{__signature} eq md5_hex(
    join ":",
      map { "$_:$s->{$_}" }
        grep { $_ ne '__signature' } sort keys(%$s)
  );
  $s->{__signature} = md5_hex(
    join ":",
      map { "$_:$s->{$_}" } 
        grep { $_ ne '__signature' } sort keys(%$s)
  );
  
  local $s->db_Main->{AutoCommit} = 1;
  my $sth = $s->db_Main->prepare_cached(<<"");
    UPDATE asp_applications SET
      application_data = ?
    WHERE application_id = ?

  my $data = { %$s };
  delete($data->{__signature} );
  $sth->execute(
    freeze( $data ),
    $s->context->config->web->application_name
  );
  $sth->finish();
  
  1;
}# end save()


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

Apache2::ASP::ApplicationStateManager - The $Application object

=head1 SYNOPSIS

  # In a handler, ASP script or your GlobalASA:
  $Application->{some_gobal_thing} = "A new value";
  
  # ...then, in all requests to the server...
  my $val = $Application->{some_global_thing};
  
  # You can also store objects:
  $Application->{some_object} = My::Thing->new( ... );
  
  # You can access the current $Application through the context also:
  my $app = Apache2::ASP::HTTPContext->current->application;

=head1 DESCRIPTION

All C<$Application> objects are instances of one or another subclass of
C<Apache2::ASP::ApplicationStateManager>.

C<Apache2::ASP::ApplicationStateManager> is the base class for all ApplicationStateManagers.

The C<$Application> object is implemented as a simple, blessed hash with no special 
magick going on anywhere.  C<$Application> is not a blessed hash and does not 
depend on special semantics, nor does it expect special treatment.

=head2 Storage

By default, when it is time to store the contents of the C<$Application> object
for later retrieval, the venerable L<Storable> module is used.  The resulting
binary blob is stored in the database referred to in the C<data_connections/application>
part of the config.

=head2 Configuration

The C<apache2-asp-config.xml> configuration file should contain a section like the following:

  <?xml version="1.0" ?>
  <config>
    ...
    <data_connections>
      ...
      <application>
        <manager>Apache2::ASP::ApplicationStateManager::SQLite</manager>
        <dsn>DBI:mysql:dbname:hostname</dsn>
        <username>sa</username>
        <password>s3cr3t!</password>
      </application>
      ...
    </data_connections>
    ...
  </config>

=head2 Database Storage

The table that the C<$Application> object is stored in has the following structure:

  CREATE TABLE  asp_applications (
    application_id    varchar(100) NOT NULL,
    application_data  blob,
    PRIMARY KEY  (application_id)
  ) ENGINE=InnoDB DEFAULT CHARSET=latin1;

Different databases will have different ways of spelling that, but the structure is clear.

=head1 PUBLIC METHODS

=head2 save( )

Stores the object in the database.  Returns true.

=head1 BUGS

It's possible that some bugs have found their way into this release.

Use RT L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Apache2-ASP> to submit bug reports.

=head1 HOMEPAGE

Please visit the Apache2::ASP homepage at L<http://www.devstack.com/> to see examples
of Apache2::ASP in action.

=head1 AUTHOR

John Drago L<mailto:jdrago_999@yahoo.com>

=head1 COPYRIGHT AND LICENSE

Copyright 2007 John Drago, All rights reserved.

This software is free software.  It may be used and distributed under the
same terms as Perl itself.

=cut

