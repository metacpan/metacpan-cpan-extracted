# $Id: RaiseError.pm,v 1.2 2006/01/23 21:40:39 dk Exp $

package DBIx::Roles::RaiseError;

use strict;
use DBIx::Roles;
use vars qw($VERSION);

$VERSION = '1.00';

sub rewrite
{
	my ( $self, $storage, $method, $parameters) = @_;
	if ( $method eq 'connect') {
		$parameters->[3]->{PrintError} = 0 unless exists $parameters->[3]->{PrintError};
		$parameters->[3]->{RaiseError} = 1 unless exists $parameters->[3]->{RaiseError};
	}
	return $self-> super( $method, $parameters);
}

1;

__DATA__

=pod

=head1 NAME

DBIx::Roles::RaiseError - change defaults to C<< RaiseError => 1 >>

=head1 DESCRIPTION

The role replaces the (arguably) most used pair of attributes

   { RaiseError => 1, PrintError => 0 }

to C<< DBI-> connect() >> with the role syntax

   use DBIx::Roles qw(MyRole1 MyRole2 ... RaiseError);

just for beautification sake.

=head1 SYNOPSIS

     use DBIx::Roles qw(RaiseError);

=head1 SEE ALSO

L<DBI>, L<DBIx::Roles>

=head1 COPYRIGHT

Copyright (c) 2005 catpipe Systems ApS. All rights reserved.

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 AUTHOR

Dmitry Karasik <dk@catpipe.net>

=cut
