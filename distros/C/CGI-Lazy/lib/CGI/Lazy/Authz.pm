package CGI::Lazy::Authz;

use CGI::Lazy::Globals;

use strict;

#-------------------------------------------------------------------------------
sub AUTOLOAD {
	my $self = shift;
	my $perm = shift;

	my $name = our $AUTOLOAD;
	return if $name =~ /::DESTROY$/;
	my @list = split "::", $name;

	my $groupName = pop @list;
	my $userID = $self->q->session->data->authn->{id};
	my @binds = ($groupName, $userID);

	my $map = $self->_mapTable;
	my $user = $self->_userTable;
	my $group = $self->_groupTable;
	my $flag = $self->_permFlag;

	my $query = "select * from $map->{name} inner join $group->{name} on $group->{primarykey} = $map->{groupField} where $group->{groupNameField} = ? and $map->{userField} = ?";

	if ($perm) {
		$query .= " and $perm = ?";
		push @binds, $flag;
	}

#	$self->q->util->debug->edump($query, $groupName, $userID);

	my $result = $self->q->db->get($query, @binds);

	if ($result) {
		return 1;
	} else {
		return;

	}
}

#----------------------------------------------------------------------------------------
sub _groupTable {
	my $self = shift;

	return $self->{_groupTable};
}

#----------------------------------------------------------------------------------------
sub q {
	my $self = shift;

	return $self->{_q};
}

#----------------------------------------------------------------------------------------
sub _mapTable {
	my $self = shift;

	return $self->{_mapTable};
}

#----------------------------------------------------------------------------------------
sub new {
	my $class = shift;
	my $q = shift;

	my $self = {
		_q 		=> $q,
		_userTable	=> $q->plugin->authz->{userTable},
		_groupTable	=> $q->plugin->authz->{groupTable},
		_mapTable	=> $q->plugin->authz->{mapTable},
		_permFlag	=> $q->plugin->authz->{permFlag} || 1,
		
	};

	bless $self, $class;

	die "Cannot use Authz without Authn.  Please enable Authn plugin" unless $self->q->authn;

	return $self;
}

#----------------------------------------------------------------------------------------
sub _permFlag {
	my $self = shift;

	return $self->{_permFlag};
}

#----------------------------------------------------------------------------------------
sub _userTable {
	my $self = shift;

	return $self->{_userTable};
}
1

__END__

=head1 LEGAL

#===========================================================================

Copyright (C) 2008 by Nik Ogura. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

Bug reports and comments to nik.ogura@gmail.com. 

#===========================================================================

=head1 NAME

CGI::Lazy::Authz

=head1 SYNOPSIS

	use CGI::Lazy;

	my $q = CGI::Lazy->new({

			tmplDir         => '/templates',

			jsDir           => '/js',

			cssDir          => '/css',

			imgDir          => '/css',

			buildDir        => '/tmp',

			plugins         => {

					dbh     => {

						dbDatasource    => 'dbi:mysql:someDB:localhost',

						dbUser          => 'someUser',

						dbPasswd        => 'somePass',

						dbArgs          => {RaiseError  => 1},

					},

					session => {

						sessionTable    => 'session',

						sessionCookie   => 'frobnitz',

						saveOnDestroy   => 1,

						expires         => '+5m',

					},

					authn   => {

						table           => 'user',

						primarykey      => 'user_id',

						template        => 'login.tmpl',
	
						salt            => '2349987sa;lsdfvsdf',

						userField       => 'username',

						passwdField     => 'password',

					},

					authz   => {

						permFlag        => 1,

						userTable       => {

							name            => 'user',

							primarykey      => 'user_id',

							userNameField   => 'username',

						},

						groupTable      => {

							name            => 'group_list',

							primarykey      => 'group_id',

							groupNameField  => 'group_name',

						},

						mapTable        => {

							name            => 'user_group_map',

							groupField      => 'group_id_map',

							userField       => 'user_id_map',

							perms   => [],

						},


					},
			},
		});

	
	return unless $q->authn->check;

	return $q->template('unauthorized')->process() unless $q->quthz->user('readable');


=head1 DESCRIPTION

CGI::Lazy::Authz is the authorization module for Lazy.  It was designed to be as flexible as possible, but unfortunately it does dictate the design of your database somewhat.  Authz is dependent on Authn and Session.  You can't have authorization without authentication, and authentication requires persistent sessions.

Authz is designed to be called in one of two ways.  First, if you call $q->authz->group, Lazy will check the db for a record indicating that the current user is a member of 'group'.  Its using an autoloader, so if you call the group name as a method on the Authz object, you'll get back a 1 if the record exists, and undef if it does not.  

Secondly, you can specify attributes to the membership in a group, such as 'read', 'write', 'execute', or any other permission you desire.  Authz expects the permissions to be flag fields in the map table that contains which users have access to which groups.  Calling $q->authz->admin('writeable')  will check to see if the current user is a member of the group 'admin', and if a field called 'writable' has the value specified by the 'permFlag' in the authz configuration.  If the user is a member of the group, and the flag is set, it returns 1, if not it returns undef;

We are assuming your database is set up as follows:  There's a user table, with some sort of unique user id.  Theres a group table that stores all available groups, and each group has a unique id.  Users are mapped to groups in a map table that has, in each record, a user id, a group id, and any number of optional flag fields.  If a record exists in the map table with a given group id and user id, then the user is part of that group.  The optional flags can be set to further customize the access within the group.

What you do with the groups, or the permissions flags is entirely up to you.  Authz simply reports on whether a given user is in a given group, or if a given user has a given permission within a given group.

The intended database structure is as follows:

	create table user (user_id int(10) unsigned not null auto_increment primary key, username varchar(50), password(varchar(25), active bool);  #mysql
	
	create table group_list (group_id int(10) unsigned not null auto_increment primary key, group_name varchar(50), group_description varchar(200));  #mysql, can't call table 'group', as it's reserved.

	create table user_group_map (user_group_map_id int(10) unsigned not null auto_increment primary key, group_id_map int(10), user_id_map int(10), readable bool, writable bool); #mysql


=head2 CONFIGURATION

=head3 mapTable

	name		=> 'user_group_map'	#name of map table

	groupField	=> 'group_id_map'	#name of field that stores group id

	userField	=> 'user_id_map'	#name of field that stores user id

=head3 userTable

	name		=> 'user'		#name of user table
	
	primarykey      => 'user_id'		#primary key of user table

	userNameField  => 'user_name'		#name of username field

=head3 groupTable

	name            => 'group_list',	#name of group table

	primarykey      => 'group_id',		#primary key of group table

	groupNameField   => 'group_name',	#name of group name field

=head3 permFlag
	
	Whatever your database uses to indicate 'true'.  Defaults to '1';
=cut

