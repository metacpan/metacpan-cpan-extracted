package Apache::UploadSvr::User;

use DBI;
use strict;
use vars qw( $Userref $VERSION );

$Userref = undef;

$VERSION = sprintf "%d.%03d", q$Revision: 1.2 $ =~ /(\d+)\.(\d+)/;

sub new {
  my($class, $caller) = @_;
  my $r = $caller->request;
  my $time = time;
  my $data_source = $r->dir_config('Auth_DBI_data_source');
  my $user_table  = $r->dir_config('Auth_DBI_pwd_table');
  my $user_field  = $r->dir_config('Auth_DBI_uid_field');

  my $userref;
  my $user = $r->connection->user or return {};
  my $db;
  if (exists $Userref->{user} and $Userref->{user} eq $user) {
    return $Userref;
  }
  if ($db = DBI->connect($data_source)) {
    my $sth = $db->prepare(
	    qq{select * from $user_table where $user_field='$user'}
			  ) or die $db->errstr;
    my $rv = $sth->execute;
    $userref = $sth->fetchrow_hashref;
    $sth->finish;
    my $query = "select * from perms where $user_field = '$user'";
    # warn "query[$query]";
    $sth = $db->prepare($query) or die $db->errstr;
    $rv = $sth->execute;
    my $numrows = $sth->rows;
    # warn "rv[$rv] numrows[$numrows]";
    my $permref;
    while ($permref = $sth->fetchrow_hashref) {
      # warn join "*", %$permref;
      push @{$userref->{permitted}}, $permref->{permitted};
      # warn "permitted[@{$userref->{permitted}}]";
    }
    $sth->finish;
  } else {
    die $DBI::errstr;
  }
  my $update = "update $user_table set lastlogin='$time'
                  where $user_field = '$user'";
  my $rv = $db->do($update);
  $db->disconnect;
  warn "rv was not 1. rv[$rv]update[$update]errstr[$DBI::errstr]" unless $rv;
  $Userref = bless $userref, $class;
}

sub has_perms {
  my($self,$f) = @_;
  # warn "f[$f]";
  for my $d (@{$self->{permitted}}) {
    # warn "has_perms d[$d]";
    if (substr($f,0,length($d)) eq $d) {
      return 1;
    }
  }
  return;
}

1;

=head1 NAME

Apache::UploadSvr::User - Identify users and permissions Apache::UploadSvr

=head1 SYNOPSIS

Apache::UploadSvr::User-E<gt>new($mgr);

=head1 DESCRIPTION

This class implements a mapping between user-ID and user attributes.
The backend is provided by a mSQL-1 database with the following structure:

    CREATE TABLE usertable (
      user CHAR(12) NOT NULL PRIMARY KEY,
      email CHAR(64),
      firstname CHAR(32),
      lastname CHAR(32),
      fullname CHAR(64),
      salut CHAR(4),
      lastlogin CHAR(10),
      introduced CHAR(10),
      password CHAR(13),
      changedon CHAR(10),
      changedby CHAR(10)
    )

C<user> corresponds to the username with which the users identify
in the authentication stage. C<email> is their email address where
the transaction tickets are delivered to. C<lastname> is their family name.
<fullname> is whatever the fullname is composed of in the local culture.
C<salut> is the salutation like C<Herr> or C<Mister>. C<lastlogin>
is the timestamp that is updated with every request. C<introduced> is
the timestamp when the user got registered (not used in this uploadserver).
C<password> is the crypted
password in the default upload server. If the authentication handler
uses a different table, then this field is not needed. C<changedon>
and C<changedby> are not used in this application, they are only used as
interesting facts for the administrator.

    CREATE TABLE perms (
      user CHAR(12),
      permitted CHAR(32)
    )

This table has a 1 to N mapping of users to directories they
have write access to.

The constructor -E<gt>new takes as a single argument an
Apache::UploadSvr object and returns an object that has the
above described fields as object attributes. The attribute C<permitted>
is computed from the C<perms> table so that its value is an anonymous
list of the directories the user has write permission to. A typical
structure of such an object would be:

    bless( {
      'introduced' => 875601758,
      'password' => 'rtthXtbR5tjit',
      'fullname' => 'Andreas J. König',
      'changedby' => 'andreas',
      'lastname' => 'König',
      'changedon' => 875601758,
      'email' => 'k',
      'firstname' => 'Andreas',
      'salut' => 'Herr',
      'lastlogin' => '0903739665',
      'permitted' => [
                       '/'
                     ],
      'user' => 'andreas'
    }, 'Apache::UploadSvr::User' )

The method ->has_perms($obj) returns true if the current user has write
access to a file or dircetory. What counts here are database entries,
not file system permissions.

=head1 CONFIGURATION



=head1 SECURITY



=head1 BUGS



=head1 AUTHOR

Andreas Koenig <koenig@kulturbox.de>

=head1 COPYRIGHT, LICENSE

These programs or modules are Copyright (C) 1997-1998 Kulturbox,
Berlin, Germany.

They are free software; you can redistribute them, use and/or modify them
under the same terms as Perl itself.

