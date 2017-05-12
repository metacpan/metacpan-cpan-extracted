use 5.008;
use strict;
use warnings;

package Class::Value::URI::fax;
our $VERSION = '1.100840';
# ABSTRACT: Value class for fax URIs
use parent 'Class::Value::SemanticAdapter';
__PACKAGE__->mk_boolean_accessors(qw(nofuture));

sub semantic_args {
    my $self = shift;
    ($self->SUPER::semantic_args(@_), nofuture => $self->nofuture,);
}
1;


__END__
=pod

=head1 NAME

Class::Value::URI::fax - Value class for fax URIs

=head1 VERSION

version 1.100840

=head1 DESCRIPTION

This value class uses the L<Class::Value> mechanism and is an adapter for
L<Data::Semantic::URI::fax> - see there for more information.

=head1 METHODS

=head2 semantic_args

FIXME

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

