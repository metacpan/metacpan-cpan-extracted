use 5.008;
use strict;
use warnings;

package Data::Semantic::URI::http;
our $VERSION = '1.100850';
# ABSTRACT: Semantic data class for http URIs
use parent qw(Data::Semantic::URI);
__PACKAGE__->mk_scalar_accessors(qw(scheme));
use constant REGEXP_KEYS => qw(URI HTTP);
use constant KEEP_KEYS   => qw(
  URI scheme host port abspath_full abspath_full_no_slash
  abspath_no_query query
);

sub flags {
    my $self  = shift;
    my @flags = $self->SUPER::flags(@_);
    push @flags => sprintf("-scheme => '%s'", $self->scheme) if $self->scheme;
    @flags;
}
1;


__END__
=pod

=for stopwords http

=head1 NAME

Data::Semantic::URI::http - Semantic data class for http URIs

=head1 VERSION

version 1.100850

=head1 SYNOPSIS

    my $obj = Data::Semantic::URI::http->new;
    if ($obj->is_valid('...')) {
       #  ...
    }

=head1 DESCRIPTION

This class can tell whether a value is an HTTP URI, as defined by RFCs 2396
and 2616. The C<valid()> method will respect the C<scheme> attribute and the
inherited C<keep> boolean attribute.

See L<Regexp::Common::URI::http> for the meaning of C<scheme>.

If C<keep> is set, C<kept()> will return a hash with the following keys/value
pairs:

=over 4

=item URI

The complete URI.

=item C<scheme>

The scheme.

=item C<host>

The host (name or address).

=item C<port>

The port (if any).

=item C<abspath_full>

The absolute path, including the query and leading slash.

=item C<abspath_full_no_slash>

The absolute path, including the query, without the leading slash.

=item C<abspath_no_query>

The absolute path, without the query or leading slash.

=item C<query>

The query, without the question mark.

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

