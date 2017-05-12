#   -*- perl -*-
#
#
#   DBD::pNET - DBI network driver
#
#   pNET.pm contains the perl based extension part
# 
# 
#   Copyright (c) 1997  Jochen Wiedmann
#
#   Based on DBD::Oracle, which is
#
#   Copyright (c) 1994,1995,1996,1997 Tim Bunce
#
#   You may distribute under the terms of either the GNU General Public
#   License or the Artistic License, as specified in the Perl README file,
#   with the exception that it cannot be placed on a CD-ROM or similar media
#   for commercial distribution without the prior approval of the author.
#
#
#   Author: Jochen Wiedmann
#           Am Eisteich 9
#           72555 Metzingen
#           Germany
# 
#           Email: wiedmann@neckar-alb.de
#           Phone: +49 7123 14881
# 
# 
#   $Id: pNET.pm,v 1.3 1997/09/19 20:35:56 joe Exp $
#

require 5.002;

{
    package DBD::pNET;

    use DBI ();
    use IO::Socket ();
    use RPC::pClient ();
    use DynaLoader ();
    @ISA = qw(DynaLoader);

    $VERSION = 0.1003;

    require_version DBI 0.86;

    bootstrap DBD::pNET $VERSION;

    $err = 0;		# holds error code   for DBI::err
    $errstr = "";	# holds error string for DBI::errstr
    $drh = undef;	# holds driver handle once initialised

    sub driver{
	return $drh if $drh;
	my($class, $attr) = @_;

	$class .= "::dr";

	# not a 'my' since we use it above to prevent multiple drivers

	$drh = DBI::_new_drh($class, {
	    'Name' => 'pNET',
	    'Version' => $VERSION,
	    'Err'    => \$DBD::pNET::err,
	    'Errstr' => \$DBD::pNET::errstr,
	    'Attribution' => 'pNET DBD by Jochen Wiedmann',
	    });

	$drh;
    }

    sub AUTOLOAD {
	my $constname;
	($constname = $AUTOLOAD) =~ s/.*:://;
	my $val = constant($constname, @_ ? $_[0] : 0);
	if ($! != 0) {
	    if ($! =~ /Invalid/) {
		$AutoLoader::AUTOLOAD = $AUTOLOAD;
		goto &AutoLoader::AUTOLOAD;
	    } else {
		die "Your vendor has not defined constant $constname";
	    }
	}
	eval "sub $AUTOLOAD { $val }";
	goto &$AUTOLOAD;
    }

    1;
}


{   package DBD::pNET::dr; # ====== DRIVER ======
    use strict;

    sub connect {
	my($drh, $dbname, $user, $auth)= @_;
	my($dsnOrig) = $dbname;
	my($hostname, $port, $key, $cipher, $dsn, $usercipher, $userkey);
	my($debug) = 0;

	while ($dbname ne '') {
	    my ($field, $remaining);
	    if ($dbname =~ /:/) {
		$field = $`;
		$remaining = $';
	    } else {
		$field = $dbname;
		$remaining = '';
	    }

	    if ($field =~ /^hostname=/) {
		$hostname = $';
	    } elsif ($field =~ /^port=/) {
		$port = $';
	    } elsif ($field =~ /^usercipher=/) {
		$usercipher = $';
	    } elsif ($field =~ /^cipher=/) {
		$cipher = $';
	    } elsif ($field =~ /^userkey=/) {
		$userkey = $';
	    } elsif ($field =~ /^key=/) {
		$key = $';
	    } elsif ($field =~ /^dsn=/) {
		$dsn = substr($dbname, 4);
		last;
	    } elsif ($field =~ /^debug=/) {
		$debug = $' ? 1 : 0;
	    }
	    $dbname = $remaining;
	}

	if (!defined($hostname)) {
	    $DBD::pNET::errstr = "Missing hostname";
	    return undef;
	}
	if (!defined($port)) {
	    $DBD::pNET::errstr = "Missing port";
	    return undef;
	}
	if (!defined($dsn)) {
	    $DBD::pNET::errstr = "Missing remote dsn";
	    return undef;
	}

	# Create a cipher object, if requested
	my $cipherRef = undef;
	if ($cipher) {
	    $cipherRef = eval "new $cipher(pack('H*', \$key))";
	    if ($@) {
		$DBD::pNET::errstr = "Cannot create cipher object: $@";
		return undef;
	    }
	}
	my $userCipherRef = undef;
	if ($usercipher) {
	    $userCipherRef = eval "new $usercipher(pack('H*', \$userkey))";
	    if ($@) {
		$DBD::pNET::errstr = "Cannot create cipher object: $@";
		return undef;
	    }
	}

	# Create an IO::Socket object
	my $sock;
	$sock = IO::Socket::INET->new('Proto' => 'tcp',
				      'PeerAddr' => $hostname,
				      'PeerPort' => $port);
	if (!$sock) {
	    $DBD::pNET::errstr = "Cannot connect: $!";
	    print STDERR "$DBD::pNET::errstr\n";
	    return undef;
	}

	my $client = RPC::pClient->new('sock' => $sock,
				       'application' => $dsn,
				       'user' => $user,
				       'password' => $auth,
				       'version', $DBD::pNET::VERSION,
				       'cipher' => $cipherRef,
				       'debug' => $debug);
	if (!ref($client)) {
	    $DBD::pNET::errstr = "Cannot log in to DBD::pNET agent: $client";
	    return undef;
	}

	# create a 'blank' dbh

	my $this = DBI::_new_dbh($drh, { 'Name' => $dsnOrig,
					 'hostname' => $hostname,
					 'port' => $port,
					 'user' => $user,
					 'dsn' => $dsn,
					 'cipher' => $cipher,
					 'usercipher' => $usercipher,
					 'userkey' => $userkey,
					 'userCipherRef' => $userCipherRef,
					 'client' => $client,
					 'key' => $key,
					 'debug' => $debug
				       });

	DBD::pNET::db::_login($this, $dsn, $user, $auth)
	    or return undef;

	$this;
    }
}


{   package DBD::pNET::db; # ====== DATABASE ======
    use strict;

    sub prepare {
	my($dbh, $statement, @attribs)= @_;

	# create a 'blank' dbh

	my $sth = DBI::_new_sth($dbh, {
	    'Statement' => $statement,
	    });

	DBD::pNET::st::_prepare($sth, $statement, @attribs)
	    or return undef;

	$sth;
    }
}


{   package DBD::pNET::st; # ====== STATEMENT ======
    use strict;

    sub errstr {
	return $DBD::pNET::errstr;
    }
}

1;

__END__

=head1 NAME

DBD::pNET - Perl network database driver for the DBI module

=head1 SYNOPSIS

  use DBI;

  $dbh = DBI->connect("dbi:pNET:hostname=$host:port=$port:dsn=$db",
                      $user, $passwd);

  # See the DBI module documentation for full details

=head1 DESCRIPTION

DBD::pNET is a Perl module for connecting to a database via a remote
DBI driver. This is of course not needed for DBI drivers which
already support connecting to a remote database, but there are
DBI drivers which work with local databases only, for example
DBD::ODBC.

=head1 CONNECTING TO THE DATABASE

Before connecting to a remote database, you must ensure, that a
pNET agent is running on the remote machine. There's no default
port, so you have to ask your system administrator for the port
number.

Say, your pNET agent is running on machine "alpha", port 3334,
and you'd like to connect to an ODBC database called "mydb"
as user "joe" with password "hello". When using DBD::ODBC
directly, you'd do a

  $dbh = DBI->connect("DBI:ODBC:mydb", "joe", "hello");

With DBD::pNET this becomes

  $dsn = "DBI:pNET:hostname=alpha:port=3334:dsn=DBI:ODBC:mydb";
  $dbh = DBI->connect($dsn, "joe", "hello");

You see, this is mainly the same. The DBD::pNET module will create
a connection to the pNET agent on "alpha" which in turn will
connect to the ODBC database.

DBD::pNET's DSN string has the format

  $dsn = "DBI:pNET:key1=val1: ... :keyN=valN:dsn=valDSN";

In other words, it is a collection of key/value pairs. The following
keys are recognized:

=over 4

=item hostname

=item port

Hostname and port of the pNET agent; these keys must be present,
no defaults. Example:

    hostname=alpha:port=3334

=item dsn

The value of this attribute will be used as a dsn name by the pNET
agent. Thus it must have the format C<DBI:driver:...>, in particular
it will contain colons. For this reason the I<dsn> key must be
the last key and its value will be the the complete remaining part
of the line, regardless of colons or other characters. Example:

    dsn=DBI:ODBC:mydb

=item cipher

=item key

=item usercipher

=item userkey

By using these fields you can enable encryption. If you set,
for example,

    cipher=$class:key=$key

then DBD::pNET will create a new cipher object by executing

    $cipherRef = $class->new(pack("H*", $key));

and pass this object to the RPC::pClient module when creating a
client. See L<RPC::pClient(3)>. Example:

    cipher=IDEA:key=97cd2375efa329aceef2098babdc9721

The usercipher/userkey attributes allow you to use two phase
encryption: The cipher/key encryption will be used in the
login and authorisation phase. Once the client is authorised,
he will change to usercipher/userkey encryption. Thus the
cipher/key pair is a B<host> based secret, typically less secure
than the usercipher/userkey secret and readable by anyone.
The usercipher/userkey secret is B<your> private secret.

Of course encryption requires an appropriately configured
server. See <pNETagent(3)/CONFIGURATION FILE>.

=item debug

Turn on debugging mode

=back

=head1 SEE ALSO

L<DBI(3)>, L<RPC::pClient(3)>, L<IO::Serialize(3)>

=head1 AUTHOR

Jochen Wiedmann, wiedmann@neckar-alb.de

=head1 COPYRIGHT

The DBD::pNET module is Copyright (c) 1997 Jochen Wiedmann. Parts of
the sources are based on the DBD::Oracle module. The DBD::Oracle module
is Copyright (c) 1995,1996,1997 Tim Bunce. England.

The DBD::pNET module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself with the exception that it
cannot be placed on a CD-ROM or similar media for commercial distribution
without the prior approval of the author.

=head1 ACKNOWLEDGEMENTS

See also L<DBI/ACKNOWLEDGEMENTS>.

=cut
