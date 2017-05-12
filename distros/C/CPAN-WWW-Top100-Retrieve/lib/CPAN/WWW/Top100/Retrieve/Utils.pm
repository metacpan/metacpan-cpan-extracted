#
# This file is part of CPAN-WWW-Top100-Retrieve
#
# This software is copyright (c) 2014 by Apocalypse.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use strict; use warnings;
# Declare our package
package CPAN::WWW::Top100::Retrieve::Utils;
$CPAN::WWW::Top100::Retrieve::Utils::VERSION = '1.001';
our $AUTHORITY = 'cpan:APOCAL';

# ABSTRACT: Provides util functions

# set ourself up for exporting
use parent qw( Exporter );
our @EXPORT_OK = qw( default_top100_uri
	dbid2type type2dbid types dbids
);

sub default_top100_uri {
	return 'http://ali.as/top100/data.html';
}

# hardcoded from CPAN::WWW::Top100::Generator v0.08
my %dbid_type = (
	1	=> 'heavy',
	2	=> 'volatile',
	3	=> 'debian',
	4	=> 'downstream',
	5	=> 'meta1',
	6	=> 'meta2',
	7	=> 'meta3',
	8	=> 'fail',
);
my %type_dbid;
foreach my $k ( keys %dbid_type ) {
	$type_dbid{ $dbid_type{ $k } } = $k;
}

sub dbid2type {
	my $id = shift;
	if ( exists $dbid_type{ $id } ) {
		return $dbid_type{ $id };
	} else {
		return;
	}
}
sub type2dbid {
	my $type = shift;
	if ( exists $type_dbid{ $type } ) {
		return $type_dbid{ $type };
	} else {
		return;
	}
}

sub types {
	return [ keys %type_dbid ];
}

sub dbids {
	return [ keys %dbid_type ];
}

1;

__END__

=pod

=encoding UTF-8

=for :stopwords Apocalypse Top100 IDs dbid dbids uri

=head1 NAME

CPAN::WWW::Top100::Retrieve::Utils - Provides util functions

=head1 VERSION

  This document describes v1.001 of CPAN::WWW::Top100::Retrieve::Utils - released November 06, 2014 as part of CPAN-WWW-Top100-Retrieve.

=head1 SYNOPSIS

	#!/usr/bin/perl
	use strict; use warnings;
	use CPAN::WWW::Top100::Retrieve::Utils qw( default_top100_uri );
	print "The default Top100 uri is: " . default_top100_uri() . "\n";

=head1 DESCRIPTION

This module holds the various utility functions used in the Top100 modules. Normally you wouldn't
need to use this directly.

=head2 Methods

=head3 default_top100_uri

Returns the Top100 uri we use to retrieve data.

The current uri is:

	return 'http://ali.as/top100/data.html';

=head3 types

Returns an arrayref of Top100 database types.

The current types is:

	return [ qw( heavy volatile debian downstream meta1 meta2 meta3 fail ) ];

=head3 dbids

Returns an arrayref of Top100 database type IDs.

The current dbids is:

	return [ qw( 1 2 3 4 5 6 7 8 ) ];

=head3 dbid2type

Returns the type given a dbid.

=head3 type2dbid

Returns the dbid given a type.

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<CPAN::WWW::Top100::Retrieve|CPAN::WWW::Top100::Retrieve>

=back

=head1 AUTHOR

Apocalypse <APOCAL@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Apocalypse.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

The full text of the license can be found in the
F<LICENSE> file included with this distribution.

=head1 DISCLAIMER OF WARRANTY

THERE IS NO WARRANTY FOR THE PROGRAM, TO THE EXTENT PERMITTED BY
APPLICABLE LAW.  EXCEPT WHEN OTHERWISE STATED IN WRITING THE COPYRIGHT
HOLDERS AND/OR OTHER PARTIES PROVIDE THE PROGRAM "AS IS" WITHOUT WARRANTY
OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO,
THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
PURPOSE.  THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE PROGRAM
IS WITH YOU.  SHOULD THE PROGRAM PROVE DEFECTIVE, YOU ASSUME THE COST OF
ALL NECESSARY SERVICING, REPAIR OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MODIFIES AND/OR CONVEYS
THE PROGRAM AS PERMITTED ABOVE, BE LIABLE TO YOU FOR DAMAGES, INCLUDING ANY
GENERAL, SPECIAL, INCIDENTAL OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE
USE OR INABILITY TO USE THE PROGRAM (INCLUDING BUT NOT LIMITED TO LOSS OF
DATA OR DATA BEING RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD
PARTIES OR A FAILURE OF THE PROGRAM TO OPERATE WITH ANY OTHER PROGRAMS),
EVEN IF SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut
