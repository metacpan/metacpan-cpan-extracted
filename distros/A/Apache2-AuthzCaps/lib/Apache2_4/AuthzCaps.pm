package Apache2_4::AuthzCaps;

use 5.014000;
use strict;
use warnings;

our $VERSION = '0.002';

use Apache2::AuthzCaps 'hascaps';
use Apache2::Const qw/AUTHZ_GRANTED AUTHZ_DENIED AUTHZ_DENIED_NO_USER/;
use Apache2::RequestRec;
use Apache2::RequestUtil;

##################################################

# General handler template stolen from Apache2_4::AuthCookie
sub handler {
	my ($r, $caps) = @_;
	my $user = $r->user;
	local $Apache2::AuthzCaps::rootdir = $r->dir_config('AuthzCapsRootdir');
	return AUTHZ_DENIED_NO_USER unless $user;
	my @caps = split ' ', $caps;
	hascaps($user, @caps) ? AUTHZ_GRANTED : AUTHZ_DENIED
}

1;
__END__

=encoding utf-8

=head1 NAME

Apache2_4::AuthzCaps - mod_perl2 capability authorization for Apache 2.4

=head1 SYNOPSIS

  # In Apache2 config
  PerlAddAuthzProvider cap Apache2_4::AuthzCaps
  <Location /protected>
    # Insert authentication here
    PerlSetVar AuthzCapsRootdir /path/to/user/directory
    Require cap staff important
    Require cap admin
  </Location>
  # This will:
  # 1) Let important staff members access /protected
  # 2) Let admins access /protected
  # 3) Not let anyone else (such as an important non-staff member or an non-important staff member) access /protected

=head1 DESCRIPTION

Apache2_4::AuthzCaps is a modification of L<Apache2::AuthzCaps> for
Apache 2.4. See that module's documentation for helper functions and
more information.

=head1 AUTHOR

Marius Gavrilescu, E<lt>marius@ieval.roE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013-2015 by Marius Gavrilescu

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.
