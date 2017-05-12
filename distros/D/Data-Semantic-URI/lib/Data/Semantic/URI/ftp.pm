use 5.008;
use strict;
use warnings;

package Data::Semantic::URI::ftp;
our $VERSION = '1.100850';
# ABSTRACT: Semantic data class for ftp URIs
use parent qw(Data::Semantic::URI);
__PACKAGE__
    ->mk_scalar_accessors(qw(type))
    ->mk_boolean_accessors(qw(password));
use constant REGEXP_KEYS => qw(URI FTP);
use constant KEEP_KEYS   => qw(
  URI scheme username password host port abspath_full abspath_full_no_slash
  abspath_full_no_slash_no_query type
);

sub flags {
    my $self  = shift;
    my @flags = $self->SUPER::flags(@_);
    push @flags => sprintf("-type => '%s'", $self->type) if $self->type;
    push @flags => '-password' if $self->password;
    @flags;
}
1;


__END__
=pod

=head1 NAME

Data::Semantic::URI::ftp - Semantic data class for ftp URIs

=head1 VERSION

version 1.100850

=head1 SYNOPSIS

    my $obj = Data::Semantic::URI::ftp->new;
    if ($obj->is_valid('...')) {
       #  ...
    }

=head1 DESCRIPTION

This class can tell whether a value is an FTP URI, as defined by RFCs 1738 and
2396. The C<valid()> method will respect the C<type> and C<password>
attributes and the inherited C<keep> boolean attribute.

See L<Regexp::Common::URI::ftp> for the meaning of C<type> and C<password>.

If C<keep> is set, C<kept()> will return a hash with the following keys/value
pairs:

=over 4

=item URI

The complete URI.

=item C<scheme>

The scheme.

=item C<username>

The userinfo, or if C<password> is used, the username.

=item C<password>

If C<password> is used, the password, else "undef".

=item C<host>

The hostname or IP address.

=item C<port>

The port number

=item C<abspath_full>

The full path and type specification, including the leading slash.

=item C<abspath_full_no_slash>

The full path and type specification, without the leading slash.

=item C<abspath_full_no_slash_no_query>

The full path, without the type specification nor the leading slash.

=item C<type>

The value of the type specification.

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

