use 5.008;
use strict;
use warnings;

package Data::Storage::Exception::Connect;
BEGIN {
  $Data::Storage::Exception::Connect::VERSION = '1.102720';
}
# ABSTRACT: Exception raised on a connection failure
use parent qw(Data::Storage::Exception);
__PACKAGE__->mk_scalar_accessors(qw(dbname dbuser reason));
use constant default_message =>
  'Cannot connect to storage [%s] as user [%s]: %s';
use constant PROPERTIES => (qw/dbname dbuser reason/);
1;


__END__
=pod

=head1 NAME

Data::Storage::Exception::Connect - Exception raised on a connection failure

=head1 VERSION

version 1.102720

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

