# Mini class for entries of the file mapping hash.
package Bio::RNA::BarMap::Mapping::FileMappingEntry;
our $VERSION = '0.04';

use 5.012;
use warnings;

use Moose;
use namespace::autoclean;


has 'name' => (is => 'ro', required => 1);
# Ensure object is cleaned after use => use weak refs
has [qw(from to)] => (is => 'rw', weak_ref => 1);

__PACKAGE__->meta->make_immutable;

1;

__END__


=pod

=encoding UTF-8

=head1 NAME

Bio::RNA::BarMap::Mapping::FileMappingEntry - stores information about which
I<Barriers> file is mapped to which other I<Barriers> file.

=head1 SYNOPSIS

    use v5.12;                              # for 'say'
    use Bio::RNA::BarMap;

    my $file_mapping = Bio::RNA::BarMap::Mapping::FileMappingEntry->new(
        name => '1.bar',
        to   => '2.bar',
        from => undef,
    )

    say 'File ', $file_mapping->name, ' is mapped to ', $file_mapping->to;


=head1 DESCRIPTION

Internally used mini-class to store information about which I<Barriers> is
mapped to another. Stores both directions (mapped from, mapped to). The C<to>
and C<from> attributes may be undefined for the first and last file.

=head1 AUTHOR

Felix Kuehnl, C<< <felix at bioinf.uni-leipzig.de> >>


=head1 BUGS

Please report any bugs or feature requests by raising an issue at
L<https://github.com/xileF1337/Bio-RNA-BarMap/issues>.

You can also do so by mailing to C<bug-bio-rna-barmap at rt.cpan.org>,
or through the web interface at
L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Bio-RNA-BarMap>.  I will be
notified, and then you'll automatically be notified of progress on your bug as
I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Bio::RNA::BarMap


You can also look for information at the official BarMap website:

L<https://www.tbi.univie.ac.at/RNA/bar_map/>


=over 4

=item * Github: the official repository

L<https://github.com/xileF1337/Bio-RNA-BarMap>

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Bio-RNA-BarMap>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Bio-RNA-BarMap>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Bio-RNA-BarMap>

=item * Search CPAN

L<https://metacpan.org/release/Bio-RNA-BarMap>

=back


=head1 LICENSE AND COPYRIGHT

Copyright 2019-2021 Felix Kuehnl.

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see L<http://www.gnu.org/licenses/>.


=cut

# End of Bio::RNA::BarMap::Mapping::FileMappingEntry
