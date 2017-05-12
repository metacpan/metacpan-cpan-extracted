#############################################################################
#                                                                           #
# Sasl Auth Daemon Client module for Perl                                   #
#                                                                           #
# Author: Piotr Klaban <poczta@klaban.torun.pl> (c)2001
# All Rights Reserved. See the Perl Artistic License for copying & usage    #
# policy.                                                                   #
#                                                                           #
# See the file 'Changes' in the distrution archive.                         #
#                                                                           #
#############################################################################

package Authen::CyrusSASL;

use IO::Socket;
use IO::Select;

use vars qw($VERSION @ISA @EXPORT);

require Exporter;
require AutoLoader;

@ISA = qw(Exporter AutoLoader);
@EXPORT = qw(SASL_OK SASL_BADAUTH SASL_FAIL SASL_PWCHECK SASL_AUTHD);
$VERSION = '0.01';

sub SASL_OK       { 0; }  # values from the sasl.h cyrus-sasl's file
sub SASL_BADAUTH  { -13; }
sub SASL_FAIL     { -1; }

sub SASL_PWCHECK  { 1; }
sub SASL_AUTHD    { 2; }

sub new {
	my $class = shift;
	my %h = @_;
	my ($pwpath);
	my $self = {};

	bless $self, $class;

	if (!defined($h{'Type'})) {
		die('Define Type attribute for Authen::CyrusSASL object');
	}

	# default values
	my ($sock_type, $def_dir, $def_file) =
	    ($h{'Type'} == SASL_AUTHD)   ? (SOCK_STREAM, '/var/run/saslauthd', 'mux')
	  : ($h{'Type'} == SASL_PWCHECK) ? (SOCK_DGRAM, '/var/run/pwcheck', 'pwcheck')
	  : die ('Unknown Authen::CyrusSASL object type, use SASL_AUTHD or SASL_PWCHECK');
	  
	$h{'Dir'} = $def_dir if not defined $h{'Dir'};
	
	if (defined($h{'Dir'}) && !-d $h{'Dir'}) {
		$! = 'Directory ' . $h{'Dir'} . ': not found';
		return undef;
	}

	$h{'Path'} = $h{'Dir'} . '/' . $def_file if not defined $h{'Path'};
	
	$pwpath = $h{'Path'};

	if (!-e $pwpath) {
		$! = 'File ' . $pwpath . ': file not found';
		return undef;
	}

	$self->{'type'} = $h{'Type'};
	$self->{'timeout'} = $h{'TimeOut'} ? $h{'TimeOut'} : 5;
	$self->{'sock'} = new IO::Socket::UNIX(
				Type => SOCK_STREAM,
				Peer => $pwpath
	) or return undef;

	$self;
}

sub check_pwd {
	my ($self, $name, $pwd) = @_;
	my ($req, $res, $sh);

	$req = "$name\0$pwd\0";
	$res = ' ' x 1024;

	# send request
	$self->{'sock'}->send ($req) || return SASL_FAIL;

	# recv response
	$sh = new IO::Select($self->{'sock'}) or return SASL_FAIL;
	$sh->can_read($self->{'timeout'}) or return SASL_FAIL;

	recv( $self->{'sock'}, $res, 1024, 0 );
	# sock->recv does not work
	#$self->{'sock'}->recv ($res, 1024, 0) or return SASL_FAIL;

	if (substr($res, 0, 2) ne 'OK') {
	  $! = substr($res, 3);
	  return SASL_BADAUTH;
	}
	
	return SASL_OK;
}

1;
__END__

=head1 NAME

Authen::CyrusSASL - simple Sasl Authen Daemon client facilities

=head1 SYNOPSIS

  use Authen::CyrusSASL;
  
  $p = new Authen::CyrusSASL(Type => SASL_AUTHD, Dir => '/var/run/saslauthd');
  print "check=", $r->check_pwd('username', 'userpass'), "\n";

  $p = new Authen::CyrusSASL(Type => SASL_PWCHECK, Dir => '/var/run/pwcheck');
  print "check=", $r->check_pwd('username', 'userpass'), "\n";

=head1 DESCRIPTION

The C<Authen::CyrusSASL> module provides a simple class that allows you to 
send request to the cyrus-sasl's 2.0 authen daemon.
This module is based on the Authen::Radius module with the similar
interface.

=head1 CONSTRUCTOR

=over 4

=item new ( Type => < SASL_AUTHD | SASL_PWCHECK >,
< Dir => dirpath | Path => sockpath > [, TimeOut => TIMEOUT] )

Creates & returns a blessed reference to a Authen::CyrusSASL object, or undef on
failure.  Error is saved into $!. 
Use undef on the return value if you want to undef the underlying
unix socket.

There are two types for Type attribute - one for saslauth daemon and one for
old pwcheck daemon (SASL_PWCHECK). The Type attribute is obligatory.

The default value for Dir is '/var/run/pwcheck' (it then looks for
the path '/var/run/pwcheck/pwcheck') for pwcheck method,
and '/var/run/saslauthd' (path '/var/run/saslauthd/mux') for saslauthd method.
You can specify the full path for pwcheck or mux special files
with the Path attribute.

The TimeOut value is self explonatory.

=back

=head1 METHODS

=over 4

=item check_pwd ( USERNAME, PASSWORD )

Checks with the SASL server if the specified C<PASSWORD> is valid for user 
C<USERNAME>. It returns SASL_OK if the C<PASSWORD> is correct,
SASL_FAIL if the connection fails, or SASL_BADAUTH if the password or
the username is incorrect (possible error is in the $! variable).

=back

=head1 SEE ALSO

Cyrus-sasl archive located at ftp://ftp.andrew.cmu.edu/pub/cyrus-mail/

=head1 AUTHOR

Piotr Klaban <poczta@klaban.torun.pl>

=cut

