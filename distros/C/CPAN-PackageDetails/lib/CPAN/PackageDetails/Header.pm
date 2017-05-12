package CPAN::PackageDetails::Header;
use strict;
use warnings;

use vars qw($VERSION);
$VERSION = '0.26';

use Carp;

=head1 NAME

CPAN::PackageDetails::Header - Handle the header of 02packages.details.txt.gz

=head1 SYNOPSIS

Used internally by CPAN::PackageDetails

=head1 DESCRIPTION

The 02packages.details.txt.gz header is a short preamble that give information
about the creation of the file, its intended use, and the number of entries in
the file. It looks something like:

	File:         02packages.details.txt
	URL:          http://www.perl.com/CPAN/modules/02packages.details.txt
	Description:  Package names found in directory $CPAN/authors/id/
	Columns:      package name, version, path
	Intended-For: Automated fetch routines, namespace documentation.
	Written-By:   Id: mldistwatch.pm 1063 2008-09-23 05:23:57Z k
	Line-Count:   59754
	Last-Updated: Thu, 23 Oct 2008 02:27:36 GMT

Note that there is a Columns field. This module tries to respect the ordering
of columns in there. The usual CPAN tools expect only three columns and in the
order in this example, but C<CPAN::PackageDetails> tries to handle any number
of columns in any order.

=head2 Methods

=over 4

=item new( HASH )

Create a new Header object. Unless you want a lot of work so you
get more control, just let C<CPAN::PackageDetails>'s C<new> or C<read>
handle this for you.

In most cases, you'll want to create the Entries object first then
pass a reference the the Entries object to C<new> since the header
object needs to know how to get the count of the number of entries
so it can put it in the "Line-Count" header.

	CPAN::PackageDetails::Header->new(
		_entries => $entries_object,
		)

=cut

sub new {
	my( $class, %args ) = @_;

	my %hash = (
		_entries => undef,
		%args
		);

	bless \%hash, $_[0]
	}

=item format_date

Write the date in PAUSE format. For example:

	Thu, 23 Oct 2008 02:27:36 GMT

=cut

sub format_date {
	my( $second, $minute, $hour, $date, $monnum, $year, $wday )  = gmtime;
	$year += 1900;

	my $day   = ( qw(Sun Mon Tue Wed Thu Fri Sat) )[$wday];
	my $month = ( qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec) )[$monnum];

	sprintf "%s, %02d %s %4d %02d:%02d:%02d GMT",
		$day, $date, $month, $year, $hour, $minute, $second;
	}

=item default_headers

Returns a list of the the headers that should show up in the file. This
excludes various fake headers stored in the object.

=cut

sub default_headers {
	map { $_, $_[0]->{$_} }
		grep ! /^_|_class|allow/, keys %{ $_[0] }
	}

sub can {
	my( $self, @methods ) = @_;

	my $class = ref $self || $self; # class or instance

	foreach my $method ( @methods ) {
		next if
			defined &{"${class}::$method"} ||
			$self->header_exists( $method );
		return 0;
		}

	return 1;
	}

=item set_header

Add an entry to the collection. Call this on the C<CPAN::PackageDetails>
object and it will take care of finding the right handler.

=cut

sub set_header {
	my( $self, $field, $value ) = @_;

	$self->{$field} = $value;
	}

=item header_exists( FIELD )

Returns true if the header has a field named FIELD, regardless of
its value.

=cut

sub header_exists {
	my( $self, $field ) = @_;

	exists $self->{$field}
	}

=item get_header( FIELD )

Returns the value for the named header FIELD. Carps and returns nothing
if the named header is not in the object. This method is available from
the C<CPAN::PackageDetails> or C<CPAN::PackageDetails::Header> object:

	$package_details->get_header( 'url' );

	$package_details->header->get_header( 'url' );

The header names in the Perl code are in a different format than they
are in the file. See C<default_headers> for an explanation of the
difference.

For most headers, you can also use the header name as the method name:

	$package_details->header->url;

=cut

sub get_header {
	my( $self, $field ) = @_;

	if( $self->header_exists( $field ) ) { $self->{$field} }
	else { carp "No such header as $field!"; return }
	}

=item columns_as_list

Returns the columns name as a list (rather than a comma-joined string). The
list is in the order of the columns in the output.

=cut

sub columns_as_list { split /,\s+/, $_[0]->{columns} }

=item as_string

Return the header formatted as a string.

=cut

BEGIN {
my %internal_field_name_mapping = (
	url => 'URL',
	);

my %external_field_name_mapping = reverse %internal_field_name_mapping;

sub _internal_name_to_external_name {
	my( $self, $internal ) = @_;

	return $internal_field_name_mapping{$internal}
		if exists $internal_field_name_mapping{$internal};

	(my $external = $internal) =~ s/_/-/g;
	$external =~ s/^(.)/ uc $1 /eg;
	$external =~ s/-(.)/ "-" . uc $1 /eg;

	return $external;
	}

sub _external_name_to_internal_name {
	my( $self, $external ) = @_;

	return $external_field_name_mapping{$external}
		if exists $external_field_name_mapping{$external};

	(my $internal = $external) =~ s/-/_/g;

	lc $internal;
	}

sub as_string {
	my( $self, $line_count ) = @_;

	# XXX: need entry count
	my @lines;
	foreach my $field ( keys %$self ) {
		next if substr( $field, 0, 1 ) eq '_';
		my $value = $self->get_header( $field );

		my $out_field = $self->_internal_name_to_external_name( $field );

		push @lines, "$out_field: $value";
		}

	push @lines, "Line-Count: " . $self->_entries->as_unique_sorted_list
		unless $self->header_exists( 'line_count' );

	join "\n", sort( @lines ), "\n";
	}
}

sub AUTOLOAD {
	my $self = shift;

	( my $method = $CPAN::PackageDetails::Header::AUTOLOAD ) =~ s/.*:://;

	carp "No such method as $method!" unless $self->can( $method );

	$self->get_header( $method );
	}

sub DESTROY { }

=back

=head1 TO DO


=head1 SEE ALSO


=head1 SOURCE AVAILABILITY

This source is in Github:

	http://github.com/briandfoy/cpan-packagedetails

=head1 AUTHOR

brian d foy, C<< <bdfoy@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2009-2014, brian d foy, All Rights Reserved.

You may redistribute this under the same terms as Perl itself.

=cut

1;
