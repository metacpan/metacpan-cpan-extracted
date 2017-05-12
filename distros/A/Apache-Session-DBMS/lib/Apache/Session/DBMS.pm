#############################################################################
#
# Apache::Session::DBMS
# Apache persistent user sessions using DBMS
# Copyright(c) 2005 Asemantics S.r.l.
# Alberto Reggiori (alberto@asemantics.com)
# Distribute under a BSD license (see LICENSE file in main dir)
#
############################################################################

package Apache::Session::DBMS;

use strict;
use vars qw(@ISA $VERSION $incl);

$VERSION = '0.32';
@ISA = qw(Apache::Session);

$incl = {};

use Apache::Session;
use Apache::Session::Lock::Null;
use Apache::Session::Store::DBMS;
use Apache::Session::Generate::DBMS;

use Apache::Session::Serialize::DBMS::Storable;

sub populate {
	my $self = shift;

	$self->{object_store} = new Apache::Session::Store::DBMS $self;
	$self->{lock_manager} = new Apache::Session::Lock::Null $self;
	$self->{generate}     = \&Apache::Session::Generate::DBMS::generate;
	$self->{validate}     = \&Apache::Session::Generate::DBMS::validate;

	if( exists $self->{args}->{Serialize} ) {
		my $ser   = "Apache::Session::Serialize::$self->{args}->{Serialize}";

		if (!exists $incl->{$ser}) {
			eval "require $ser" || die $@;
			eval '$incl->{$ser}->[0] = \&' . $ser . '::serialize'   || die $@;
			eval '$incl->{$ser}->[1] = \&' . $ser . '::unserialize' || die $@;

			$self->{serialize}    = $incl->{$ser}->[0];
			$self->{unserialize}  = $incl->{$ser}->[1];
			};
	} else {
		# Storable is the default
		$self->{serialize}    = \&Apache::Session::Serialize::DBMS::Storable::serialize;
		$self->{unserialize}  = \&Apache::Session::Serialize::DBMS::Storable::unserialize;
		};

	$self->{ isObjectPerKey } = (	( defined $self->{data}->{_session_id} ) and
					(	$self->{data}->{_session_id} =~ m|^\s*dbms://([^:]+):(\d+)/([^\s]+)| or
						$self->{data}->{_session_id} =~ m|^\s*dbms://([^/]+)/([^\s]+)| ) ) ? 1 : 0 ;

	return $self;
	};

# override perltie part
sub FETCH {
	my $self = shift;
	my $key  = shift;

        if( $self->{isObjectPerKey} ) {
		&{$self->{unserialize}}( $self, $self->{object_store}->{dbh}->FETCH( $key ) ); # yep we do unserialize it each time
        } else {
		$self->SUPER::FETCH( $key );
		};
	};

sub STORE {
	my $self  = shift;
	my $key   = shift;
	my $value = shift;

	if( $self->{isObjectPerKey} ) {
		$self->{object_store}->{dbh}->STORE( $key, &{$self->{serialize}}( $self, $value ) ); # yep we do serialize it each time
        } else {
		$self->SUPER::STORE( $key, $value );
		};
	};

sub DELETE {
	my $self = shift;
	my $key  = shift;

	if( $self->{isObjectPerKey} ) {
		$self->{object_store}->{dbh}->DELETE( $key );
        } else {
		$self->SUPER::DELETE( $key );
		};
	};

sub CLEAR {
	my $self = shift;

	if( $self->{isObjectPerKey} ) {
		$self->{object_store}->{dbh}->CLEAR();
        } else {
		$self->SUPER::CLEAR();
		};
	};

sub EXISTS {
	my $self = shift;
	my $key  = shift;

	if( $self->{isObjectPerKey} ) {
		$self->{object_store}->{dbh}->EXISTS( $key );
        } else {
		$self->SUPER::EXISTS( $key );
		};
	};

sub FIRSTKEY {
	my $self = shift;

	if( $self->{isObjectPerKey} ) {
		$self->{object_store}->{dbh}->FIRSTKEY();
        } else {
		$self->SUPER::FIRSTKEY();
		};
	};

sub NEXTKEY {
	my $self = shift;

	if( $self->{isObjectPerKey} ) {
		$self->{object_store}->{dbh}->NEXTKEY( shift );
        } else {
		$self->SUPER::NEXTKEY( shift );
		};
	};

sub DESTROY {
	my $self = shift;

	if( $self->{isObjectPerKey} ) {
		#$self->{object_store}->{dbh}->sync();
        } else {
		$self->SUPER::DESTROY();
		};
	};

# override persistence methods if object-per-key mode on
# NOTE: basically we bypass the whole Apache::Session "caching" one-key-object layer

sub restore {
	my $self = shift;

	if( $self->{isObjectPerKey} ) {
		$self->{object_store}->connection($self);
	} else {
		$self->SUPER::restore();
		};
	};

sub save {
	my $self = shift;

	if( $self->{isObjectPerKey} ) {
		$self->{object_store}->connection($self);
	} else {
		$self->SUPER::save();
		};
	};

sub delete {
	my $self = shift;

	if( $self->{isObjectPerKey} ) {
		$self->{object_store}->connection($self);

		$self->{object_store}->{dbh}->DROP()
			or die $DBMS::ERROR."\n"; #shall we do a fire-safe check here?
        } else {
		$self->SUPER::delete();
		};
	};

1;

=pod

=head1 NAME

Apache::Session::DBMS - An implementation of Apache::Session using DBMS

=head1 SYNOPSIS

 use Apache::Session::DBMS;

 tie %s, 'Apache::Session::DBMS', $sessionid, {
 	'DataSource => 'sessions',
 	'Host' => 'localhost',
        'Port' => 1234
        };

 # or
 use DBMS;
 tie %s, 'Apache::Session::DBMS', $sessionid, {
 	'DataSource => 'dbms://localhost:1234/sessions',
        'Mode' => &DBMS::XSMODE_RDONLY #makes write operations failing
        };
 
 # or if you want to deal with 'object-per-key'
 tie %s, 'Apache::Session::DBMS', "dbms://localhost:1234/sessions/$sessionid";

 #or, if your handles are already opened:

 tie %s, 'Apache::Session::DBMS', $sessionid, {
 	'Handle' => tied(%mydbms)
 	};

 undef %s;

=head1 DESCRIPTION

This module is an implementation of Apache::Session. It uses DBMS to store session variables on a remote hashed storage
and no locking.

The advantage of this is that it is fairly fast and allow to share session information across different machines in very
cheap way without requiring a full-blown RDBMS solution. The backend storage is implemented using BerkeleyDB database files.

See also the documentation for Apache::Session::Store::DBMS for more details.

=head1 OBJECT-PER-KEY

The Apache::Session::DBMS module extends the core Apache::Session to deal object-per-key storage; to explain, the built in
Apache::Session::Store::DB_File by default just store one single key per DB file which corresponds to the actual
session identifier. This is can be too restrictive if the session DB is being used to store misc information like a more
persistent user profile for example or some global information to exchange between Apache processes. By using the original
Apache::Session model one would need to "invent" a session-identifer and use that to refer to ad-hoc info stored into it
(see the Apache:Session documentation for some hints). And then store all information into that key as a single, possibly big, BLOB
serialized/de-serialzied as needed. Instead, what would be more useful is to "go one level down" and let the session model
to deal with the perltie tied hash keys and serialize/de-serialize those separatly. This of course has the drawback that
each write operation on the virtual hash (STORE basically) need to serialize/de-serialize the object associated to the key.
To achive this the Apache::Session::DBMS module allows to define custom session-identifiers using the following notation:

	dbms://<HOSTNAME>:<PORT>/<IDENTIFIER>

HOSTNAME is the tcp/ip IP/FQHN of the machine running the dbmsd deamon - PORT is the port is listening to. While IDENTIFIER
is the name of the DB (which might or might not correspond to a unique session-identifier). For example, the following would
store into an Apache::Session some global information on 'foo.bar.com' port '1234' DB name 'global':

	tie %global, "Apache::Session::DBMS", 'dbms://foo.bar.com:1234/global';

	$global{ 'some preference' } = 'some value';
	$global{ 'some struct' } = { 'foo' => [ 'bar', 2, 3], 'baz' => 'value' };

	undef %global;

or if we would have one unique session DB_File one could write

	tie %session, "Apache::Session::DB_File", $session_id, {
		'DataSource' => 'sessions',
		};

	$session{ 'user preference' } = 'some value';
	$session{ 'some user defined struct' } = { 'foo' => [ 'bar', 2, 3], 'baz' => 'value' };

	undef %session;

which would be the similarly mapped into a remote DBMS hash as:

	tie %session, "Apache::Session::DBMS", $session_id, {
		'DataSource' => 'sessions',
		'Port' => 1234,
		'Host' => 'foo.bar.com'
		};

or even

	tie %session, "Apache::Session::DBMS", $session_id, {
		'DataSource' => 'dbms://foo.bar.com:1234/sessions'
		};

If one need am 'object-per-key' remote hash instead:

	tie %session, "Apache::Session::DBMS", 'dbms://foo.bar.com:1234/sessions';

	$session{ $session_id } = {
		'user preference' => 'some value',
		'some user defined struct' => { 'foo' => [ 'bar', 2, 3], 'baz' => 'value' }
		};

	undef %session;

When the 'object-per-key' mode is on the invocation of delete() method will trigger a physical DROP
operation on the corresponding dbmsd database.

=head1 USAGE

The special Apache::Session arguments for this module are Host, Port, Mode....

=head1 AUTHOR

This module was written by Alberto Reggiori <alberto@asemantics.com>

=head1 SEE ALSO

L<Apache::Session>, L<DBMS>,
http://rdfstore.sf.net/dbms.html
