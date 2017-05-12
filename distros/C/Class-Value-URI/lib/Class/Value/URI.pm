use 5.008;
use strict;
use warnings;

package Class::Value::URI;
our $VERSION = '1.100840';
# ABSTRACT: Value class for URIs
use parent qw(Class::Accessor::Complex);
__PACKAGE__->mk_new;
1;


__END__
=pod

=head1 NAME

Class::Value::URI - Value class for URIs

=head1 VERSION

version 1.100840

=head1 DESCRIPTION

The classes in this distribution are value classes for various URI types.

=over 4

=item C<fax>

See L<Class::Value::URI::fax>.

=item C<file>

See L<Class::Value::URI::file>.

=item C<ftp>

See L<Class::Value::URI::ftp>.

=item C<http>

See L<Class::Value::URI::http>.

=back

=head1 INSTALLATION

See perlmodinstall for information and options on installing Perl modules.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests through the web interface at
L<http://rt.cpan.org/Public/Dist/Display.html?Name=Class-Value-URI>.

=head1 AVAILABILITY

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see
L<http://search.cpan.org/dist/Class-Value-URI/>.

The development version lives at
L<http://github.com/hanekomu/Class-Value-URI/>.
Instead of sending patches, please fork this project using the standard git
and github infrastructure.

=head1 AUTHOR

  Marcel Gruenauer <marcel@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2007 by Marcel Gruenauer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

