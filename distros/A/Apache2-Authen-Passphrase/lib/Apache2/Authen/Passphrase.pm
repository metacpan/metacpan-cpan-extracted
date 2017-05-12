package Apache2::Authen::Passphrase;

use 5.014000;
use strict;
use warnings;
use parent qw/Exporter/;
use subs qw/OK HTTP_UNAUTHORIZED/;

our $VERSION = 0.002002;

use constant USER_REGEX => qr/^\w{2,20}$/pas;
use constant PASSPHRASE_VERSION => 1;
use constant INVALID_USER => "invalid-user\n";
use constant BAD_PASSWORD => "bad-password\n";

use if $ENV{MOD_PERL}, 'Apache2::RequestRec';
use if $ENV{MOD_PERL}, 'Apache2::RequestUtil';
use if $ENV{MOD_PERL}, 'Apache2::Access';
use if $ENV{MOD_PERL}, 'Apache2::Const' => qw/OK HTTP_UNAUTHORIZED/;
use Authen::Passphrase;
use Authen::Passphrase::BlowfishCrypt;
use YAML::Any qw/LoadFile DumpFile/;

our @EXPORT_OK = qw/pwset pwcheck pwhash USER_REGEX PASSPHRASE_VERSION INVALID_USER BAD_PASSWORD/;

##################################################

our $rootdir;
$rootdir //= $ENV{AAP_ROOTDIR};

sub pwhash{
	my ($pass)=@_;

	my $ppr=Authen::Passphrase::BlowfishCrypt->new(
		cost => 10,
		passphrase => $pass,
		salt_random => 1,
	);

	$ppr->as_rfc2307
}

sub pwset{
	my ($user, $pass)=@_;

	my $file = "$rootdir/$user.yml";
	my $conf = eval { LoadFile $file } // undef;
	$conf->{passphrase}=pwhash $pass;
	$conf->{passphrase_version}=PASSPHRASE_VERSION;
	DumpFile $file, $conf;

	chmod 0660, $file;
}

sub pwcheck{
	my ($user, $pass)=@_;
	die INVALID_USER unless $user =~ USER_REGEX; ## no critic (RequireCarping)
	$user=${^MATCH};                             # Make taint shut up
	my $conf=LoadFile "$rootdir/$user.yml";

	## no critic (RequireCarping)
	die BAD_PASSWORD unless keys %$conf;          # Empty hash means no such user
	die BAD_PASSWORD unless Authen::Passphrase->from_rfc2307($conf->{passphrase})->match($pass);
	## use critic
	pwset $user, $pass if $conf->{passphrase_version} < PASSPHRASE_VERSION
}

sub handler{
	my $r=shift;
	local $rootdir = $r->dir_config('AuthenPassphraseRootdir');

	my ($rc, $pass) = $r->get_basic_auth_pw;
	return $rc unless $rc == OK;

	my $user=$r->user;
	unless (eval { pwcheck $user, $pass; 1 }) {
		$r->note_basic_auth_failure;
		return HTTP_UNAUTHORIZED
	}

	OK
}

1;
__END__

=head1 NAME

Apache2::Authen::Passphrase - basic authentication with Authen::Passphrase

=head1 SYNOPSIS

  use Apache2::Authen::Passphrase qw/pwcheck pwset pwhash/;
  $Apache2::Authen::Passphrase::rootdir = "/path/to/user/directory"
  my $hash = pwhash $username, $password;
  pwset $username, "pass123";
  eval { pwcheck $username, "pass123" };

  # In Apache2 config
  <Location /secret>
    PerlAuthenHandler Apache2::Authen::Passphrase
    PerlSetVar AuthenPassphraseRootdir /path/to/user/directory
    AuthName MyAuth
    Require valid-user
  </Location>

=head1 DESCRIPTION

Apache2::Authen::Passphrase is a perl module which provides easy-to-use Apache2 authentication. It exports some utility functions and it contains a PerlAuthenHandler.

The password hashes are stored in YAML files in an directory (called the C<rootdir>), one file per user.

Set the C<rootdir> like this:

  $Apache2::Authen::Passphrase::rootdir = '/path/to/rootdir';

or by setting the C<AAP_ROOTDIR> enviroment variable to the desired value.

=head1 FUNCTIONS

=over

=item B<pwhash>()

Takes the password as a single argument and returns the password hash.

=item B<pwset>(I<$username>, I<$password>)

Sets the password of $username to $password.

=item B<pwcheck>(I<$username>, I<$password>)

Checks the given username and password, throwing an exception if the username is invalid or the password is incorrect.

=item B<handler>

The PerlAuthenHandler for use in apache2. It uses Basic Access Authentication.

=item B<USER_REGEX>

A regex that matches valid usernames. Usernames must be at least 2 characters, at most 20 characters, and they may only contain word characters (C<[A-Za-z0-9_]>).

=item B<INVALID_USER>

Exception thrown if the username does not match C<USER_REGEX>.

=item B<BAD_PASSWORD>

Exception thrown if the password is different from the one stored in the user's yml file.

=item B<PASSPHRASE_VERSION>

The version of the passphrase. It is incremented each time the passphrase hashing scheme is changed. Versions so far:

=over

=item Version 1 B<(current)>

Uses C<Authen::Passphrase::BlowfishCrypt> with a cost factor of 10

=back

=back

=head1 ENVIRONMENT

=over

=item AAP_ROOTDIR

If the C<rootdir> is not explicitly set, it is taken from this environment variable.

=back

=head1 AUTHOR

Marius Gavrilescu, E<lt>marius@ieval.roE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013-2015 by Marius Gavrilescu

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.


=cut
