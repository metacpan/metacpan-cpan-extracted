package Apache::Session::Generate::Random;

use 5.006;

use strict;
use warnings;

use Crypt::SysRandom 0.007 ();

# RECOMMEND PREREQ:  Crypt::SysRandom::XS 0.010

our $VERSION = '0.002002';

# ABSTRACT: use system randomness for generating session ids


sub generate {
    my ($session) = @_;
    return $session->{'data'}->{'_session_id'} = unpack( 'H*', Crypt::SysRandom::random_bytes(20) );
}

sub validate {
    my ($session) = @_;
    if ( $session->{data}->{_session_id} =~ /^[0-9a-f]{40}$/ ) {
        return $session->{data}->{_session_id};
    }
    die "Invalid session ID: " . $session->{data}->{_session_id};
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Apache::Session::Generate::Random - use system randomness for generating session ids

=head1 VERSION

version 0.002002

=head1 SYNOPSIS

    use Apache::Session::Flex;

    tie %sessions, 'Apache::Session::Flex', $id, {
        Store     => 'Postgres',
        Lock      => 'Null',
        Generate  => 'Random',
        Serialize => 'Base64',
    };

=head1 DESCRIPTION

This module extends L<Apache::Session> to create secure random session ids using the system's source of randomness.

=for Pod::Coverage generate

=for Pod::Coverage validate

=head1 SEE ALSO

L<Apache::Session>

L<Crypt::SysRandom>

=head1 SUPPORT

Only the latest version of this module will be supported.

This module should work on very old Perl versions, such as v5.6.0.
However, only Perl versions released in the last ten years will be supported.

=head2 Reporting Bugs and Submitting Feature Requests

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/robrwo/perl-Apache-Session-Generate-Random/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

If the bug you are reporting has security implications which make it inappropriate to send to a public issue tracker,
then see F<SECURITY.md> for instructions how to report security vulnerabilities.

=head1 SOURCE

The development version is on github at L<https://github.com/robrwo/perl-Apache-Session-Generate-Random>
and may be cloned from L<https://github.com/robrwo/perl-Apache-Session-Generate-Random.git>

=head1 AUTHOR

Robert Rothenberg <perl@rhizomnic.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
