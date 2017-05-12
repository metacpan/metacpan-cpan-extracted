package BackPAN::Version::Discover::Results;

our $VERSION = '0.01';

use warnings;
use strict;

# yeah, it's only "OO" because that's what all the cool kids do.
sub new {
    my ($class, %args) = @_;

    return bless \%args, $class;
}

###
1;

__END__

=head1 NAME

BackPAN::Version::Discover::Results - The results from BackPAN::Version::Discover

=head1 VERSION

Version 0.01

=cut

=head1 SYNOPSIS

See the documentation for L<BackPAN::Version::Discover> for more info, like
how to get this object with useful data in it.

    # assuming $results is a BackPAN::Version::Discover::Results object...
    
    my @releases        = $results->release_paths();
    my @vendor_mods     = $results->vendor_mods();
    my @unmatched_dists = $results->unmatched_dists();


=head1 SUBROUTINES/METHODS

=head2 new

Creates a new BackPAN::Version::Discover::Results object with the given parameters.

Note: You should never need to create this object directly!

Parameters:

=over 4

=item * releases_matched

=item * skipped_modules

=item * dists_not_matched

=item * searched_dirs

=item * dist_info

=item * scan_args

=back

=head2 release_paths

returns a list of paths to the release tarballs as can be found on a
backpan mirror.

=head2 vendor_mods

returns a list of the names of modules that were likely installed via a
vendor package, ie. Dpkg or RPM or ebuild, et al.

Note: since the same module can be installed in several places with
several different versions, these modules are the ones that perl would
load if they were used in a script.

=head2 unmatched_dists

returns a list of the names of CPAN distributions that appear to be installed,
but a matching backpan release could not be determined.

You may have to track it down manually, or better yet, send me a patch!

=head1 AUTHOR

Stephen R. Scaffidi, C<< <sscaffidi at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-backpan-version-discover at rt.cpan.org>, or through the web interface
at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=BackPAN-Version-Discover>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc BackPAN::Version::Discover

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=BackPAN-Version-Discover>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/BackPAN-Version-Discover>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/BackPAN-Version-Discover>

=item * Search CPAN

L<http://search.cpan.org/dist/BackPAN-Version-Discover/>

=back

=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2010 Stephen R. Scaffidi.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

