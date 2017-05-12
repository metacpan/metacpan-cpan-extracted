#
#    UserDB.pm - User and Group Management Interface.
#
#    This file is part of DBIx::SearchProfiles.
#
#    Author: Francis J. Lacoste <francis.lacoste@iNsu.COM>
#
#    Copyright (C) 1999 Francis J. Lacoste, iNsu Innovations
#
#    This program is free software; you can redistribute it and/or modify
#    it under the terms same terms as perl itself.
#
package DBIx::UserDB;

use strict;

use vars qw( $VERSION );

BEGIN {
    ($VERSION) = '$Revision: 1.6 $' =~ /Revision: ([\d.]+)/;
}

use DBIx::SearchProfiles;

=pod

=head1 NAME

DBIx::UserDB - Module to manage a user database using DBIx::SearchProfiles

=head1 SYNOPSIS

    use DBIx::UserDB;
    use DBIx::SearchProfiles;

    my $db     = new DBIx::SearchProfiles( ... );
    my $userdb = new DBIx::UserDB( $db );

    my $user   = { username => $username, password => $password };
    $user      = $userdb->user_create( $user );

    # Later on
    my $user   = $userdb->login( $user, $password );
    die "Login failed" unless $user;

    # Much later
    if ( $userdb->allowed( $user, $target, "DELETE" ) ) {
	...
    }

=head1 DESCRIPTION

The DBIx::UserDB uses DBIx::SearchProfiles to manage a user and group
database and may be also used to manage complex ACL. The user and
group schema may be modified for application specific data since only
a few fields are required by the UserDB. This is possible thanks to 
DBIx::SearchProfiles.

=head1 CONCEPTS

=head2 Users and Groups

Users are represented as hash and as one SQL table. They have a unique
username and a unique uid. Group have also a unique name and a unique
gid. A user may be a members of many groups.

=head2 ACLs

UserDB can also be used to manage complex ACL (Acccess Control Lists).
Access to resources is determined by the tuple (user,target,privilege)
which determines if a I<user> has the required I<privilege> on
I<target>. I<Privilege> and I<target> are treated as application
specific character strings.

=head1 CONFIGURATION

In order to use DBIx::UserDB you will need to create a few tables in
your DMBS and to create the approriate DBIx::SearchProfiles.

Here is the minimal schema required in your DBMS :

    CREATE TABLE userdb (
	uid	    SERIAL PRIMARY KEY,
	username    CHAR(32) UNIQUE,
	password    CHAR(32)
    );

    CREATE TABLE groupdb (
	gid	    SERIAL PRIMARY KEY,
	groupname   CHAR(32) UNIQUE
    );

    CREATE TABLE groupmembers (
	gid	    INT REFERENCES groupdb,
	uid	    INT REFERENCES userdb,
	PRIMARY KEY (gid,uid)
    );

    CREATE TABLE user_acl (
	uid	    INT REFERENCES userdb,
	target	    CHAR(128),
	privilege   CHAR(32),
	negated	    BOOL DEFAULT 0,
	PRIMARY KEY (uid,target,privilege)
    );

    CREATE TABLE group_acl (
	gid	    INT REFERENCES groupdb,
	target	    CHAR(128),
	privilege   CHAR(32),
	negated	    BOOL DEFAULT 0,
	PRIMARY KEY (gid,target,privilege)
    );

    CREATE TABLE default_acl (
	target	    CHAR(128),
	privilege   CHAR(32),
	negated	    BOOL DEFAULT 0,
	PRIMARY KEY (target,privilege)
    );

This SQL was tested with PostgreSQL, modify according to your RDBMS.
And here is its related DBIx::SearchProfiles profile :

    {
    userdb	 =>
      {
       fields	 => [qw( username password ) ],
       keys	 => [qw( uid )],
       table	 => "userdb",
      },
    groupdb	 =>
      {
       query	 => q{ SELECT m.gid,uid,groupname FROM groupdb, groupmembers m
		       WHERE  uid = ? },
       params	 => [ qw( uid ) ],
       fields	 => [ qw( groupname ) ],
       keys	 => [ qw( gid )],
       table	 => "groupdb",
      }	,
    }

You may add any fields to the groupdb and userdb tables as long as you
add them to the profiles. The I<userdb> profile should be a C<record>
profile (see DBIx::SearchProfiles(3)) and I<groupdb> should contains
both template profile's information (for finding the users associated
with a group) and record profile's information (for inserting and
updating group's information). Additionaly you may change the fields
length of all required fields.

Passwords are uuencoded for storage (for minimal privacy not for
security), so take this into account when setting the password field's
length. If you want to store password in plaintext, use the
C<scramble_password> method.

=head1 INITIALIZATION

Initializing the DBIx::UserDB is as simple as 

    my $userdb = new DBIx::UserDB( $DB, "userdb", "groupdb" );

The first parameter is a DBIx::SearchProfiles object which will be
used to access the database. The second parameter is the name of the
profile that should be used to access the users' information (defaults
to "userdb"). The third parameter is the name of the profile to use 
for group access (defaults to "groupdb").

=cut

sub new {
    my $proto = shift;
    my $class = ref $proto || $proto;

    my $self = bless {}, $class;

    my $DB	= shift
      or die "Missing Database argument\n";

    my $user_profile	= shift || "userdb";
    my $group_profile	= shift || "groupdb";

    die "No user profile named $user_profile\n"
      unless $DB->has_profile( $user_profile );
    die "No group profile named $group_profile\n"
      unless $DB->has_profile( $group_profile );

    $self->{DB}		    = $DB;
    $self->{user_profile}   = $user_profile;
    $self->{group_profile}  = $group_profile;
    $self->{scramble}	    = 1;

    $self;
}

=pod

=head2 scramble_password ( [new_setting] )

Return the scramble password setting. You may also change the setting
by giving the method a new value. If scramble password is true, user's
password will be uuencoded before being stored in the database.

=cut

sub scramble_password($;$) {
    $_[0]->{scramble} = $_[1] if @_ == 2;

    $_[0]->{scramble};
}

=pod

=head1 USER METHODS

Here are the methods for managing users in the database.

=head2 user_create ( \%user )

This method creates a user with the information specified in the hash
reference in the database. In the user's hash, at least the fields
I<username> and I<password> should be set.

The methods return true on success and false if there is already a
username with that name in the database. Exception are thrown on
database errors. Additionally, on return, the method will add the UID
of the newly created user.

=cut

sub user_create {
    my ( $self, $user ) = @_;

    # Check for a user with the same username
    my $old_user = $self->{DB}->record_search( $self->{user_profile},
					       {username => $user->{username}}
					     );
    return undef if @$old_user;

    # Scramble the password for persistence
    $user->{password} = pack "u*", $user->{password} 
      if ( $self->{scramble} );
    $self->{DB}->record_insert( $self->{user_profile}, $user );

    # Load the user back
    my $new_user = $self->{DB}->record_search( $self->{user_profile},
					       {username => $user->{username}}
					     );
    die "Can't find new user\n" unless @$new_user == 1;

    # Copy the fields of the new user back in this one
    while ( my ($name,$value) = each %{$new_user->[0]} ) {
	$user->{$name} = $value;
    }

    # Unscramble the password
    $user->{password} = unpack "u*", $user->{password}
      if $self->{scramble};

    return $user;
}

sub user_load {
    my ($self,$user) = @_;

    # Unscramble the password
    $user->{password} = unpack "u*", $user->{password}
      if $self->{scramble};
    $user->{groups} =
      $self->{DB}->template_search( $self->{group_profile},
				    { uid => $user->{uid} } );
    return $user;
}

=pod

=head2 user_search ( \%params )

This method will return users matching the DBIx::SearchProfiles query
specification in a reference to an array.

=cut

sub user_search {
    my $self   = shift;

    my $users = $self->{DB}->record_search( $self->{user_profile}, @_ );
    for my $user ( @$users ) {
	$self->user_load( $user );
    }
    return $users;
}

=pod

=head2 user_get ( $uid_or_name )

This method takes a UID or username and return the corresponding user (as an hash reference) or undef if there is no such user.

The key I<groups> in the user's hash contains the names of the groups
of which this user is a member.

=cut

sub user_get {
    my ( $self, $uidorname  ) = @_;

    my $user;
    if ( $uidorname =~ /\d+/ ) {
	$user = $self->{DB}->record_get( $self->{user_profile}, $uidorname );
	return undef unless $user;
    } else {
	my $users = $self->{DB}->record_search( $self->{user_profile},
						{ username => $uidorname } );
	return undef unless @$users;
	$user = $users->[0];
    }
    $self->user_load( $user );
}

=pod

=head2 user_login ( $username, $password )

This method will return the user which have the corresponding username
and password or undef if the username or password is invalid.

=cut

sub user_login {
    my ( $self, $username, $password) = @_;

    my $user = $self->{DB}->record_search( $self->{user_profile},
					   {username => $username,
					    password => ($self->{scramble} ? 
					    pack( "u*", $password ) :
							 $password)
					   }
					 );
    return undef unless @$user == 1;
    $user = $user->[0];

    $self->user_load($user);
}

=pod

=head2 user_delete ( \%user )

This method removes the given user from the database.

=cut

sub user_delete {
    my ( $self, $user ) = @_;

    die "Bad user: no uid\n" unless defined $user->{uid};
    my $DB = $self->{DB};
    $DB->record_delete( $self->{user_profile}, $user );
    $DB->sql_delete( "DELETE FROM groupmembers  WHERE uid = ?", $user->{uid} );
    $DB->sql_delete( "DELETE FROM user_acl	WHERE uid = ?", $user->{uid} );
}

=pod

=head2 user_update ( \%user )

This method updates database information of the given user. This
method has no effects on the group information. Use the
C<group_add_user> and C<group_remove_user> methods for modifying the
groups associated with a user.

=cut

sub user_update {
    my ( $self, $user ) = @_;

    die "Bad user: no uid\n" unless defined $user->{uid};
    # Scramble password
    $user->{password} = pack "u*", $user->{password}
      if $self->{scramble};
    $self->{DB}->record_update( $self->{user_profile}, $user );
    # Unscramble
    $user->{password} = unpack "u*", $user->{password}
      if $self->{scramble};
}

=pod

=head1 GROUP METHODS

Here are the methods to manage group information

=head2 group_create ( \%group )

This method creates a new group in the database. At least the
I<groupname> key should be set in the hash.

This methods returns false if there is already a group with the same
groupname. It returns true if the creation succeeded. Additionnaly, on
return, the key I<gid> will be set in the original group's hash.

=cut

sub group_create {
    my ( $self, $group ) = @_;

    my $DB = $self->{DB};

    # Check for group with same name
    my $old_group = $DB->record_search( $self->{group_profile},
			    { groupname => $group->{groupname} }
				);
    return undef if @$old_group;

    $DB->record_insert( $self->{group_profile}, $group );
    my $new_group = $DB->record_search( $self->{group_profile},
			    { groupname => $group->{groupname} }
				);
    die "Failed to find newly created group\n" unless @$new_group == 1;

    # Copy the fields of the new user back in this one
    while ( my ($name,$value) = each %{$new_group->[0]} ) {
	$group->{$name} = $value;
    }

    return $group;
}

sub load_group {
    my ( $self, $group ) = @_;

    $group->{members} =
      $self->{DB}->sql_search( q{ SELECT uid FROM groupmembers WHERE gid = ? },
			       $group->{gid} );

    return $group;
}

=pod

=head2 group_search ( \%params )

This method will search the database for groups matching the
DBIx::SearchProfiles record search and will return its results as a
reference to an hash.

=cut

sub group_search {
    my $self = shift;

    my $groups = $self->{DB}->record_search( $self->{group_profile}, @_ );
    for my $group( @$groups) {
	$self->load_group( $group );
    }
    return $groups;
}

=pod

=head2 group_get ( $gid_or_name )

This method takes a gid or groupname and will fetch the corresponding
group. It returns the corresponding group or undef if there is no such
group. Additionnaly there is a key I<members> defined in the resulting
hash which contains in an array the name of all members of the group.

=cut

sub group_get {
    my ( $self, $gidorname ) = @_;

    my $group;
    if ( $gidorname =~ /\d+/ ) {
	$group = $self->{DB}->record_get( $self->{group_profile}, $gidorname );
	return undef unless $group;
    } else {
	my $groups = $self->{DB}->record_search( $self->{group_profile},
						 { groupname => $gidorname } );
	return undef unless @$groups;

	$group = $groups->[0];
    }

    $self->load_group( $group );
}

=pod

=head2 group_delete ( \%group )

This methods removes the given group from the database.

=cut

sub group_delete {
    my ( $self, $group ) = @_;

    my $DB = $self->{DB};
    $DB->sql_delete( q{ DELETE FROM groupmembers WHERE gid = ? },
		     $group->{gid} );
    $DB->record_delete( $self->{group_profile}, $group->{gid} );
}

=pod

=head2 group_update ( \%group )

This methods updates the information associated with the given group
in that database. This methods doesn't modify the list of members of
this group. User C<group_add_user> and C<group_remove_user> for that.

=cut

sub group_update {
    my ( $self, $group ) = @_;

    my $DB = $self->{DB};
    $DB->record_update( $self->{group_profile}, $group );

}

=pod

=head2 group_add_user ( \%group, \%user )

Adds the user to that group.

=cut

sub group_add_user {
    my ( $self, $group, $user ) = @_;

    my $DB = $self->{DB};
    $DB->sql_insert( q{ INSERT INTO groupmembers (gid,uid)
				    VALUES (?,?) },
		     $group->{gid}, $user->{uid} );
    push @{$group->{members}}, $user->{uid};
}

=pod

=head2 group_remove_user ( \%group, \%user )

Removes the user from that group.

=cut

sub group_remove_user {
    my ( $self, $group, $user ) = @_;

    my $DB = $self->{DB};
    $DB->sql_insert( q{ DELETE FROM groupmembers WHERE gid = ? AND uid = ?) },
		     $group->{gid}, $user->{uid} );

    $group->{members} = [ grep { $_ != $user->{uid} } @{$group->{members} } ];

}

=pod

=head1 ACL METHODS

Here are the methods to access the ACL information :

=head2 grant ( \%user_or_group, $target, $privilege )

Grant the specified I<privilege> on I<target> to that group or user.
If you want to set the default policy regarding that target and privilege,
use undef as the user parameter.

=cut

sub grant {
    $_[0]->update_acl( @_, 1 );
}

=pod

=head2 deny ( \%user_or_group, $target, $privilege )

Deny the specific I<privilege> on I<target> to that group or user. Use undef
if you want the default policy to be deny.

=cut

sub deny {
    $_[0]->update_acl( @_, 0 );
}

sub update_acl {
    my ( $self, $whom, $target, $priv, $negated ) = @_;

    my $DB = $self->{DB};

    # Try to update privilege first in case it was set and not revoked
    my $rv;
    if ( not ref $whom) {
	$rv = $DB->sql_update( q{ UPDATE default_acl SET negated = ?
				  WHERE target = ? AND privilege = ? },
			       $negated, $target, $priv );
    } elsif ( exists $whom->{uid} ) {
	$rv = $DB->sql_update( q{ UPDATE user_acl SET negated = ?
				  WHERE uid = ? AND target = ?
					AND privilege = ? },
			       $negated, $whom->{uid}, $target, $priv );
    } else {
	$rv = $DB->sql_updated( q{ UPDATED group_acl SET negated = ?
				   WHERE gid = ? AND target = ?
					 AND privilege = ? },
			 $negated, $whom->{gid}, $target, $priv );
    }
    unless ( $rv ) {
	if ( not ref $whom) {
	    $DB->sql_insert( q{ INSERT INTO default_acl
				    (target,privilege,negated)
				    VALUES (?,?,?) },
			     $target, $priv, $negated );
	} elsif ( exists $whom->{uid} ) {
	    $DB->sql_insert( q{ INSERT INTO user_acl
				(uid,target,privilege,negated)
				VALUES (?,?,?,?) },
			     $whom->{uid}, $target, $priv, $negated );
	} else {
	    $DB->sql_insert( q{ INSERT INTO group_acl
				(gid,target,privilege,negated)
				VALUES (?,?,?,?) },
			     $whom->{gid}, $target, $priv, $negated );
	}
    }
}

=pod

=head2 revoke ( \%user_or_group, $target, $privilege )

Removes the specified I<privilege> on I<target> associated with user
or group. If you want to remove the default policy, use undef as the
user parameter.

NOTE: Revoking is not the same as denying. Revoking removes the entry
from the ACL which means that the resulting policy will be determined
by other entry in the ACL (i.e: group or default). When using deny,
you are explicitely determining the level of access.

=cut

sub revoke {
    my ( $self, $whom, $target, $priv ) = @_;

    my $DB = $self->{DB};
    if ( not ref $whom) {
	$DB->sql_delete( q{ DELETE FROM default_acl
			    WHERE target = ? AND privilege = ? },
			 $target, $priv );
    } elsif ( exists $whom->{uid} ) {
	$DB->sql_delete( q{ DELETE FROM user_acl
			    WHERE uid = ? AND target = ? AND privilege = ? },
			 $whom->{uid}, $target, $priv );
    } else {
	$DB->sql_delete( q{ DELETE FROM group_acl
			    WHERE gid = ? AND target = ? AND privilege = ? },
			 $whom->{gid}, $target, $priv );
    }
}

=pod

=head2 allowed ( \%user, $target, $privilege )

Determine if I<user> has I<prilivege> on I<target>. This how the access is determined :

=over

=item 1

Determine if there is an entry (user,target,privilege). If an entry is
found, true or false will be returned depending whether that privilege
was granted or denied.

=item 2

Check for an entry (group,target,privilege) for each group of which
the user is a member. For the group policy to apply, all group must
share the same result.

For example, if user A is member of group A and B and group A is
granted the requested privilege and group B is denied, the group
policy doesn't apply to that particular user. Schematically :

    Group A Granted + Group B Granted = User Granted
    Group A Granted + Group B Denied  = Default policy will apply
    Group A Denied  + Group B Denied  = User Denied

=item 3

A entry (target,privilege) will be lookup in the default policy. If
one is found, that policy will apply.

=item 4

Access is denied.

=back

=cut

sub allowed {
    my ( $self, $user, $target, $priv ) = @_;

    my $DB = $self->{DB};

    # Try to see if there is a policy for this particular 
    # user
    my $user_policy =
      $DB->sql_get( q{ SELECT negated FROM user_acl
		       WHERE uid = ? AND target = ? AND privilege = ? },
		    $user->{uid}, $target, $priv
		  );
    return not $user_policy->{negated} if $user_policy;

    # Now check the group in which this user is.
    # All the group policy must match for this to be returned as
    # a result. If there is a conflict, we use the default policy.
    my $groups = join ",", map { $_->{gid} } @{$user->{groups}};
    my $group_policy =
      $DB->sql_search( qq{ SELECT DISTINCT negated FROM group_acl
			   WHERE gid IN ( $groups ) AND
				 target = ? AND privilege = ?},
		       $target, $priv );
    return not $group_policy->[0]{negated} if @$group_policy == 1;

    # Use the default policy
    my $default_policy = 
      $DB->sql_get( q{ SELECT negated FROM default_acl
		       WHERE target = ? AND privilege = ? },
		    $target, $priv );

    return not $default_policy->{negated} if $default_policy;

    # Well, the default's default is to default
    return 0;
}

1;

__END__

=pod

=head1 BUGS AND LIMITATIONS

Please report bugs, suggestions, patches and thanks to
<bugs@iNsu.COM>.

Authentication is limited to clear text password authentication.

User and group data structure is restricted to single level hash.

=head1 AUTHOR

Copyright (c) 1999 Francis J. Lacoste and iNsu Innovations Inc.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms as perl itself.

=head1 SEE ALSO

DBIx::SearchProfiles(3) Apache::UserDBAuthen(3) Apache::UserDBAuthz(3)

=cut
