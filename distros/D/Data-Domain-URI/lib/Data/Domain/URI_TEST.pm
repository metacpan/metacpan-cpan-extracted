use 5.008;
use strict;
use warnings;

package Data::Domain::URI_TEST;
our $VERSION = '1.100850';
# ABSTRACT: Test companion class for the URI data domain class
use Test::More;
use Data::Domain::URI ':all';
use parent qw(Test::CompanionClasses::Base);
use constant PLAN => 4 * keys %Data::Domain::URI::map;

sub run {
    my $self = shift;
    while (my ($shortcut, $rel_pkg) = each %Data::Domain::URI::map) {
        no strict 'refs';
        my $domain = *{$shortcut}{CODE}->();
        isa_ok($domain,          "Data::Domain::$rel_pkg");
        isa_ok($domain,          'Data::Domain::SemanticAdapter');
        isa_ok($domain->adaptee, "Data::Semantic::$rel_pkg");
        isa_ok($domain->adaptee, 'Data::Semantic::RegexpAdapter');
    }
}
1;


__END__
=pod

=head1 NAME

Data::Domain::URI_TEST - Test companion class for the URI data domain class

=head1 VERSION

version 1.100850

=head1 DESCRIPTION

This test companion class tests the shortcuts provided by L<Data::Domain::URI>
and that the objects they create, and their adaptees, are of the expected
types.

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

