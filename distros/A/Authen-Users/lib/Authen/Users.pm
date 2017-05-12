package Authen::Users;

require 5.004;

use strict;
use warnings;
use Carp;
use DBI;
use Digest::SHA qw(sha1_base64 sha256_base64 sha384_base64 sha512_base64);
use vars qw($VERSION);
$VERSION = '0.17';

sub new {
    my ( $class, %args ) = @_;
    my $self = {};
    bless( $self, $class );
    foreach
      my $k (qw( dbtype dbname create dbuser dbpass dbhost authen_table digest))
    {
        $self->{$k} = $args{$k} if $args{$k};
    }
    $self->{dbname}
      or croak "Cannot set up Auth::Users without a dbname: $self->{dbname}.";
    $self->{dbtype} = 'SQLite' unless $self->{dbtype};
    $self->{authentication} = $self->{authen_table} || 'authentication';
    $self->{make_salt} = 1 unless $args{NO_SALT};
    my $algo = $self->{digest} || 1;
    if ( $algo == 256 ) {
        $self->{sha} = sub { sha256_base64(shift) }
    }
    elsif ( $algo == 384 ) {
        $self->{sha} = sub { sha384_base64(shift) }
    }
    elsif ( $algo == 512 ) {
        $self->{sha} = sub { sha512_base64(shift) }
    }
    else {
        $self->{sha} = sub { sha1_base64(shift) }
    }
    $self->{_error} = '';    # internal error message used by error() func
    $self->{sqlparams} = { PrintError => 0, RaiseError => 1, AutoCommit => 1 };
    if ( $self->{dbtype} =~ /^MySQL/i ) {

        # MySQL
        $self->{dsn} = "dbi:mysql:database=$self->{dbname}";
        $self->{dsn} .= ";host=$self->{dbhost}" if $self->{dbhost};
        $self->{dbh} = DBI->connect(
            $self->{dsn},    $self->{dbuser},
            $self->{dbpass}, $self->{sqlparams}
          )
          or croak "Can't connect to MySQL database as $self->{dsn} with "
          . "user $self->{dbuser} and given password and $self->{sqlparams}: "
          . DBI->errstr;
    }
    else {

        # SQLite is the default
        $self->{dsn} = "dbi:SQLite:dbname=$self->{dbname}";
        $self->{dbh} = DBI->connect( $self->{dsn}, $self->{sqlparams} )
          or croak "Can't connect to SQLite database as $self->{dsn} with "
          . "$self->{sqlparams}: "
          . DBI->errstr;
    }

    # check if table exists
    my $sth_tab = $self->{dbh}->table_info();
    my $need_table = 1;
    while ( my $tbl = $sth_tab->fetchrow_hashref ) {
        $need_table = 0 if $tbl->{TABLE_NAME} eq $self->{authentication};
    }
    if ($need_table) {
        unless ( $self->{create} ) {
            croak
"No table in database, and create not specified for new Authen::Users";
        }

        # try to create the table
        my $ok_create = $self->{dbh}->do(<<ST_H);
CREATE TABLE $self->{authentication} 
( groop VARCHAR(15), user VARCHAR(30), password VARCHAR(60),
fullname VARCHAR(40), email VARCHAR(40), question VARCHAR(120),
answer VARCHAR(80), created VARCHAR(12), modified VARCHAR(12), 
pw_timestamp VARCHAR(12), salt VARCHAR(10), gukey VARCHAR (46) UNIQUE )
ST_H
        carp("Could not make table") unless $ok_create;
    }
    return $self;
}

sub authenticate {
    my ( $self, $group, $user, $password ) = @_;
    my $password_sth = $self->{dbh}->prepare(<<ST_H);
SELECT password, salt FROM $self->{authentication} WHERE groop = ? AND user = ? 
ST_H
    $password_sth->execute( $group, $user );
    my $row = $password_sth->fetchrow_arrayref;
    if ($row) {
        my $stored_pw_digest = $row->[0];
        my $salt = $row->[1];
        my $user_pw_digest   = ($salt)
          ?  $self->{sha}->($password, $salt)
          :  $self->{sha}->($password);
        return 1 if $user_pw_digest eq $stored_pw_digest;
    }
    return;
}

sub add_user {
    my ( $self, $group, $user, $password, $fullname, $email, $question,
        $answer ) = @_;
    $self->validate( $group, $user, $password ) or return;
    $self->not_in_table( $group, $user ) or return;
    my $r;
    my $salt = 0;
    if($self->{make_salt}) {
		$salt = $self->{sha}->( time + rand(10000) );
		$salt = substr( $salt, -8 );
		my $password_sha = $self->{sha}->($password, $salt); 
        my $insert_sth = $self->{dbh}->prepare(<<ST_H);
INSERT INTO $self->{authentication} 
(groop, user, password, fullname, email, question, answer, 
created, modified, pw_timestamp, salt, gukey)
VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?) 
ST_H
       my $t = time;
       $r = $insert_sth->execute( $group, $user, $password_sha,
        $fullname, $email, $question, $answer, $t, $t, $t, $salt,
        _g_u_key( $group, $user ) );
    }
    else {
		my $password_sha = $self->{sha}->($password); 
        my $insert_sth = $self->{dbh}->prepare(<<ST_H);
INSERT INTO $self->{authentication} 
(groop, user, password, fullname, email, question, answer, 
created, modified, pw_timestamp, gukey)
VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?) 
ST_H
       my $t = time;
       $r = $insert_sth->execute( $group, $user, $password_sha,
        $fullname, $email, $question, $answer, $t, $t, $t,
        _g_u_key( $group, $user ) );
	}
    return 1 if $r and $r == 1;
    $self->{_error} = $self->{dbh}->errstr;
    return;
}

sub user_add { shift->add_user(@_) }

sub update_user_all {
    my ( $self, $group, $user, $password, $fullname, $email, $question,
        $answer ) = @_;
    $self->validate( $group, $user, $password ) or return;
    my $salt = 0;
    if($self->{make_salt}) {
		$salt = $self->{sha}->( time + rand(10000) );
		$salt = substr( $salt, -8 );
		my $password_sha = $self->{sha}->($password, $salt);
		my $update_all_sth = $self->{dbh}->prepare(<<ST_H);
UPDATE $self->{authentication} SET password = ?, fullname = ?, email = ?, 
question = ?, answer = ? , modified = ?, pw_timestamp = ?, salt = ?, gukey = ?
WHERE groop = ? AND user = ? 
ST_H
		my $t = time;
		return 1
		if $update_all_sth->execute(
          $password_sha, $fullname, $email, $question, $answer, 
          $t, $t, $salt, _g_u_key( $group, $user ), $group, $user
		);
    }
    else {
		my $password_sha = $self->{sha}->{password};
		my $update_all_sth = $self->{dbh}->prepare(<<ST_H);
UPDATE $self->{authentication} SET password = ?, fullname = ?, email = ?, 
question = ?, answer = ? , modified = ?, pw_timestamp = ?, gukey = ?
WHERE groop = ? AND user = ? 
ST_H
		my $t = time;
		return 1
		  if $update_all_sth->execute(
          $password_sha, $fullname, $email, $question, $answer, 
          $t, $t, _g_u_key( $group, $user ), $group, $user
		);
	}
    return;
}

sub update_user_password {
    my ( $self, $group, $user, $password ) = @_;
    $self->validate( $group, $user, $password ) or return;
    my $salt = 0;
    if($self->{make_salt}) {
		$salt = $self->{sha}->( time + rand(10000) );
		$salt = substr( $salt, -8 );
		my $password_sha = $self->{sha}->($password, $salt);
		my $update_pw_sth = $self->{dbh}->prepare(<<ST_H);
UPDATE $self->{authentication} SET password = ?, modified = ?, pw_timestamp = ?,
  salt = ?
WHERE groop = ? AND user = ? 
ST_H
		my $t = time;
		return 1
		  if $update_pw_sth->execute( $password_sha, 
			$t, $t, $salt, $group, $user );
    }
    else {
		my $password_sha = $self->{sha}->{password};
		my $update_pw_sth = $self->{dbh}->prepare(<<ST_H);
UPDATE $self->{authentication} SET password = ?, modified = ?, pw_timestamp = ?
WHERE groop = ? AND user = ? 
ST_H
		my $t = time;
		return 1
		if $update_pw_sth->execute( $password_sha, 
          $t, $t, $group, $user );
	}
    return;
}

sub update_user_fullname {
    my ( $self, $group, $user, $fullname ) = @_;
    my $update_fullname_sth = $self->{dbh}->prepare(<<ST_H);
UPDATE $self->{authentication} SET fullname = ?, modified = ?,
WHERE groop = ? AND user = ? 
ST_H
    my $t = time;
    return 1 if $update_fullname_sth->execute( $fullname, $t, $group, $user );
    return;
}

sub update_user_email {
    my ( $self, $group, $user, $email ) = @_;
    my $update_email_sth = $self->{dbh}->prepare(<<ST_H);
UPDATE $self->{authentication} SET email = ? , modified = ?,
WHERE groop = ? AND user = ? 
ST_H
    my $t = time;
    return 1 if $update_email_sth->execute( $email, $t, $group, $user );
    return;
}

sub update_user_question_answer {
    my ( $self, $group, $user, $question, $answer ) = @_;
    my $update_additional_sth = $self->{dbh}->prepare(<<ST_H);
UPDATE $self->{authentication} SET question = ?, answer = ? , 
modified = ? WHERE groop = ? AND user = ? 
ST_H
    my $t = time;
    return 1
      if $update_additional_sth->execute( $question, $answer, $t, $group,
        $user );
    return;
}

sub delete_user {
    my ( $self, $group, $user ) = @_;
    my $delete_sth = $self->{dbh}->prepare(<<ST_H);
DELETE FROM $self->{authentication} WHERE groop = ? AND user = ? 
ST_H
    return 1 if $delete_sth->execute( $group, $user );
    return;
}

sub count_group {
    my ( $self, $group ) = @_;
    my $count_sth = $self->{dbh}->prepare(<<ST_H);
SELECT COUNT(password) FROM $self->{authentication} WHERE groop = ? 
ST_H
    $count_sth->execute($group);
    my $nrows = $count_sth->fetchrow_arrayref->[0];
    $nrows = 0 if $nrows < 0;
    return $nrows;
}

sub get_group_members {
    my ( $self, $group ) = @_;
    my ( $row, @members );
    my $members_sth = $self->{dbh}->prepare(<<ST_H);
SELECT user FROM $self->{authentication} WHERE groop = ? 
ST_H
    $members_sth->execute($group);
    while ( $row = $members_sth->fetch ) { push @members, $row->[0] }
    return \@members;
}

sub user_info {

    # returns an arrayref:
    # [ groop, user, password, fullname, email,
    #        question, answer, created, modified, pw_timestamp, salt, gukey ]
    my ( $self, $group, $user ) = @_;
    my $user_sth = $self->{dbh}->prepare(<<ST_H);
SELECT * FROM $self->{authentication} WHERE groop = ? AND user = ? 
ST_H
    $user_sth->execute( $group, $user );
    return $user_sth->fetch;
}

sub user_info_hashref {

    # returns a hashref:
    # {groop => $group, user => $user, password => $password, etc. }
    my ( $self, $group, $user ) = @_;
    my $user_sth = $self->{dbh}->prepare(<<ST_H);
SELECT * FROM $self->{authentication} WHERE groop = ? AND user = ? 
ST_H
    $user_sth->execute( $group, $user );
    return $user_sth->fetchrow_hashref;
}

sub get_user_fullname {
    my ( $self, $group, $user ) = @_;
    my $row = $self->user_info( $group, $user );
    return $row->[3] if $row;
    return;
}

sub get_user_email {
    my ( $self, $group, $user ) = @_;
    my $row = $self->user_info( $group, $user );
    return $row->[4] if $row;
    return;
}

sub get_user_question_answer {
    my ( $self, $group, $user ) = @_;
    my $row = $self->user_info( $group, $user );
    return ( $row->[5], $row->[6] ) if $row;
    return;
}

sub get_password_change_time {
    my ( $self, $group, $user ) = @_;
    my $row = $self->user_info( $group, $user );
    return $row->[9] if $row;
    return;
}

sub errstr {
    my $self = shift;
    return $self->{dbh}->errstr;
}

sub error {
    my $self = shift;
    return $self->{_error} || $self->{dbh}->errstr;
}

# validation routine for adding users, etc.
sub validate {
    my ( $self, $group, $user, $password ) = @_;
    unless ($group) {
        $self->{_error} = "Group is not defined.";
        return;
    }
    unless ($user) {
        $self->{_error} = "Username is not defined.";
        return;
    }
    unless ($password) {
        $self->{_error} = "Password is not defined.";
        return;
    }
    return 1;
}

# assistance functions

sub not_in_table {
    my ( $self, $group, $user ) = @_;
    my $unique_sth = $self->{dbh}->prepare(<<ST_H);
SELECT password FROM $self->{authentication} WHERE gukey = ? 
ST_H
    $unique_sth->execute( _g_u_key( $group, $user ) );
    my @row = $unique_sth->fetchrow_array;
    return if @row;
    return 1;
}

sub is_in_table {
    my ( $self, $group, $user ) = @_;
    return if $self->not_in_table( $group, $user );
    return 1;
}

#end of public interface
# internal use--not for object use (no $self argument)

sub _g_u_key {
    my ( $group, $user ) = @_;
    return $group . '|' . $user;
}

=head1 NAME

Authen::Users - DBI Based User Authentication

=head1 DESCRIPTION

General password authentication using DBI-capable databases. Currently supports
MySQL and SQLite databases. The default is to use a SQLite database to store 
and access user information. 

This module is not an authentication protocol. For that see something such as
Authen::AuthenDBI.

=head1 RATIONALE

After several web sites were written which required ongoing DBI or .htpassword 
file tweaking for user authentication, it seemed we needed a default user 
password database that would contain not only the user name and password but 
also such things as the information needed to reset lost passwords. 
Thus, this module, designed to be as much as possible a drop-in for your
website authorization scripting needs.

=head1 SYNOPSIS

use Authen::Users;

my $authen = new Athen::Users(dbtype => 'SQLite', dbname => 'mydbname');

// for backward compatibility use the call below:
my $authen = new Athen::Users(
  dbtype => 'SQLite', dbname => 'mydbname', NO_SALT => 1 );


my $a_ok = $authen->authenticate($group, $user, $password);

my $result = $authen->add_user(
    $group, $user, $password, $fullname, $email, $question, $answer);

=head1 METHODS

=over 4

=item B<new>

Create a new Authen::Users object.

my $authen = new Authen::Users(dbname => 'Authentication');

=over 4

Defaults are dbname => SQLIte, authen_table => authentication, 
create => 0 (off), digest => SHA1.

=back

my $authen = new Authen::Users( dbtype => 'SQLite', dbname => 'authen.db', 
  create => 1, authen_table => 'authen_table', digest => 512 );

my $authen = new Authen::Users( 
  dbtype => 'MySQL', dbname => 'authen.db', 
  dbpass => 'myPW', authen_table => 'authen_table', 
  dbhost => 'mysql.server.org', digest => 256 );

Takes a hash of arguments:

=over 4

=item B<dbtype>

The type of database. Currently supports 'SQLite' and 'MySQL'. 
Defaults to SQLite.

=item B<dbname>

The name of the database. Required for all database types.

=item B<authen_table>

The name of the table containing the user data. 
  
  
NOTE: If this is omitted, defaults to a table called 'authentication' in the
database. If the argument 'create' is passed with a true value, and the 
authen_table argument is omitted, then a new empty table called 'authentication' 
will be created in the database. 

The SQL compatible table is currently as follows:

=over 8

=item C<groop VARCHAR(15)>
 
Group of the user. This may signify authorization (trust) level, or could
be used to allow one authorization database to serve several applications 
or sites. 

=item C<user VARCHAR(30)>
 
User name

=item C<password VARCHAR(60)>

Password, as SHA digest

=item C<fullname VARCHAR(40)>

Full name of user

=item C<email VARCHAR(40)>

User email

=item C<question VARCHAR(120)>

Challenge question

=item C<answer VARCHAR(80)>   

Challenge answer

=item C<creation VARCHAR(12)>     

Row insertion timestamp

=item C<modified VARCHAR(12)>

Row modification timestamp

=item C<pw_timestamp VARCHAR(12)>

Password modification timestamp

=item C<gukey VARCHAR (46)>

Internal use: key made of user and group--kept unique

=back

=over 4  
  
For convenience, the database has fields to store for each user an email 
address and a question and answer for user verification if a password is lost.

=back

=item B<create>

If true in value, causes the named authen_table to be created if it was not 
already present when the database was opened.

=item B<dbpass>

The password for the account. Not used by SQLite. Sometimes needed otherwise.

=item B<dbhost>

The name of the host for the database. Not used by SQLite. 
Needed if the database is hosted on a remote server.

=item B<digest>

The algorithm used for the SHA digest. Currently supports SHA1 and SHA2. 
B<Defaults> to SHA1. Supported values are 1 for SHA1, 256 for SHA-256, 
384 for SHA-384, and 512 for SHA-512. See documentation for Digest::SHA for 
more information. Given that in most cases SHA1 is much more random than most 
user-typed passwords, any of the above algorithms should be more than 
sufficient, since most attacks on passwords would likely be dictionary-based, 
not purely brute force. In recognition that some uses of the package might use 
long, random passwords, there is the option of up to 512-bit SHA2 digests.

=back

=item B<BREAK WITH BACKWARD COMPATIBILITY IN VERSION 0.16 AND ABOVE>

In version 0.16 and above, a random salt is added to the digest in order
to partially defeat hacking passwords with pre-computed rainbow tables.
To use later versions of Authen::Users with older SQL tables created by
previous versions, you MUST specify the named parameter NO_SALT => 1
in your call to new.

=item B<OBJECT METHODS>

=item B<authenticate>

Authenticate a user. Users may have the same user name as long as they are not 
also in the same authentication group. Therefore, the user's group should be 
included in all calls to authenticate the user by password. Passwords are
stored as SHA digests, so the authentication is of the digests.

=item B<add_user>

=item B<user_add>


Add a user to the database. Synonym: B<user_add>.

The arguments are as follows:

$authen->add_user($group, $user, $password, $fullname, $email, $question, $answer)
  or die $authen->error;

=over 4

=item B<group>
Scalar. The group of users. Used to classify authorizations, etc. 
User names may be the same if the groups are different, but in any given group 
the users must have unique names.

=item B<user>

Scalar. User name.

=item B<password>

Scalar. SHA digest of user's password.

=item B<fullname>

Scalar. The user's 'real' or full name.

=item B<email>

Scalar. User's email address.

=item B<question>

Scalar. A question used, for example,  for identifying the user if they lose their password.

=item B<answer>

Scalar. The correct answer to $question.

=back

Note: it is up to the user of the module to determine how the fields after group, user, and 
password fields are used, or if they are used at all.

=item B<update_user_all>

Update all fields for a given group and user:

$authen->update_user_all($group, $user, $password, $fullname, $email, $question, $answer) or die "Could not update $user: " . $authen->errstr();

=item B<update_user_password>

$authen->update_user_password($group, $user, $password) 
  or die "Cannot update password for group $group and user $user: $authen->errstr";

Update the password. 

=item B<update_user_fullname>

$authen->update_user_fullname($group, $user, $fullname) 
  or die "Cannot update fullname for group $group and user $user: $authen->errstr";

Update the full name. 

=item B<update_user_email>

$authen->update_user_email($group, $user, $email) 
  or die "Cannot update email for group $group and user $user: $authen->errstr";

Update the email address. 

=item B<update_user_question_answer>

$authen->update_user_question_answer($group, $user, $question, $answer) or die "Cannot update question and answer for group $group and user $user: $authen->errstr";

Update the challenge question and its answer. 

=item B<delete_user>

$authen->delete_user($group, $user) or die "Cannot delete user in group $group with username $user: $authen->errstr";

Delete the user entry. 

=item B<count_group>

$authen->count_group($group) or die "Cannot count group $group: $authen->errstr";

Return the number of entries in group $group. 

=item B<get_group_members>

$authen->get_group_members($group) or die "Cannot retrieve list of group $group: $authen->errstr";

Return a reference to a list of the user members of group $group. 

=item B<user_info>

$authen->user_info($group, $user) or die "Cannot retrieve information about $user in group $group: $authen->errstr";

Return a reference to a list of the information about $user in $group. 

=item B<user_info_hashref>

my $href = $authen->user_info_hashref($group, $user) or die "Cannot retrieve information about $user in group $group: $authen->errstr";
print "The email for $user in $group is $href->{email}";

Return a reference to a hash of the information about $user in $group, with the field 
names as keys of the hash.

=item B<get_user_fullname>

$authen->get_user_fullname($group, $user) or die "Cannot retrieve full name of $user in group $group: $authen->errstr";

Return the user full name entry. 

=item B<get_user_email>

$authen->get_user_email($group, $user) or die "Cannot retrieve email of $user in group $group: $authen->errstr";

Return the user email entry. 

=item B<get_user_question_answer>

$authen->get_user_question_answer($group, $user) or die "Cannot retrieve question and answer for $user in group $group: $authen->errstr";

Return the user question and answer entries. 

=item B<get_password_change_time> 

$authen->get_password_change_time($group, $user) 
    or die "Cannot retrieve password timestamp for $user in group $group: $authen->errstr";

There is a timestamp associated with changes in passwords. This may be used to
expire passwords that need to be periodically changed. The logic used to do 
password expiration, if any, is up to the code using the module.

=item B<errstr>

print $auth->errstr();

Returns the last database error, if any.

=item B<error>

print $auth->error;

Returns the last class internal error message, if any; if none, returns the 
last database DBI error, if any.

=item B<not_in_table>

$auth->not_in_table($group, $user);

True if $user in group $group is NOT already an entry. 
Useful to rule out an existing user name when adding a user.

=item B<is_in_table>

$auth->is_in_table($group, $user);

True if $user in group $group is already in the database.

=item B<validate>

$auth->validate($group, $user, $password);

True if the item is a valid entry;  internal use

=back

=head1 BUGS

On installation, "make test" may fail if Perl support for MySql or SQLite is 
installed, but the database itself is not running or is otherwise not available
for use by the installing user. MySql by default has a 'test' database which is 
required under "make test." "Forcing" installation may work around this.

=head1 AUTHOR

William Herrera (wherrera@skylightview.com)

=head1 SUPPORT

Questions, feature requests and bug reports should go to wherrera@skylightview.com

=head1 COPYRIGHT

     Copyright (C) 2004, 2008 William Hererra.  All Rights Reserved.

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
