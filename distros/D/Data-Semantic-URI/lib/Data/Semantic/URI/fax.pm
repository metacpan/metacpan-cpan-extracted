use 5.008;
use strict;
use warnings;

package Data::Semantic::URI::fax;
our $VERSION = '1.100850';
# ABSTRACT: Semantic data class for fax URIs
use parent qw(Data::Semantic::URI);
__PACKAGE__->mk_boolean_accessors(qw(nofuture));
use constant REGEXP_KEYS => qw(URI fax);
use constant KEEP_KEYS   => qw(URI scheme phone_number);

sub flags {
    my $self  = shift;
    my @flags = $self->SUPER::flags(@_);
    push @flags => 'nofuture' if $self->nofuture;
    @flags;
}
1;


__END__
=pod

=for stopwords ISDN

=head1 NAME

Data::Semantic::URI::fax - Semantic data class for fax URIs

=head1 VERSION

version 1.100850

=head1 SYNOPSIS

    my $obj = Data::Semantic::URI::fax->new;
    if ($obj->is_valid('...')) {
       #  ...
    }

=head1 DESCRIPTION

This class can tell whether a value is a fax URI, as defined by RFC 2006. The
C<valid()> method will respect the C<nofuture> boolean attribute and the
inherited C<keep> boolean attribute.

If C<nofuture> is set, future extensions are not allowed.

If C<keep> is set, C<kept()> will return a hash with the following keys/value
pairs:

=over 4

=item URI

The complete URI.

=item C<scheme>

The scheme.

=item C<phone_number>

The phone number, including any possible add-ons like ISDN sub-address, a
post dial part, area specifier, service provider, etc.

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

