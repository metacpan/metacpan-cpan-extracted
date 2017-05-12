package Authen::ModAuthPubTkt;
require Exporter;
our @ISA=qw(Exporter);
our @EXPORT = qw/pubtkt_generate
		 pubtkt_verify
		 pubtkt_parse/;

use strict;
use warnings;
use Carp;
use MIME::Base64;
use File::Temp qw/tempfile/;
use IPC::Run3;


# ABSTRACT: A Module to generate Mod-Auth-PubTkt compatible Cookies

=pod

=head1 NAME

Authen::ModAuthPubTkt - Generate Tickets (Signed HTTP Cookies) for mod_auth_pubtkt protected websites.

=head1 VERSION

version 0.1.1

=cut
our $VERSION = '0.1.1';

=pod

=head1 SYNOPSIS

On the command-line, generate the public + private keys:
(More details available at L<https://neon1.net/mod_auth_pubtkt/install.html>)

	$ openssl genrsa -out key.priv.pem 1024
	$ openssl rsa -in key.priv.pem -out key.pub.pem -pubout


Then in your perl script (which is probably the your custom login website), use the following code to issue tickets:

	use Authen::ModAuthPubTkt;

	my $ticket = pubtkt_generate(
		privatekey => "key.priv.pem",
		keytype    => "rsa",
		clientip   => undef,  # or a valid IP address
		userid     => "102",  # or any ID that makes sense to your application, e.g. email
		validuntil => time() + 86400, # valid for one day
		graceperiod=> 3600,   # grace period of an hour
		tokens     => undef,  # comma separated string of tokens.
		userdata   => undef   # any application specific data to pass.
	);

	## $ticket string will look something like:
	## "uid=102;validuntil=1337899939;graceperiod=1337896339;tokens=;udata=;sig=h5qR" \
	## "yZZDl8PfW8wNxPYkcOMlAxtWuEyU5bNAwEFT9lztN3I7V13SaGOHl+U6wB+aMkvvLQiaAfD2xF/Hl" \
	## "+QmLDEvpywp98+5nRS+GeihXTvEMRaA4YVyxb4NnZujCZgX8IBhP6XBlw3s7180jxE9I8DoDV8bDV" \
	## "k/2em7yMEzLns="


To verify a ticket, use the following code:

	my $ok = pubtkt_verify (
		publickey => "key.pub.pem",
		keytype   => "rsa",
		ticket    => $ticket
	);
	die "Ticket verification failed.\n" if not $ok;

To extract items from a ticket, use the following code:

	my %items = pubtkt_parse($ticket);

	## %items will be something like:
	## {
	##    'uid' => 102,
	##    'validuntil' => 1337899939,
	##    'graceperiod => 1337896339,
	##    'tokens' => "",
	##    'udata'  => "",
	##    'sig'    => 'h5qRyZZDl8PfW8wNxPYkcOMlAxtWuEyU5bNAwEFT9lztN3 (....)'
	## }


Also, a command-line utility (C<mod_auth_pubtkt.pl>) will be installed, and can be used to generate/verify keys:

	$ mod_auth_pubtkt.pl --generate --private-key key.priv.pem --rsa
	$ mod_auth_pubtkt.pl --verify --public-key key.pub.pem --rsa
	$ mod_autH_pubtkt.pl --help


=head1 DESCRIPTION

This module generates and verify a mod_auth_pubtkt-compatible ticket string, which should be used
as a cookie with the rest of the B<mod_auth_pubtkt> ( L<https://neon1.net/mod_auth_pubtkt/> ) system.

=head3 Common scenario:

=over 2

=item 1.
On the login server side, write perl code to authenticate users (using Apache's authenetication, LDAP, DB, etc.).

=item 2.
Once the user is authenticated, call C<pubtkt_generate> to generate a ticket, and send it back to the user as a cookie.

=item 3.
Redirect the user back to the server he/she came from.

=back


=head1 Working Example

A working (but minimal) perl login example is available at L<https://github.com/manuelkasper/mod_auth_pubtkt/blob/master/perl-login/minimal_cgi/login.pl>

=cut


## On unix, assume it's on the $PATH.
## On Windows - you're on your own.
## TODO: make this user-configurable.
my $openssl_bin = "openssl";

=pod

=head1 METHODS

=head2 pubtkt_generate

Generates a signed ticket.

If successful, returns a signed ticket string (to be sent back to the user as a cookie).

On any failure (bad key, failure to run C<openssl>, etc.) returns C<undef>.

Accepts a hash of parameters:

=over 4

=item B<privatekey>

String containing the private key filename (full path). The key can be either DSA or RSA key (see B<keytype>).

=item B<keytype>

either "rsa" or "dsa" - depending on how you created the private/public key files.

=item B<userid>

String containing the user ID. No specific format is enforced: can by a number, a string, an email address, etc. It will be encoded as "uid=XXXX" in the signed ticket.

=item B<validuntil>

Numeric value, containing the validity period, in seconds since epoch (use C<time()> function).

=item B<graceperiod>

Optional. Numeric value. If given, will be added to the signed ticket string.

=item B<clientip>

Optional. A string with an IP address. If given. will be added to the signed ticket string.

=item B<token>

Optional. Any textual string. If given. will be added to the signed ticket string.

=item B<userdata>

Optional. Any textual string. If given. will be added to the signed ticket string.

=back

=cut
sub pubtkt_generate
{
	my %args = @_;
	my $private_key_file = $args{privatekey} or croak "Missing \"privatekey\" parameter";
	croak "Invalid \"privatekey\" value ($private_key_file): file doesn't exist/not readable"
		unless -r $private_key_file;

	my $keytype = $args{keytype} or croak "Missing \"keytype\" parameter";
	croak "Invalid \"keytype\" value ($keytype): expecting 'dsa' or 'rsa'\n"
		unless $keytype eq "dsa" || $keytype eq "rsa";

	my $user_id = $args{userid} or croak "Missing \"userid\" parameter";

	my $valid_until = $args{validuntil} or croak "Missing \"validuntil\" parameter";
	croak "Invalid \"validuntil\" value ($valid_until), expecting a numeric value."
		unless $valid_until =~ /^\d+$/;

	my $grace_period = $args{graceperiod} || "";
	croak "Invalid \"graceperiod\" value ($grace_period), expecting a numeric value."
		unless $grace_period eq "" || $grace_period =~ /^\d+$/;

	my $client_ip = $args{clientip} || "";
	##TODO: better IP address validation
	croak "Invalid \"client_ip\" value ($client_ip), expecting a valid IP address."
		unless $client_ip eq "" || $client_ip =~ /^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$/;

	my $tokens = $args{token} || "";
	my $user_data = $args{userdata} || "";

	# Generate Ticket String
	my $tkt = "uid=$user_id;" ;
	$tkt .= "cip=$client_ip;" if $client_ip;
	$tkt .= "validuntil=$valid_until;";
	$tkt .= "graceperiod=" . ($valid_until - $grace_period) . ";" if $grace_period;
	$tkt .= "tokens=$tokens;";
	$tkt .= "udata=$user_data";

	my $algorithm_param  = ( $keytype eq "dsa" ) ? "-dss1" : "-sha1";

	my @cmd = ( $openssl_bin,
		    "dgst", $algorithm_param,
		    "-binary",
		    "-sign", $private_key_file ) ;

	my ($stdin, $stdout, $stderr);

	$stdin = $tkt;
	run3 \@cmd, \$stdin, \$stdout, \$stderr;
	my $exitcode = $?;

	if ($exitcode != 0) {
		warn "pubtkt_generate failed: openssl returned exit code $exitcode, stderr = $stderr\n";
		return;
	}

	$tkt .= ";sig=" . encode_base64($stdout,""); #2nd param = no EOL.

	return $tkt;
}

=head2 pubtkt_verify

Verifies a signed ticket string.

If successful (i.e. the ticket's signature is valid), returns TRUE (=1).

On any failure (bad key, failure to run C<openssl>, etc.) returns C<undef>.

B<NOTE>: B<This function checks ONLY THE SIGNATURE, based on the public key file. It is the caller's resposibility to check the expiration date.>  That is: The function will return TRUE if the ticket is properly signed, but possibly expired.

Accepts a hash of parameters:

=over 4

=item B<publickey>

String containing the public key filename (full path). The key can be either DSA or RSA key (see B<keytype>).

=item B<keytype>

either "rsa" or "dsa" - depending on how you created the private/public key files.

=item B<ticket>

The string of the ticket (such as returned by C<pubtkt_generate>).

=back

=cut
sub pubtkt_verify
{
	my %args = @_;
	my $public_key_file = $args{publickey} or croak "Missing \"publickey\" parameter";
	croak "Invalid \"publickey\" value ($public_key_file): file doesn't exist/not readable"
		unless -r $public_key_file;

	my $keytype = $args{keytype} or croak "Missing \"keytype\" parameter";
	croak "Invalid \"keytype\" value ($keytype): expecting 'dsa' or 'rsa'\n"
		unless $keytype eq "dsa" || $keytype eq "rsa";
	my $algorithm_param  = ( $keytype eq "dsa" ) ? "-dss1" : "-sha1";

	my $ticket_str = $args{ticket} or croak "Missing \"ticket\" parameter";

	# Extract base64'd signature text
	my ($ticket_data, $sig_base64) = split /;sig=/, $ticket_str;
	warn "Pubtkt.pm: missing \"sig=\" in ticket ($ticket_str)" unless $sig_base64;
	return unless $sig_base64;

	# Decode base64 signature, and store in a temporary file
	my $sig_bin = decode_base64($sig_base64);
	warn "Pubtkt.pm: invalid base64 signature from ticket ($ticket_str)" unless length($sig_bin)>0;

	my ($fh, $temp_sig_file) = tempfile("pubtkt.XXXXXXXXX", UNLINK=>1, TMPDIR=>1);
	print $fh $sig_bin or die "Failed to write signature data: $!";
	close $fh or die "Failed to write signature data: $!";

	# verify signature using openssl
	my @cmd = ( $openssl_bin,
		    "dgst", $algorithm_param,
		    "-verify", $public_key_file,
		    "-signature", $temp_sig_file);
	my ($stdin, $stdout, $stderr);
	$stdin = $ticket_data;
	run3 \@cmd, \$stdin, \$stdout, \$stderr;
	my $exitcode = $?;
	return unless $exitcode == 0;

	return 1 if ( $stdout eq "Verified OK\n" ) ;

	return ;
}

=head2 pubtkt_parse($ticket)

Utility function to parse a ticket string into a Perl hash.

B<NOTE>: No validation is performed. The given ticket might be expired, or even forged.

=cut
sub pubtkt_parse
{
	my $tkt = shift or croak "missing ticket string parameter";
	my @fields = split /;/, $tkt;
	my %values = map { split (/=/, $_, 2) } @fields;
	return %values;
}

=head1 PREREQUISITES

B<openssl> must be installed (and available on the $PATH).

L<IPC::Run3> is required to run the openssl executables.

=head1 BUGS

Probably many.

=head1 TODO

Use Perl's L<Crypt::OpenSSL::RSA> and L<Crypt::OpenSSL::DSA> instead of the running C<openssl> executable.

Don't assume C<openssl> binary is on the $PATH.

Refactor into OO interface.

=head1 LICENSE

Copyright (C) 2012 A. Gordon ( gordon at cshl dot edu ).

Apache License, same as the rest of B<mod_auth_pubtkt>

=head1 AUTHORS

A. Gordon, heavily based on the PHP code from B<mod_auth_pubtkt>.

=head1 SEE ALSO

ModAuthPubTkt main website: L<https://neon1.net/mod_auth_pubtkt/>

ModAuthPubTkt github repository: L<https://github.com/manuelkasper/mod_auth_pubtkt>

This module's github repository: L<https://github.com/agordon/Authen-ModAuthPubTkt>

Examples in the C<./eg> directory:

=over 4

=item B<generate_rsa_keys.sh>

Generates a pair of RSA key files.

=item B<generate_dsa_keys.sh>

Generates a pair of DSA key files.

=item B<mod_auth_pubtkt.pl>

A command-line utility to generate/verify tickets.

=back

=cut

1;
