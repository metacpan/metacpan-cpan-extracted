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
package CPAN::WWW::Top100::Retrieve::Dist;
$CPAN::WWW::Top100::Retrieve::Dist::VERSION = '1.001';
our $AUTHORITY = 'cpan:APOCAL';

# ABSTRACT: Describes a dist in the Top100

# import the Moose stuff
use Moose;
use MooseX::StrictConstructor 0.08;
use namespace::autoclean;

has 'type' => (
	isa		=> 'Str',
	is		=> 'ro',
	required	=> 1,
);

has 'dbid' => (
	isa		=> 'Int',
	is		=> 'ro',
	required	=> 1,
);

# Common to all types
has 'rank' => (
	isa		=> 'Int',
	is		=> 'ro',
	required	=> 1,
);

has 'author' => (
	isa		=> 'Str',
	is		=> 'ro',
	required	=> 1,
);

has 'dist' => (
	isa		=> 'Str',
	is		=> 'ro',
	required	=> 1,
);

has 'score' => (
	isa		=> 'Int',
	is		=> 'ro',
	required	=> 1,
);

# from Moose::Manual::BestPractices
no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=for :stopwords Apocalypse dbid dist debian

=head1 NAME

CPAN::WWW::Top100::Retrieve::Dist - Describes a dist in the Top100

=head1 VERSION

  This document describes v1.001 of CPAN::WWW::Top100::Retrieve::Dist - released November 06, 2014 as part of CPAN-WWW-Top100-Retrieve.

=head1 SYNOPSIS

	#!/usr/bin/perl
	use strict; use warnings;
	use CPAN::WWW::Top100::Retrieve;

	my $top100 = CPAN::WWW::Top100::Retrieve->new;
	foreach my $dist ( @{ $top100->list( 'heavy' ) } ) {
		print "Heavy dist(" . $dist->dist . ") rank(" . $dist->rank .
			") author(" . $dist->author . ") score(" .
			$dist->score . ")\n";
	}

=head1 DESCRIPTION

This module holds the info for a distribution listed in the Top100.

=head2 Attributes

Those attributes hold information about the distribution.

=head3 type

The type of Top100 this dist is listed on.

Example: heavy

=head3 dbid

The dbid of Top100 this dist is listed on.

Example: 1

=head3 rank

The rank of this dist on the Top100 list.

Example: 81

=head3 author

The author of this dist.

Example: LBROCARD

=head3 dist

The distribution name.

Example: Tapper-MCP

=head3 score

The score of the distribution on the Top100 list.

Example: 153

If the type is: heavy

	The score is the number of downstream dependencies

If the type is: volatile, debian, downstream, meta1/2/3

	The score is the number of dependent modules

If the type is: fail

	The score is the FAIL score

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
