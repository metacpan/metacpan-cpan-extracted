package CGI::Lazy::Session;

use strict;

use JSON;
use CGI::Lazy::ID;
use CGI::Lazy::CookieMonster;
use CGI::Lazy::Session::Data;
use CGI::Lazy::Globals;

#--------------------------------------------------------------------------------------
sub cookiemonster {
	my $self = shift;
	
	return $self->{_cookiemonster};
}

#--------------------------------------------------------------------------------------
sub config {
	my $self = shift;
	
	my $q = $self->q;
	return $q->config;
}

#----------------------------------------------------------------------------------------------	
sub data {
	my $self = shift;
	return $self->{_data};
}

#--------------------------------------------------------------------------------------
sub db {
	my $self = shift;
	
	return $self->q->db;

}

#--------------------------------------------------------------------------------------
sub expired {
	my $self = shift;
	
	my $table = $self->sessionTable;

	my $now = time();
	my $expiry = $self->data->expires;

	if ($self->data->terminated) {
		return 1;
	} elsif ($expiry > $now) { 
		return;
	} else {
		return 1;
	}
}

#----------------------------------------------------------------------------------------------	
sub expires {
	my $self = shift;
	return $self->{_expires};
}

#---------------------------------------------------------------------------------------
sub getData {
	my $self = shift;

	my $sessionTable = $self->config->plugins->{session}->{sessionTable};
	my $results = $self->db->getarray("select data from $sessionTable where sessionID = ?", $self->sessionID);
	my $data = $results->[0]->[0];

	if ($data) {
		return from_json($data);
	} else {
		return;
	}
}

#--------------------------------------------------------------------------------------
sub id {
	my $self = shift;

	return $self->{_id};
}

#---------------------------------------------------------------------------------------
sub new {
	my $self = shift;
	my $sessionID = shift;

	my $sessionTable = $self->sessionTable;

	my $query = "insert into $sessionTable (sessionID, data) values (?, ?)";
	my $now = time();
	my $expires = $self->parseExpiry($now);
	
	#set creation time, expiry time, last accessed time
	my $var = {
		created	=> $now,
		updated	=> $now,
		expires	=> $expires,
	};

	my $data = to_json($var);

	$self->db->do($query, $sessionID, $data);

	return $sessionID;	
}
 
#--------------------------------------------------------------------------------------
sub open {
	my $class = shift;
	my $q = shift;
	my $sessionID = shift;

	my $self = {};
	$self->{_q} = $q;
	$self->{_sessionTable} = $q->plugin->session->{sessionTable};
	$self->{_sessionCookie} = $q->plugin->session->{sessionCookie};
	$self->{_expires} = $q->plugin->session->{expires};

	bless $self, $class;

	$self->{_cookiemonster} = CGI::Lazy::CookieMonster->new($q);
   	$self->{_id} = CGI::Lazy::ID->new($self);

       	$sessionID = $self->cookiemonster->getCookie($self->sessionCookie)  unless $sessionID;

	if ($sessionID) { #check sessionID against db, compare expiry time to last accessed time, reopen if valid
		#$q->util->debug->edump("have sessionID");
		$self->{_sessionID} = $sessionID;
		$self->{_data} = CGI::Lazy::Session::Data->new($self);
		
		my $now = time();
		my $expiry = $self->data->expires;

		$sessionID = $self->new($self->id->generate) if $self->expired;

		if ($expiry > $now) { #valid sesion, update expiration
			#$q->util->debug->edump("not expired", "now: ".$now, "expires: ".$expiry, "difference: ".($expiry - $now));
			$self->data->expires($self->parseExpiry($now)); #reset expiry time

		} else {
			#$q->util->debug->edump("expired");
			$self->terminate();

			$sessionID = $self->new($self->id->generate); #session expired.  create a new one
		}

	} else { # create new session
		$sessionID = $self->new($self->id->generate); #if we don't have a valid sessionID, we'll generate one
	}

	$q->errorHandler->badSession($sessionID) unless $self->id->valid($sessionID); #error out if we still don't have something we can work with.

	$self->{_sessionID} = $sessionID;
	$self->{_data} = CGI::Lazy::Session::Data->new($self);

	return $self;

}

#--------------------------------------------------------------------------------------
sub parseExpiry {
	my $self = shift;
	my $time = shift;

	my $expirestring = $self->expires;

	$expirestring =~ /([+-])(\d+)(\w)/;
	my ($sign, $num, $unit) = ($1, $2, $3);

	unless ($sign && $num && $unit) {
		$self->q->errorHandler->badSessionExpiry;
	}

	my $minute = 60; #seconds in a minute
	my $hour = 3600; #seconds in an hour
	my $day = 43200; #seconds in a day
	my $factor;
	my $expiry;

	if ($unit eq 'm') {
		$factor = $minute * $num;
	} elsif ($unit eq 'h') {
		$factor = $hour * $num;
	} elsif ($unit eq 'd') {
		$factor = $day * $num;
	} else { #we'll assume it's seconds then (why would someone do this?)
		$factor = $num;
	}

	if ($sign eq '+') {
		$expiry = $time + $factor;
	} elsif ($sign eq '-') {
		$expiry = $time - $factor;
	}
	
	return $expiry;
}

#--------------------------------------------------------------------------------------
sub q {
	my $self = shift;

	return $self->{_q};
}

#--------------------------------------------------------------------------------------
sub sessionCookie {
	my $self = shift;

	return $self->{_sessionCookie};
}

#--------------------------------------------------------------------------------------
sub sessionID {
	my $self = shift;
	
	return $self->{_sessionID};
}

#--------------------------------------------------------------------------------------
sub sessionTable {
	my $self = shift;

	return $self->{_sessionTable};
}

#--------------------------------------------------------------------------------------
sub save {
	my $self = shift;

	my $sessionID = $self->sessionID;
	my $datastring = to_json($self->data->{_data});
	my $sessionTable = $self->q->plugin->session->{sessionTable};

	$self->db->do("update $sessionTable set data = ? where sessionID = ?", $datastring, $sessionID);
}

#--------------------------------------------------------------------------------------
sub terminate {
	my $self = shift;

#	my $table = $self->sessionTable;

#	$self->db->do("update $table set expired = 1 where sessionID = ?", $self->sessionID);

	$self->data->terminated(1);
	return;
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

CGI::Lazy::Session

=head1 SYNOPSIS

	use CGI::Lazy;

	our $q = CGI::Lazy->new({

					tmplDir 	=> "/templates",

					jsDir		=>  "/js",

					plugins 	=> {

						mod_perl => {

							PerlHandler 	=> "ModPerl::Registry",

							saveOnCleanup	=> 1,

						},

						ajax	=>  1,

						dbh 	=> {

							dbDatasource 	=> "dbi:mysql:somedatabase:localhost",

							dbUser 		=> "dbuser",

							dbPasswd 	=> "letmein",

							dbArgs 		=> {"RaiseError" => 1},

						},

						session	=> {

							sessionTable	=> 'SessionData',

							sessionCookie	=> 'frobnostication',

							saveOnDestroy	=> 1,

							expires		=> '+15m',

						},

					},

				});

=head1 DESCRIPTION

CGI::Lazy::Session is for maintaining state between requests.  It's enabled in the config file or config hash.  Once it's enabled, any calls to $q->header will automatically include a cookie that will be used to retrieve session data.

To function, the session needs the following arguments:

	sessionTable	=> name of table to store data in

	sessionCookie	=> name of the cookie

	expires		=> how long a session can sit idle before expiring

By default, sessions are automatically saved when the Lazy object is destroyed, or in the cleanup stage of the request cycle for mod_perl apps.  Both mechanisms are enabled by default.  (call me paranoid)  Should you wish to disable the save on destroy:
	saveOnDestroy	=> 0

If the key is missing from the config, it's as if it was set to 1.  You will have to set it to 0 to disable this functionality.  Same goes for the mod_perl save.  See CGI::Lazy::ModPerl for details

Session data is stored in the db as JSON formatted text at present.  Fancier storage (for binary data and such) will have to wait for subsequent releases.

The session table must have the following fields at a bare minimum:

	sessionID	not null, primary key, varchar(25)

	data		text (mysql) large storage (clob in oracle)

=head1 METHODS

=head2 cookiemonster

returns reference to CGI::Lazy::CookieMonster object

=head2 config

returns reference to the config object

=head2 data ()

returns reference to the CGI::Lazy::Session::Data object

=head2 db ()

returns reference to CGI::Lazy::DB object

=head2 expired ()

returns 1 if session has been expired, either explicitly or by timeout

=head2 expires ()

Returns time in epoch when session expires.

=head2 getData ()

Called internally on CGI::Lazy::Session::Data creation.  Queries db for session data

=head2 id ()

returns session id

=head2 new ( sessionID )

Constructor.  Creates new session.

=head3 sessionID

valid session ID string

=head2 open ( q sessionID )

Opens a previous session, or creates a new one.  If it's opening an existing session, it will check to see that the session given has not expired.   If it has, it will create a new one.

=head3 q

CGI::Lazy object

=head3 sessionID

valid session ID

=head2 parseExpiry ( time)

Parses expiration string from session plugin and returns time in epoch when session should expire.

Currently only can parse seconds, minutes, hours and days.  Is more really necessary?

=head3 time

Epoch returned from time() function

=head2 q ()

Returns reference to CGI::Lazy object

=head2 sessionCookie ()

Returns name of session cookie specified by session plugin

=head2 sessionID ()

Returns session id

=head2 sessionTable ()

Returns session table name specified by session plugin

=head2 save ()

Saves session variable to database

=head2 terminate ()

Terminates the session.  Session data object will have the 'terminated' flag set.


=cut

