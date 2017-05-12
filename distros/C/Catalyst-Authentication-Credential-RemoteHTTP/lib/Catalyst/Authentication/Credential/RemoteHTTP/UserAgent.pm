package Catalyst::Authentication::Credential::RemoteHTTP::UserAgent;

# ABSTRACT: Wrapper for LWP::UserAgent

use strict;
use warnings;
use base qw/LWP::UserAgent/;

our $VERSION = '0.05'; # VERSION
our $AUTHORITY = 'cpan:NIGELM'; # AUTHORITY

sub set_credentials {
    my ($self, $user, $pass) = @_;
    @{ $self->{credentials} } = ($user, $pass);
}

sub get_basic_credentials {
    my $self = shift;
    return @{ $self->{credentials} };
}


1;

__END__
=pod

=for stopwords ACKNOWLEDGEMENTS Marcus Ramberg

=head1 NAME

Catalyst::Authentication::Credential::RemoteHTTP::UserAgent - Wrapper for LWP::UserAgent

=head1 VERSION

version 0.05

=head1 DESCRIPTION

A thin wrapper for L<LWP::UserAgent> to make basic authentication simpler.

=head1 METHODS

=head2 set_credentials

now takes just a username and password

=head2 get_basic_credentials

Returns the set credentials, takes no options.

=head1 ACKNOWLEDGEMENTS

Marcus Ramberg <mramberg@cpan.org - original code in L<Catalyst::Plugin::Authentication::Credential::HTTP::User>

=head1 INSTALLATION

See perlmodinstall for information and options on installing Perl modules.

=head1 BUGS AND LIMITATIONS

You can make new bug reports, and view existing ones, through the
web interface at L<http://rt.cpan.org/Public/Dist/Display.html?Name=Catalyst-Authentication-Credential-RemoteHTTP>.

=head1 AVAILABILITY

The project homepage is L<https://metacpan.org/release/Catalyst-Authentication-Credential-RemoteHTTP>.

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see L<https://metacpan.org/module/Catalyst::Authentication::Credential::RemoteHTTP/>.

=head1 AUTHOR

Nigel Metheringham <nigelm@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Nigel Metheringham <nigelm@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

