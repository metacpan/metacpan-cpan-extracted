package Apache::Auth::Subrequest;
use mod_perl2 ;
use Apache2::Access ;
use Apache2::RequestRec ;
use Apache2::RequestUtil ;
use Apache2::Const -compile => qw(HTTP_FORBIDDEN OK) ;
use Carp;
use strict;
use warnings; 

use version; our $VERSION = qv('0.0.1');

=head1 NAME

Apache::Auth::Subrequest - Allow only if a Subrequest !

=head1 SYNOPSIS

	PerlModule Apache::Auth::Subrequest
        <LocationMatch "/z/style/[^/]+/xsl>
		PerlAccessHandler Apache::Auth::Subrequest
        </Location>

=head1 DESCRIPTION

Restrict access control to a site/location/directory that 

=head1 PROBLEMS

This is a very simple approach which allows access to systems from wihtin
Apache only. This is useful for original images being resized or XSL being
applied.

It is howerver not foolproof and should not be trusted. E.g. a module which
runs XSL over XML could be used to grab the original XSL itself.

This module should also allow the opposite - can't think of a good reason now,
but there will be one.

=cut

sub handler {
	my ($r) = @_;
	if ($r->is_initial_req()) {
		return Apache2::Const::HTTP_FORBIDDEN;
	}
	return Apache2::Const::OK;
}

1;
