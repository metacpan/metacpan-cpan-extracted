package Authen::ModAuthToken;
use strict;
use warnings;
require Exporter;
use Carp;
use URI::Escape;
use Digest::MD5 qw/md5_hex/;

our @ISA = qw(Exporter);
our @EXPORT_OK = qw/generate_mod_auth_token/;

our $VERSION = '0.03';

sub generate_mod_auth_token
{
	my %args = @_;

	my $secret = $args{secret} or croak "Missing 'secret' key value";
	my $remote_addr = $args{remote_addr} || "";
	my $filepath = $args{filepath} or croak "Missing 'filepath' key value";
	die "'filepath' key value should start with '/'" unless substr($filepath,0,1) eq "/";

	my $hexTime = sprintf("%08x", time());
	my $token_md5 = md5_hex ( $secret . $filepath . $hexTime . $remote_addr);

	my $encoded_url = "";
	foreach my $part ( split '/', $filepath ) {
		next unless $part;
		$encoded_url .= "/" . uri_escape($part) ;
	}

	my $url = "/" . $token_md5 . "/" . $hexTime . $encoded_url;

	return $url;
}

# ABSTRACT: A Module to generate Mod-Auth-Token compatible URLs

1;
__END__
=pod

=head1 NAME

Authen::ModAuthToken - Generates Mod-Auth-Token compatible URLs

=head1 VERSION

version 0.03

=head1 SYNOPSIS

In your Apache's configuration, define the following:

	## (your module's path may vary)
	LoadModule auth_token_module  /usr/lib/apache2/modules/mod_auth_token.so

	Alias "/protected"  "/my/protected/directory"
	<Location "/protected">
		AuthTokenSecret       "FlyingMonkeys"
		AuthTokenPrefix       /protected/
		AuthTokenTimeout      14400
	</Location>


In a CGI script, use the following:

	use Authen::ModAuthToken qw/generate_mod_auth_token/;

	## If the file wasn't protected with "mod-auth-token",
	## its URL would have been:
	##   http://my.server.com/protected/myfile.txt

	$web_server = "http://my.server.com" ;
	$prefix_url = "/protected";
	$file_to_protect = "/myfile.txt";


	##
	## Since the location is protected with mod-auth-token,
	## Generate a valid access token:
	##
	$token = generate_mod_auth_token(
			secret => "FlyingMonkeys",
			filepath => $file_to_protect ) ;

	$url = $web_server . $prefix_url . $token ;

	## The protected URL will look like
	##   http://my.server.com/protected/6c488f69992206a2b5cc9c6a9cc91709/4f0f7b09/myfile.txt
	## (actual value will change, as it dependant upon the current time).
	##
	## Show this URL to the user, to allow him access to this file.


=head1 DESCRIPTION

This module does not perform the actual authentication - it merely generates a valid authentication token URL, which will be authenticated by the mod_auth_token module.

=head1 FUNCTIONS

=over

=item C<generate_mod_auth_token ( sercet =E<gt> $secret, filepath =E<gt> $path, [ remote_addr =E<gt> $remote_addr ])>

Generates an authentication token, based on given parameters and current time.

B<Parameters>:

C<secret> - The secret key, will be used to calculate the MD5 hash. Must match the key in your apache's configuration.

C<filepath> - The relative URL of the file you want to publish. The path B<must> begin with a slash (C</>) .

C<remote_addr> - (B<optional>) - the remote IP of the client. If you use this option, your apache configuratino should include C<AuthTokenLimitByIp    on> - see the mod-auth-token website for more details.

B<Output>:

The function returns a URL portion of the protected file (see L<synopsis> for an example).

=back

=head1 Examples

The following example files are in the C<./eg/> directory:

=over

=item C<mod_auth_token_example.pl>

prints a mod-auth-token URL. Configuration (server, prefix, key, file) can be set with command-line parameters.

=back

=head1 AUTHOR

Assaf Gordon, C<< <gordon at cshl.edu> >>

=head1 TODO

=over

=item Add OO interface

=back

=head1 BUGS

Please report any bugs or feature requests to
L<https://github.com/agordon/Authen-ModAuthToken/issues>

=head1 SEE ALSO

L<http://code.google.com/p/mod-auth-token/>

=head1 ACKNOWLEDGEMENTS

Thanks to Mikael Johansson (http://www.synd.info) and David Alves (http://www.alvesdavid.com) for creating Mod-Auth-Token.

=head1 LICENSE AND COPYRIGHT

Copyright 2011 Assaf Gordon.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
