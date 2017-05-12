use 5.008;
use strict;
use warnings;

package Data::Storage::Null;
BEGIN {
  $Data::Storage::Null::VERSION = '1.102720';
}
# ABSTRACT: Base class for null storages
use Class::Null;

# use Class::Null for methods not implemented here or in
# Data::Storage
use parent 'Data::Storage::Memory';
sub FIRST_CONSTRUCTOR_ARGS { () }
sub is_connected           { 1 }
sub AUTOLOAD               { Class::Null->new }
1;


__END__
=pod

=head1 NAME

Data::Storage::Null - Base class for null storages

=head1 VERSION

version 1.102720

=head1 METHODS

=head2 FIRST_CONSTRUCTOR_ARGS

FIXME

=head2 is_connected

FIXME

=head1 INSTALLATION

See perlmodinstall for information and options on installing Perl modules.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests through the web interface at
L<http://rt.cpan.org/Public/Dist/Display.html?Name=Data-Storage>.

=head1 AVAILABILITY

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see L<http://search.cpan.org/dist/Data-Storage/>.

The development version lives at L<http://github.com/hanekomu/Data-Storage>
and may be cloned from L<git://github.com/hanekomu/Data-Storage>.
Instead of sending patches, please fork this project using the standard
git and github infrastructure.

=head1 AUTHORS

=over 4

=item *

Marcel Gruenauer <marcel@cpan.org>

=item *

Florian Helmberger <fh@univie.ac.at>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2004 by Marcel Gruenauer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

