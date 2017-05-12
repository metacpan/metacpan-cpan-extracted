use 5.008;
use strict;
use warnings;

package Data::Semantic::URI;
our $VERSION = '1.100850';
# ABSTRACT: Semantic data classes for URI-related data
use parent qw(Data::Semantic::RegexpAdapter);
1;


__END__
=pod

=head1 NAME

Data::Semantic::URI - Semantic data classes for URI-related data

=head1 VERSION

version 1.100850

=head1 DESCRIPTION

This is a base class for semantic data classes for URIs. Classes for the
following URI types are available:

=over 4

=item C<fax>

See L<Data::Semantic::URI::fax>.

=item C<file>

See L<Data::Semantic::URI::file>.

=item C<ftp>

See L<Data::Semantic::URI::ftp>.

=item C<http>

See L<Data::Semantic::URI::http>.

=back

=head1 INSTALLATION

See perlmodinstall for information and options on installing Perl modules.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests through the web interface at
L<http://rt.cpan.org/Public/Dist/Display.html?Name=Data-Semantic-URI>.

=head1 AVAILABILITY

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see
L<http://search.cpan.org/dist/Data-Semantic-URI/>.

The development version lives at
L<http://github.com/hanekomu/Data-Semantic-URI/>.
Instead of sending patches, please fork this project using the standard git
and github infrastructure.

=head1 AUTHOR

  Marcel Gruenauer <marcel@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2007 by Marcel Gruenauer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

