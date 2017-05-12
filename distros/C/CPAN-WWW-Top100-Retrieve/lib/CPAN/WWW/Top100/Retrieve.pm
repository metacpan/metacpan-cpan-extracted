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
package CPAN::WWW::Top100::Retrieve;
# git description: f223abe
$CPAN::WWW::Top100::Retrieve::VERSION = '1.001';
our $AUTHORITY = 'cpan:APOCAL';

# ABSTRACT: Retrieves the CPAN Top100 data from http://ali.as/top100

# import the Moose stuff
use Moose;
use MooseX::StrictConstructor 0.08;
use Moose::Util::TypeConstraints;
use Params::Coerce;
use namespace::autoclean;

# get some utility stuff
use LWP::UserAgent;
use URI;
use HTML::TableExtract;

use CPAN::WWW::Top100::Retrieve::Dist;
use CPAN::WWW::Top100::Retrieve::Utils qw( default_top100_uri dbids type2dbid dbid2type );

has 'debug' => (
	isa		=> 'Bool',
	is		=> 'rw',
	default		=> sub { 0 },
);

has 'ua' => (
	isa		=> 'LWP::UserAgent',
	is		=> 'rw',
	required	=> 0,
	lazy		=> 1,
	default		=> sub {
		LWP::UserAgent->new;
	},
);

has 'error' => (
	isa		=> 'Str',
	is		=> 'ro',
	writer		=> '_error',
);

# Taken from Moose::Cookbook::Basics::Recipe5
subtype 'My::Types::URI' => as class_type('URI');

coerce 'My::Types::URI'
	=> from 'Object'
		=> via {
			$_->isa('URI') ? $_ : Params::Coerce::coerce( 'URI', $_ );
		}
	=> from 'Str'
		=> via {
			URI->new( $_, 'http' )
		};

has 'uri' => (
	isa		=> 'My::Types::URI',
	is		=> 'rw',
	required	=> 0,
	lazy		=> 1,
	default		=> sub {
		default_top100_uri();
	},
	coerce		=> 1,
);

has '_data' => (
	isa		=> 'HashRef',
	is		=> 'ro',
	default		=> sub { {} },
);

sub _retrieve {
	my $self = shift;

	# Do we already have data?
	if ( keys %{ $self->_data } > 0 ) {
		warn "Using cached data" if $self->debug;
		return 1;
	} else {
		warn "Starting retrieve run" if $self->debug;
	}

	# Okay, get the data via LWP
	warn "LWP->get( " . $self->uri . " )" if $self->debug;
	my $response = $self->ua->get( $self->uri );
	if ( $response->is_error ) {
		my $errstr = "LWP Error: " . $response->status_line . "\n" . $response->content;
		$self->_error( $errstr );
		warn $errstr if $self->debug;
		return 0;
	}

	# Parse it!
	return $self->_parse( $response->content );
}

sub _parse {
	my $self = shift;
	my $content = shift;

	# Get the tables!
	foreach my $dbid ( sort { $a <=> $b } @{ dbids() } ) {
		warn "Parsing dbid $dbid..." if $self->debug;

		my $table_error;
		my $table = HTML::TableExtract->new( attribs => { id => "ds$dbid" }, error_handle => \$table_error );
		$table->parse( $content );

		if ( ! $table->tables ) {
			my $errstr = "Unable to parse table $dbid";
			$errstr .= " $table_error" if length $table_error;
			$self->_error( $errstr );
			warn $errstr if $self->debug;
			return 0;
		}

		foreach my $ts ( $table->tables ) {
			# Store it in our data struct!
			my %cols;
			foreach my $row ( $ts->rows ) {
				if ( ! keys %cols ) {
					# First row, the headers!
					my $c = 0;
					%cols = map { $_ => $c++ } @$row;
				} else {
					# Make the object!
					my $obj = CPAN::WWW::Top100::Retrieve::Dist->new(
						## no critic ( ProhibitAccessOfPrivateData )
						'dbid'		=> $dbid,
						'type'		=> dbid2type( $dbid ),
						'rank'		=> $row->[ $cols{ 'Rank' } ],
						'author'	=> $row->[ $cols{ 'Author' } ],
						'dist'		=> $row->[ $cols{ 'Distribution' } ],

						# ugly logic here, but needed to "collate" the different report types
						'score'		=> ( exists $cols{ 'Dependencies' } ? $row->[ $cols{ 'Dependencies' } ] :
									( exists $cols{ 'Dependents' } ? $row->[ $cols{ 'Dependents' } ] :
										( exists $cols{ 'Score' } ? $row->[ $cols{ 'Score' } ] : undef ) ) ),
					);

					push( @{ $self->_data->{ $dbid } }, $obj );
				}
			}
		}
	}

	return 1;
}

sub list {
	my $self = shift;
	my $type = shift;

	return if ! defined $type or ! length $type;
	$type = type2dbid( lc( $type ) );
	return if ! defined $type;

	# if we haven't retrieved yet, do it!
	return if ! $self->_retrieve;

	# Generate a copy of our data
	my @r = ( @{ $self->_data->{ $type } } );
	return \@r;
}

# from Moose::Manual::BestPractices
no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=for :stopwords Apocalypse cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee
diff irc mailto metadata placeholders metacpan Top100 AnnoCPAN CPANTS
Kwalitee RT com dists github ua uri

=head1 NAME

CPAN::WWW::Top100::Retrieve - Retrieves the CPAN Top100 data from http://ali.as/top100

=head1 VERSION

  This document describes v1.001 of CPAN::WWW::Top100::Retrieve - released November 06, 2014 as part of CPAN-WWW-Top100-Retrieve.

=head1 SYNOPSIS

	#!/usr/bin/perl
	use strict; use warnings;

	use CPAN::WWW::Top100::Retrieve;
	use Data::Dumper;

	my $top100 = CPAN::WWW::Top100::Retrieve->new;
	print Dumper( $top100->list( 'heavy' ) );

=head1 DESCRIPTION

This module retrieves the data from CPAN Top100 and returns it in a structured format.

=head2 Constructor

This module uses Moose, so you can pass either a hash or hashref to the constructor. The object will cache all
data relevant to the Top100 for as long as it's alive. If you want to get fresh data just make a new object and
use that.

The attributes are:

=head3 debug

( not required )

A boolean value specifying debug warnings or not.

The default is: false

=head3 ua

( not required )

The LWP::UserAgent object to use in place of the default one.

The default is: LWP::UserAgent->new;

=head3 uri

( not required )

The uri of Top100 data we should use to retrieve data in place of the default one.

The default is: CPAN::WWW::Top100::Retrieve::Utils::default_top100_uri()

=head2 Methods

Currently, there is only one method: list(). You call this and get the arrayref of data back. For more
information please look at the L<CPAN::WWW::Top100::Retrieve::Dist> class. You can call list() as
many times as you want, no need to re-instantiate the object for each query.

=head3 list

Takes one argument: the $type of Top100 list and returns an arrayref of dists.

WARNING: list() will return an empty list if errors happen. Please look at the error() method for the string.

Example:

	use Data::Dumper;
	print Dumper( $top100->list( 'heavy' ) );
	print Dumper( $top100->list( 'volatile' ) );

=head3 error

Returns the error string if it was set, undef if not.

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<CPAN::WWW::Top100::Retrieve::Dist>

=item *

L<CPAN::WWW::Top100::Retrieve::Utils>

=back

=head1 SUPPORT

=head2 Perldoc

You can find documentation for this module with the perldoc command.

  perldoc CPAN::WWW::Top100::Retrieve

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

MetaCPAN

A modern, open-source CPAN search engine, useful to view POD in HTML format.

L<http://metacpan.org/release/CPAN-WWW-Top100-Retrieve>

=item *

Search CPAN

The default CPAN search engine, useful to view POD in HTML format.

L<http://search.cpan.org/dist/CPAN-WWW-Top100-Retrieve>

=item *

RT: CPAN's Bug Tracker

The RT ( Request Tracker ) website is the default bug/issue tracking system for CPAN.

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=CPAN-WWW-Top100-Retrieve>

=item *

AnnoCPAN

The AnnoCPAN is a website that allows community annotations of Perl module documentation.

L<http://annocpan.org/dist/CPAN-WWW-Top100-Retrieve>

=item *

CPAN Ratings

The CPAN Ratings is a website that allows community ratings and reviews of Perl modules.

L<http://cpanratings.perl.org/d/CPAN-WWW-Top100-Retrieve>

=item *

CPAN Forum

The CPAN Forum is a web forum for discussing Perl modules.

L<http://cpanforum.com/dist/CPAN-WWW-Top100-Retrieve>

=item *

CPANTS

The CPANTS is a website that analyzes the Kwalitee ( code metrics ) of a distribution.

L<http://cpants.cpanauthors.org/dist/overview/CPAN-WWW-Top100-Retrieve>

=item *

CPAN Testers

The CPAN Testers is a network of smokers who run automated tests on uploaded CPAN distributions.

L<http://www.cpantesters.org/distro/C/CPAN-WWW-Top100-Retrieve>

=item *

CPAN Testers Matrix

The CPAN Testers Matrix is a website that provides a visual overview of the test results for a distribution on various Perls/platforms.

L<http://matrix.cpantesters.org/?dist=CPAN-WWW-Top100-Retrieve>

=item *

CPAN Testers Dependencies

The CPAN Testers Dependencies is a website that shows a chart of the test results of all dependencies for a distribution.

L<http://deps.cpantesters.org/?module=CPAN::WWW::Top100::Retrieve>

=back

=head2 Email

You can email the author of this module at C<APOCAL at cpan.org> asking for help with any problems you have.

=head2 Internet Relay Chat

You can get live help by using IRC ( Internet Relay Chat ). If you don't know what IRC is,
please read this excellent guide: L<http://en.wikipedia.org/wiki/Internet_Relay_Chat>. Please
be courteous and patient when talking to us, as we might be busy or sleeping! You can join
those networks/channels and get help:

=over 4

=item *

irc.perl.org

You can connect to the server at 'irc.perl.org' and join this channel: #perl-help then talk to this person for help: Apocalypse.

=item *

irc.freenode.net

You can connect to the server at 'irc.freenode.net' and join this channel: #perl then talk to this person for help: Apocal.

=item *

irc.efnet.org

You can connect to the server at 'irc.efnet.org' and join this channel: #perl then talk to this person for help: Ap0cal.

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests by email to C<bug-cpan-www-top100-retrieve at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=CPAN-WWW-Top100-Retrieve>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<https://github.com/apocalypse/perl-cpan-www-top100-retrieve>

  git clone https://github.com/apocalypse/perl-cpan-www-top100-retrieve.git

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
