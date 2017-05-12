# $Id: InlineArray.pm,v 1.4 2005/11/30 13:13:37 dk Exp $

# recursively straightens array references into {,,}-strings 
# useful for DBD implementations that cannot do that themselves

package DBIx::Roles::InlineArray;

use strict;
use vars qw($VERSION);

$VERSION = '1.00';

sub inline
{
	map {
		ref($_) ? 
			'{' . join(',', inline(@$_)) . '}' : 
			$_
	} @_
}

sub rewrite
{
	my ( $self, $storage, $method, $params) = @_;
	if (
		$method eq 'do' or
		exists $DBIx::Roles::DBI_select_methods{$method}
	) {
		my $shift = ( $method eq 'selectall_hashref') ? 3 : 2;
		splice( @$params, $shift, $#$params, inline( @$params[ $shift..$#$params ]))
			if $shift < @$params;
	}

	return $self-> super( $method, $params);
}

1;

__DATA__

=head1 NAME

DBIx::Roles::InlineArray - Flattens arrays passed as parameters to DBI calls into strings.

=head1 DESCRIPTION

Recursively straightens array references into {,,}-strings. Useful for DBD
implementations that cannot do that themselves

=head1 SYNOPSIS

     use DBIx::Roles qw(InlineArray);

     my $dbh = DBI-> connect(
           "dbi:Pg:dbname=template1",
	   "postgres",
	   "password",
     );

     $dbh-> do('INSERT INTO moo VALUES(?)', {}, [1,2,3]);

=head1 NOTES

I've only used that module for PostgreSQL, so I've no idea if the array
flattening will work on other databases.

=head1 SEE ALSO

L<DBIx::Roles>.

=head1 COPYRIGHT

Copyright (c) 2005 catpipe Systems ApS. All rights reserved.

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 AUTHOR

Dmitry Karasik <dk@catpipe.net>

=cut

