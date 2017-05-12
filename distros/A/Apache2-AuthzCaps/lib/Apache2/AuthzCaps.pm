package Apache2::AuthzCaps;

use 5.014000;
use strict;
use warnings;
use subs qw/OK DECLINED/;

our $VERSION = '0.002';

use if $ENV{MOD_PERL}, 'Apache2::Access';
use if $ENV{MOD_PERL}, 'Apache2::Const' => qw/OK DECLINED/;
use if $ENV{MOD_PERL}, 'Apache2::RequestRec';
use if $ENV{MOD_PERL}, 'Apache2::RequestUtil';
use YAML::Any qw/LoadFile DumpFile/;

use parent qw/Exporter/;

our @EXPORT_OK = qw/setcap hascaps/;

##################################################

our $rootdir;

sub setcap{
	my ($user, $cap, $value) = @_;
	my $config = eval { LoadFile "$rootdir/$user.yml" } // {};
	$config->{caps}//={};
	my $caps=$config->{caps};

	delete $caps->{$cap} unless $value;
	$caps->{$cap} = 1 if $value;
	DumpFile "$rootdir/$user.yml", $config
}

sub hascaps{
	my ($user, @caps) = @_;
	my $config = LoadFile "$rootdir/$user.yml";
	my $caps = $config->{caps};
	for (@caps) {
		return 0 unless $caps->{$_}
	}
	1
}

sub handler{
	my $r=shift;
	my $user = $r->user;
	local $rootdir = $r->dir_config('AuthzCapsRootdir');

	if ($user) {
		for my $requirement (map { $_->{requirement} } @{$r->requires}) {
			my ($command, @args) = split ' ', $requirement;

			return OK if $command eq 'cap' && hascaps $user, @args;
		}
	}

	DECLINED
}

1;
__END__

=head1 NAME

Apache2::AuthzCaps - mod_perl2 capability authorization

=head1 SYNOPSIS

  use Apache2::AuthzCaps qw/setcap hascaps/;
  $Apache2::AuthzCaps::rootdir = "/path/to/user/directory"
  setcap marius => deleteusers => 1; # Grant marius the deleteusers capability
  setcap marius => createusers => 0;
  hascaps marius => qw/deleteusers/; # returns 1, since marius can delete users
  hascaps marius => qw/deleteusers createusers/; # returns 0, since marius can delete users but cannot create users

  # In Apache2 config
  <Location /protected>
    # Insert authentication here
    PerlAuthzHandler Apache2::AuthzCaps
    PerlSetVar AuthzCapsRootdir /path/to/user/directory
    Require cap staff important
    Require cap admin
  </Location>
  # This will:
  # 1) Let important staff members access /protected
  # 2) Let admins access /protected
  # 3) Not let anyone else (such as an important non-staff member or an non-important staff member) access /protected

=head1 DESCRIPTION

Apache2::AuthzCaps is a perl module which provides simple Apache2 capability-based authorization. It contains a PerlAuthzHandler and some utility functions.

B<< For Apache 2.4, use L<Apache2_4::AuthzCaps>. >>

The user data is stored in YAML files in a user-set directory. Set this directory using:

  $Apache2::AuthzCaps::rootdir = "/path/to/directory"; # From perl
  PerlSetVar AuthzCapsRootdir /path/to/directory # From Apache2 config

=head1 FUNCTIONS

=over

=item B<setcap>(I<$username>, I<$capability>, I<$value>)

If I<$value> is true, grants I<$username> the I<$capability> capability. Otherwise denies I<$username> that capability.

=item B<hascaps>(I<$username>, I<$cap>, ...)

Returns true if and only of I<$username> has ALL of the listed capabilities. Dies if I<$username> does not exist.

=item B<handler>

The PerlAuthzHandler for use in apache2.

=back

=head1 AUTHOR

Marius Gavrilescu, E<lt>marius@ieval.roE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013-2015 by Marius Gavrilescu

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.


=cut
