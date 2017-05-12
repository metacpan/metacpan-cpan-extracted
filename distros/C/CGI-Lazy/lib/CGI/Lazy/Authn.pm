package CGI::Lazy::Authn;

use strict;

use CGI::Lazy::Globals;
use Digest::MD5;

#----------------------------------------------------------------------------------------
sub activeField {
	my $self = shift;

	return $self->{_activeField};
}

#----------------------------------------------------------------------------------------
sub authenticate {
	my $self = shift;

	my $extraFields = $self->extraFields;
	my @extraFields;
	my @binds;

	my $username = $self->q->param($self->userField);	
	my $passwd = $self->q->param($self->passwdField);

	return unless $username && $passwd;

	$passwd = $self->passwdhash($username, $passwd);

	push @binds, $username;
	push @binds, $passwd;

	#$self->q->util->debug->edump($passwd);

	foreach my $webfield (keys %$extraFields) {
		push @extraFields, $extraFields->{$webfield};
		push @binds, $self->q->param($webfield);
	}

	my $query = 'select * from '. $self->table. ' where '. $self->userField . ' = ? and '. $self->passwdField . ' = ? and '. $self->activeField .' = 1 ';

	foreach (@extraFields) {
		$query .= " and $_ = ?";
	}
	
	my $result = $self->q->db->gethashlist($query, @binds);

	if ($result->[0]) {
		$self->q->session->data->authn({username => $username, authenticated => 1, id => $result->[0]->{$self->primarykey}});

		return 1;
	} else {
		return 0;
	}
}

#----------------------------------------------------------------------------------------
sub check {
	my $self = shift;

	my $session = $self->q->session;

	if  (!$session->expired && $session->data->authn && $session->data->authn->{username} && $session->data->authn->{authenticated}) {
		return 1;
	} else {
		if ($self->authenticate) {
			return $self->authenticate;
		} else {
			return $self->redirectLogin;
		}
	}
}

#----------------------------------------------------------------------------------------
sub extraFields {
	my $self = shift;

	return $self->{_extraFields};
}

#----------------------------------------------------------------------------------------
sub q {
	my $self = shift;

	return $self->{_q};
}

#----------------------------------------------------------------------------------------
sub new {
	my $class = shift;
	my $q = shift;

	my $self = {
		_q		=> $q,

	};

	$self->{_table} = $q->plugin->authn->{table};
	$self->{_template} = $q->plugin->authn->{template};
	$self->{_primarykey} = $q->plugin->authn->{primarykey};
	$self->{_salt} = $q->plugin->authn->{salt};
	$self->{_extraFields} = $q->plugin->authn->{extraFields};
	$self->{_userField} = $q->plugin->authn->{userField} || 'username';
	$self->{_passwdField} = $q->plugin->authn->{passwdField} || $q->plugin->authn->{passwordField} || 'password';
	$self->{_activeField} = $q->plugin->authn->{activeField} || 'active';

	bless $self, $class;

	die "Cannot use Authn without Session.  Please enable Session plugin" unless $self->q->session;

	return $self;
}

#----------------------------------------------------------------------------------------
sub passwdField {
	my $self = shift;

	return $self->{_passwdField};
}

#----------------------------------------------------------------------------------------
sub passwdhash {
	my $self = shift;
	my $username = shift;
	my $passwd = shift;


	return Digest::MD5::md5_base64($username.$passwd.$self->salt);
}

#----------------------------------------------------------------------------------------
sub primarykey	{
	my $self = shift;

	return $self->{_primarykey};
}

#----------------------------------------------------------------------------------------
sub redirectLogin {
	my $self = shift;

	my $tmplvars = {};

	print $self->q->template($self->template)->process($tmplvars);

	return;
}

#----------------------------------------------------------------------------------------
sub salt {
	my $self = shift;

	return $self->{_salt};
}

#----------------------------------------------------------------------------------------
sub table {
	my $self = shift;

	return $self->{_table};
}

#----------------------------------------------------------------------------------------
sub template {
	my $self = shift;

	return $self->{_template};
}

#----------------------------------------------------------------------------------------
sub userField {
	my $self = shift;

	return $self->{_userField};
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

CGI::Lazy::Authn

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

						dbDatasource    => 'dbi:mysql:somedb:localhost',

						dbUser          => 'luser',

						dbPasswd        => 's3cr3t',

						dbArgs          => {RaiseError  => 1},

					},

					session => {

						sessionTable    => 'session',

						sessionCookie   => 'frobnitz',

						saveOnDestroy   => 1,

						expires         => '+15m',

					},

					authn   => {

						table           => 'user',

						primarykey	=> 'user_id',

						template        => 'login.tmpl',

						salt            => '234998fhgsldkj#$^',

						userField       => 'username',

						passwdField     => 'password',

						activeField	=> 'active',

						extraFields	=> {

							country	=> country,

						}

					},
			},

	});


	return unless $q->authn->check;

=head1 DESCRIPTION

CGI::Lazy Authentication module.  Draws much of its inspiration from CGI::Auth. Put the $q->authn->check call in your CGI, if theres a current authenticated session, it will return true.  If not, it will print the login template specified and return false.

The intended minimum database structure is as follows:

	create table user (user_id int(10) unsigned not null auto_increment primary key, username varchar(50), password(varchar(25), active bool);  #mysql
	
=head2 CONFIGURATION


Required Arguments:

	table		=> 'table_name', 		#name of user table	

	primarykey	=> 'field_name',		#name of primary key field on above table.

	template	=> 'login.tmpl',		#name of template for logins

	salt		=> 'asdf9234ml@#4234',		#unique identifying string for this application.  Passwords are stored as md5 hashes of $username.$passwd.$salt .

	userField	=> 'username',			#name of username field.  Defaults to 'username'

	passwdField	=> 'password',			#name of password field.  Defaults to 'password' needs to be varchar and at least 22 characters wide.

	activeField	=> 'active',			#name of field that flags a user as active.  Defaults to 'active'. Assumes '1' means active. 


Optional Arguments:

	extraFields	=> {				#any other fields you want to authenticate on.  If set, will authenticate on username, passwd, and every other field set here.

		webname		=> fieldname,		#first value is the name of the web control, second is the name of the field in the db

		webname2	=> fieldname2,

	}

=head1 METHODS

=head2 check

Call this in your cgi to check if an authenticated session is present.  Returns 1 if session is valid, and authenticated.  Returns 0 otherwise;  If authentication fails, prints the login template.

=head2 passwdhash (username, password)

Takes username, password, and salt from config and generates hashed value for storage in the db.

=head3 username

The username

=head3 password

The cleartext password.

=cut

