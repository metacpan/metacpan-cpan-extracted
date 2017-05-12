package CDMIUtils;

    use strict;
    use parent qw(Exporter);
    our @EXPORT = qw(location_string_to_location region_string_to_region
                     location_to_location_string region_to_region_string);

=head1 CDMI Utilities

This package contains useful methods for manipulating the data
types in the KBase Central Data Model. Unlike API methods, these
do not require actual access to a database instance.

=head2 Important Definitions

=over 4

=item region string

A region string specifies a portion of a contig in the form of a
string. It contains a contig ID followed by an underscore, the start
location, the strand (C<+> or C<->), and the region length. Thus,
C<NC17007_101+483> represents the 483-base-pair region beginning at the
101st base pair on the plus strand of contig B<NC17007>, and
C<kb|108762_436-101> represents the region of contig B<kb|108762> beginning at
the 436th base pair and extending backward through the 336th base pair.

=item location_string

A location string represents multiple regions on a contig (and sometimes
on multiple contigs). It is formed by joining the individual region
strings together with commas. So, for example C<kb|108762_436+120,kb|108762_561+132>
is a location string for two regions on the contig B<kb|108762> separated
by a gap of 5 base pairs.

=item region

A region is a 4-tuple specifying a single portion of a contig. The
elements of the tuple are (0) the contig ID, (1) the start location,
(2) the strand (C<+> or C<->), and (3) the length. Thus,
C<< ['NC17007', 101, '+', 483] >> represents the 483-base-pair region
beginning at the 101st base pair on the plus strand of contig B<NC17007>,
and C<< ['kb|108762', 436, '-', 101] >> represents the region of contig
B<kb|108762> beginning at the 436th base pair and extending backward
through the 336th base pair.

=item location

A location is a reference to a list of regions and specifies one or more
portions of one or more contigs. So, for example,
C<< [['kb|108762', 436, '+', 120], ['kb|108762', 561, '+', 132]] >>
is a location for two regions on the contig B<kb|108762> separated
by a gap of 5 base pairs.

=back

=head2 Methods

=head3 location_string_to_location

    my $location = location_string_to_location($location_string);

Convert a location string to a location.

=over 4

=item location_string

A location string representing one or more regions in a contig.

=item RETURN

Returns the same location in the form of a reference to a list of regions,
each of which is a 4-tuple.

=back

=cut

sub location_string_to_location {
    # Get the parameter.
    my ($location_string) = @_;
    # Split it into region strings.
    my @regionStrings = split /\s*,\s*/, $location_string;
    # Convert them into regions.
    my @regions = map { region_string_to_region($_) } @regionStrings;
    # Return the result.
    return \@regions;
}

=head3 region_string_to_region

    my $region = region_string_to_region($region_string);

Convert a region string to a region.

=over 4

=item region_string

A region string representing a single portion of a contig.

=item RETURN

Returns a the same region in the form of a 4-tuple.

=back

=cut

sub region_string_to_region {
    # Get the parameters.
    my ($region_string) = @_;
    # Parse out the pieces.
    my @region = ($region_string =~ /^(.+)_(\d+)([+\-])(\d+)$/);
    # Return the result.
    return \@region;
}

=head3 location_to_location_string

    my $location = location_to_location_string($location);

Convert a location to a location string.

=over 4

=item location

A location in the form of a reference to a list of 4-tuples.

=item RETURN

Returns the same location information in the form of a location string.

=back

=cut

sub location_to_location_string {
    # Get the parameters.
    my ($location) = @_;
    # Convert the elements to region strings.
    my @strings = map { region_to_region_string($_) } @$location;
    # Return the result.
    return join(",", @strings);
}

=head3 region_to_region_string

    my $region = region_to_region_string($region);

Convert a region to a region string.

=over 4

=item region

A region in the form of a 4-tuple.

=item RETURN

Returns the same region in the form of a region string.

=back

=cut

sub region_to_region_string {
    # Get the parameters.
    my ($region) = @_;
    # Join the elements into a string.
    my $string = $region->[0] . '_' . $region->[1] . $region->[2] . $region->[3];
    # Return the result.
    return $string;
}

1;