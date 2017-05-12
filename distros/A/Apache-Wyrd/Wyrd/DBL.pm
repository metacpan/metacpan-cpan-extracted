use 5.006;
use strict;
use warnings;
no warnings qw(uninitialized);

package Apache::Wyrd::DBL;
our $VERSION = '0.98';
use DBI;
use Apache;
use Apache::Wyrd::Request;
use Apache::Wyrd::User;
use Apache::URI;

=pod

=head1 NAME

Apache::Wyrd::DBL - Centralized location for tracking variables, internals

=head1 SYNOPSIS

	my $hostname = $wyrd->dbl->req->hostname;
	my $database_handle = $wyrd->dbl->dbh;
	my $value = $wyrd->dbl->param('value');

=head1 DESCRIPTION

C<Apache::Wyrd::DBL> ("Das Blinkenlights") is a convenient placeholder for
all session information a Wyrd might need in order to do work.  It holds
references to the session's current apreq, DBI, and Apache objects, as well
as the current session log and other vital information.  It is meant to be
called from within an Apache::Wyrd object through it's C<dbl> method, as in
the SYNOPSIS.

Debugging is always turned on if port 81 is used.  Note that apache must be set
up to listen at this port as well.  See the Listen and BindAddress Apache directives.

=head1 METHODS

=over

=item (DBL) C<new> (hashref, hashref)

initialize and return the DBL with a set of startup params and a set of global
variables (for the WO to access) in the form of two hashrefs.  The first hashref
should include at least the 'req' key, which is an Apache request object.

The startup params can have several keys set.  These may be:

=over

=item apr

the param/cookie subsystem (CGI or Apache::Request object initialized by a Apache::Wyrd::Request object);

=item dba

database application.  Should be the name of a DBI::DBD driver.

=item database

database name (to connect to)

=item db_password

database password

=item db_username

database user name

=item loglevel

Logging level, per Apache::Wyrd object

=item globals

pointer to globals hashref

=item req (B<required>)

the request itself (Apache request object)

=item strict

should strict procedures be followed (not used by default)

=item user

the current user (not used by default)

=back

=cut

sub new {
	my ($class, $init) = @_;
	if ((ref($init) ne 'HASH') and $init) {
		complain("invalid init data given to Das Blinkenlights -- Ignored");
		$init = {};
	}
	$ENV{PATH} = undef unless ($$init{flags} =~ /allow_unsafe_path/);
	if ((ref($$init{'globals'}) ne 'HASH') and $$init{'globals'}) {
		complain("invalid global data given to Das Blinkenlights -- Ignored");
		$$init{'globals'} = {};
	}
	my @standard_params = qw(
		atime
		base_class
		blksize
		blocks
		ctime
		database
		db_password
		db_username
		dba
		dev
		file_path
		gid
		globals
		ino
		logfile
		loglevel
		mode
		mtime
		nlink
		rdev
		req
		self_path
		size
		strict
		taint_exceptions
		uid
		user
	);
	my $data = {
		dbl_log		=>	[],
		dbh_ok		=>	0,
		dbh			=>	undef,
		response	=>	undef
	};
	foreach my $param (@standard_params) {
		$$data{$param} = ($$init{$param} || undef);
	}
	bless $data, $class;
	if (UNIVERSAL::isa($$init{'req'}, 'Apache')) {
		$data->{'req'} = $$init{'req'};
		$data->{'mod_perl'} = 1;
		my $server = $$init{'req'}->server;
		$data->{'loglevel'} = 4 if ($server->port == 81);
		$data->{'self_path'} ||= $$init{'req'}->parsed_uri->rpath;
		my $apr = Apache::Wyrd::Request->instance($$init{'req'});
		$data->{'apr'} = $apr;
	};
	if (UNIVERSAL::isa($$init{'database'}, 'DBI::db')) {
		if ($$init{'database'}->can('ping') && $$init{'database'}->ping) {
			$data->{'dbh'} = $$init{'database'};
			$data->{'dbh_ok'} = 1;
		} else {
			$data->log_bug('DBI-type Database apparently passed to Das Blinkenlights, but was not valid')
		}
	}
	return $data;
}

=pod

=item verify_dbl_compatibility

Used by Apache::Wyrd to confirm it's been passed the right sort of object for a
DBL.

=cut

sub verify_dbl_compatibility {
	return 1;
}

=item (scalar) C<strict> (void)

Optional read-only method for "strict" conditions.  Not used by the default install.

=cut

sub strict {
	my ($self) = @_;
	return $self->{'strict'};
}

=pod

=item (scalar) C<loglevel> (void)

Optional read-only method for "loglevel" conditions.  Not used by the default install.

=cut

sub loglevel {
	my ($self) = @_;
	return $self->{'loglevel'};
}

=pod

=item (void) C<log_bug> (scalar)

insert a debugging message in the session log.

=cut

sub log_bug {
	return unless (ref($_[0]) and ($_[0]->{'debug'}));
	my ($self, $value) = @_;
	my @caller = caller();
	$caller[0] =~ s/.+://;
	$caller[2] =~ s/.+://;
	my $id = "($caller[0]:$caller[2])";
	$value = join(':', $id, $value);
	push @{$self->{'dbl_log'}}, $value;
	warn $value;
}

=pod

=item (void) C<set_logfile> (filehandle typeglob)

give DBL a file in which to store it's events. The filehandle is then kept in
the logfile attribute.

=cut

sub set_logfile {
	my ($self, $fh) = @_;
	$| = 1;
	$self->{'logfile'} = $fh;
}

=pod

=item (void) C<close_logfile> (void)

flush logfile to disk.  Necessary in mod_perl situation, it seems.

=cut

sub close_logfile {
	my ($self, $fh) = @_;
	$self->{'logfile'} = $fh;
	close ($fh) if ($fh);
	eval("system('/bin/sync')");
}

=pod

=item (void) C<log_event> (scalar)

same as log_bug, but don't send the output to STDERR. Instead, make it HTML escaped and store it for later dumping.

=cut

sub log_event {
	my ($self, $value) = @_;
	$self->{'dbl_log'} = [@{$self->{'dbl_log'}}, $value];
	my $fh = $self->{'logfile'};
	if ($fh) {
		print $fh (Apache::Util::escape_html($value) . "<br>\n");
	}
}

=pod

=item (hashref) C<base_class> (void)

return the base class of this set of Wyrds.

=cut

sub base_class {
	my ($self) = @_;
	return $self->{'base_class'};
}

=pod

=item (hashref) C<taint_exceptions> (void)

Which params are allowed to contain information that could be interpreted as a
Wyrd.

=cut

sub taint_exceptions {
	my ($self) = @_;
	return @{$self->{'taint_exceptions'} || []};
}

=pod

=item (hashref) C<globals> (void)

return a reference to the globals hashref  Has a useful debugging message on unfound globals.

=cut

sub globals {
	my ($self) = @_;
	return $self->{'globals'};
}

=pod

=item (scalar) C<mtime> (void)

the modification time of the file currently being served.  Derived from
Apache::Wyrd::Handler, by default compatible with the C<stat()> builtin
function.

=cut

sub mtime {
	my ($self) = @_;
	return $self->{'mtime'};
}

=item (scalar) C<size> (void)

the file size of the file currently being served.  Derived from
Apache::Wyrd::Handler, by default compatible with the C<stat()> builtin
function.

=cut

sub size {
	my ($self) = @_;
	return $self->{'size'};
}

=pod

=item (scalar) C<dev> (void)

the device number of filesystem of the file currently being served.  Derived
from Apache::Wyrd::Handler, by default compatible with the C<stat()> builtin
function.

=cut

sub dev {
	my ($self) = @_;
	return $self->{'dev'};
}


=pod

=item (scalar) C<ino> (void)

the inode number of the file currently being served.  Derived from
Apache::Wyrd::Handler, by default compatible with the C<stat()> builtin
function.

=cut

sub ino {
	my ($self) = @_;
	return $self->{'ino'};
}


=pod

=item (scalar) C<mode> (void)

the file mode  (type and permissions) of the file currently being served. 
Derived from Apache::Wyrd::Handler, by default compatible with the C<stat()>
builtin function.

=cut

sub mode {
	my ($self) = @_;
	return $self->{'mode'};
}


=pod

=item (scalar) C<nlink> (void)

the number of (hard) links to the file of the file currently being served. 
Derived from Apache::Wyrd::Handler, by default compatible with the C<stat()>
builtin function.

=cut

sub nlink {
	my ($self) = @_;
	return $self->{'nlink'};
}


=pod

=item (scalar) C<uid> (void)

the numeric user ID of file's owner of the file currently being served. 
Derived from Apache::Wyrd::Handler, by default compatible with the C<stat()>
builtin function.

=cut

sub uid {
	my ($self) = @_;
	return $self->{'uid'};
}


=pod

=item (scalar) C<gid> (void)

the numeric group ID of file's owner of the file currently being served. 
Derived from Apache::Wyrd::Handler, by default compatible with the C<stat()>
builtin function.

=cut

sub gid {
	my ($self) = @_;
	return $self->{'gid'};
}


=pod

=item (scalar) C<rdev> (void)

the the device identifier (special files only) of the file currently being
served.  Derived from Apache::Wyrd::Handler, by default compatible with the
C<stat()> builtin function.

=cut

sub rdev {
	my ($self) = @_;
	return $self->{'rdev'};
}


=pod

=item (scalar) C<atime> (void)

the last access time in seconds since the epoch of the file currently being
served.  Derived from Apache::Wyrd::Handler, by default compatible with the
C<stat()> builtin function.

=cut

sub atime {
	my ($self) = @_;
	return $self->{'atime'};
}


=pod

=item (scalar) C<ctime> (void)

the inode change time in seconds since the epoch of the file currently being
served.  Derived from Apache::Wyrd::Handler, by default compatible with the
C<stat()> builtin function.  See the perl documentation for details.

=cut

sub ctime {
	my ($self) = @_;
	return $self->{'ctime'};
}


=pod

=item (scalar) C<blksize> (void)

the preferred block size for file system I/O of the file currently being
served.  Derived from Apache::Wyrd::Handler, by default compatible with the
C<stat()> builtin function.

=cut

sub blksize {
	my ($self) = @_;
	return $self->{'blksize'};
}


=pod

=item (scalar) C<blocks> (void)

the actual number of blocks allocated of the file currently being served. 
Derived from Apache::Wyrd::Handler, by default compatible with the C<stat()>
builtin function.

=cut

sub blocks {
	my ($self) = @_;
	return $self->{'blocks'};
}


=pod

=item (variable) C<get_global> (scalar)

retrieve a global by name.

=cut

sub get_global {
	my ($self, $name) = @_;
	unless (exists($self->{'globals'}->{$name})) {
		$self->log_bug("Asked to get global value $name which doesn't exist. Returning undef.");
		return;
	}
	return $self->{'globals'}->{$name};
}

=pod

=item (void) set_global(scalar, scalar)

find the global by name and set it.  Has a helpful debugging message on
undefined globals.

=cut

sub set_global {
	my ($self, $name, $value) = @_;
	unless (exists($self->{'globals'}->{$name})) {
		$self->log_bug("Asked to set global value $name which doesn't exist.  Creating it and setting it.");
	}
	$self->{'globals'}->{$name} = $value;
	return;
}

=pod

=item (scalar) C<get_response> (void)

Return the response.  Should be an Apache::Constants response code.

=cut

sub get_response {
	my ($self) = @_;
	return $self->{'response'};
}

=pod

=item (scalar) C<set_response> (void)

Set the response.  Should be an Apache::Constants response code.

=cut

sub set_response {
	my ($self, $response) = @_;
	$self->{'response'} = $response;
	return;
}

=pod

=item (DBI::DBD::handle) C<dbh> (void)

Database handle object.  Collects database information from the initialization
data and calls _init_db with it.

=cut

sub dbh {
	my ($self) = shift;
	my $dba = $self->{'dba'};
	my $db = $self->{'database'};
	my $uname = $self->{'db_username'};
	my $pw = $self->{'db_password'};
	my $dbh = $self->_init_db($dba, $db, $uname, $pw);
	return $dbh if ($dbh);
	$self->log_bug('dbh was requested from DBL but no database could be initialized');
	return;
}

=pod

=item (Apache) C<req> (void)

Apache request object

=cut

sub req {
	my ($self) = shift;
	return $self->{'req'} if $self->{'mod_perl'};
	$self->log_bug('Apache Request Object requested from DBL, but none supplied at initialization.');
}

=pod

=item (scalar) C<user> (void)

Optional read-only method for an C<Apache::Wyrd::User> object.  Not used by the
default install.

=cut

sub user {
	my ($self) = shift;
	if ($self->{'user'}) {
		return $self->{'user'};
	} else {
		#attempt to create a null user if none is defined.
		my $req = $self->req;
		my $object_class = $req->dir_config('UserObject');
		if ($object_class) {
			eval "use $object_class";
			unless ($@) {
				my $user = undef;
				eval '$user = ' . $object_class . '->new()';
				unless ($@) {
					return $user;
				} else {
					$self->log_bug("User Object defined as $object_class, but could not be instantiated.  Reason: $@");
				}
			} else {
				$self->log_bug("You must define a user class with the UserObject directory configuration.  See `perldoc Apache::Wyrd::Services::Auth`.");
			}
		}
	}
	return undef;
}

=pod

=item (CGI/Apache::Request) C<apr> (void)

Apache::Wyrd::Request object (handle to either a CGI or Apache::Request object)

=cut

sub apr {
	my ($self) = shift;
	return $self->{'apr'};
}

=pod

=item (scalar/arrayref) C<param> ([scalar])

Like CGI->param().  As a security measure, any data found in parameters which
matches the name of the Wyrds on a given installation, I<e.g. BASENAME> is
dropped unless the variable is named in the array of variable names stored
by reference under the C<taint_exceptions> key of the BASENAME::Handler's
C<init()> function.

=cut

sub param {
	my ($self, $value, $set) = @_;
	return $self->apr->param($value, $set) if (scalar(@_) > 2);
	if ($value) {
			if (grep {$value eq $_} $self->taint_exceptions) {
				return $self->apr->param($value);
			}
			my $forbidden = qr/<$self->{base_class}/;
			if (wantarray) {
				return grep {$_ !~ /$forbidden/} $self->apr->param($value);
			} else {
				my $result = $self->apr->param($value);
				if ($result !~ /$forbidden/) {
					return $result
				}
				return;
			}
	}
	return $self->apr->param;
}

=pod

=item (scalar) C<param_exists> (scalar)

Returns a non-null value if the CGI variable indicated by the scalar argument
was actually returned by the client.

=cut

sub param_exists {
	my ($self, $value) = @_;
	return grep {$_ eq $value} $self->apr->param;
}

=pod

=item (scalar) C<file_path> (void)

return the path to the actual file being parsed.

=cut

sub file_path {
	my ($self) = shift;
	return $self->{'file_path'} if $self->{'file_path'};
	$self->log_bug('file_path was requested from DBL, but could not be determined.');
}

=pod

=item (scalar) C<self_path> (void)

return the document-root relative path to the file being served.

=cut

sub self_path {
	my ($self) = shift;
	return $self->{'self_path'} if $self->{'self_path'};
	$self->log_bug('self_path was requested from DBL, but could not be determined.');
}

=pod

=item (scalar) C<self_url> (void)

return an interpolated version of the current url.

=cut

sub self_url {
	my ($self) = @_;
	my $scheme = 'http:';
	$scheme = 'https:' if ($ENV{'HTTPS'} eq 'on');
	return $scheme . '//' . $self->req->hostname . $self->req->parsed_uri->unparse;
}

=pod

=item (internal) C<_init_db> (scalar, scalar, scalar, scalar);

open the DB connection.  Accepts a database type, a database name, a username,
and a password.  Defaults to a mysql database.  Sets the dbh parameter and the
dbh_ok parameter if the database connection was successful.  Meant to be called
from C<dbh>.  As of version 0.97 calls connect_cached instead of attempting to
maintain a cached connection itself.

=cut


sub _init_db {
	my ($self, $dba, $database, $db_uname, $db_passwd) = @_;
	my $dbh = undef;
	$dba ||= 'mysql';
	eval{$dbh = DBI->connect_cached("DBI:$dba:$database", $db_uname, $db_passwd)};
	$self->log_bug("Database init failed: $@") if ($@);
	return $dbh;
}

=pod

=item (internal) C<close_db> (void);

close the C<dbh> connection if it was opened.

=cut

sub close_db {
	my ($self) = @_;
	return undef unless ($self->{'dbh_ok'});
	$self->{'dbh'}->finish if (UNIVERSAL::can($self->{'dbh'}, 'finish'));
	$self->{'dbh'}->disconnect if (UNIVERSAL::can($self->{'dbh'}, 'disconnect'));
	return;
}

=item (scalarref) C<dump_log> (void)

return a scalarref to a html-formatted dump of the log.

=cut

sub dump_log {
	require Apache::Util;
	my ($self) = @_;
	my $out ="<code><small><b>Log Backtrace:</b><br>";
	foreach my $i (reverse(@{$self->{'dbl_log'}})) {
		$out .= Apache::Util::escape_html($i) . "<br>\n";
	}
	$out .= "</small></code>";
	return \$out;
}

=head1 BUGS

UNKNOWN

=head1 AUTHOR

Barry King E<lt>wyrd@nospam.wyrdwright.comE<gt>

=head1 SEE ALSO

=over

=item Apache::Wyrd

General-purpose HTML-embeddable perl object

=back

=head1 LICENSE

Copyright 2002-2007 Wyrdwright, Inc. and licensed under the GNU GPL.

See LICENSE under the documentation for C<Apache::Wyrd>.

=cut

1;
