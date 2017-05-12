use 5.008;
use strict;
use warnings;

package Data::Domain::URI;
our $VERSION = '1.100850';
# ABSTRACT: Data domain classes for URIs
use Data::Domain::SemanticAdapter;
use Exporter qw(import);
our %map = (
    URI_Fax  => 'URI::fax',
    URI_File => 'URI::file',
    URI_FTP  => 'URI::ftp',
    URI_HTTP => 'URI::http',
);
our %EXPORT_TAGS = (util => [ keys %map ],);
our @EXPORT_OK = @{ $EXPORT_TAGS{all} = [ map { @$_ } values %EXPORT_TAGS ] };
Data::Domain::SemanticAdapter::install_shortcuts(%map);
1;


__END__
=pod

=head1 NAME

Data::Domain::URI - Data domain classes for URIs

=head1 VERSION

version 1.100850

=head1 DESCRIPTION

The classes in this distribution are data domain classes for various URI
types.

=over 4

=item C<fax>

See L<Data::Domain::URI::fax>.

=item C<file>

See L<Data::Domain::URI::file>.

=item C<ftp>

See L<Data::Domain::URI::ftp>.

=item C<http>

See L<Data::Domain::URI::http>.

=back

Besides defining the methods described below, this class also exports, on
request, these functions:

=over 4

=item URI_Fax

A shortcut for creating a L<Data::Domain::URI::fax> object. Arguments are
passed on to the object's constructor.

=item URI_File

A shortcut for creating a L<Data::Domain::URI::file> object. Arguments are
passed on to the object's constructor.

=item URI_FTP

A shortcut for creating a L<Data::Domain::URI::ftp> object. Arguments are
passed on to the object's constructor.

=item URI_HTTP

A shortcut for creating a L<Data::Domain::URI::http> object. Arguments are
passed on to the object's constructor.

=back

By using the C<:all> tag, you can import all of them.

=head1 INSTALLATION

See perlmodinstall for information and options on installing Perl modules.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests through the web interface at
L<http://rt.cpan.org/Public/Dist/Display.html?Name=Data-Domain-URI>.

=head1 AVAILABILITY

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see
L<http://search.cpan.org/dist/Data-Domain-URI/>.

The development version lives at
L<http://github.com/hanekomu/Data-Domain-URI/>.
Instead of sending patches, please fork this project using the standard git
and github infrastructure.

=head1 AUTHOR

  Marcel Gruenauer <marcel@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2007 by Marcel Gruenauer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

