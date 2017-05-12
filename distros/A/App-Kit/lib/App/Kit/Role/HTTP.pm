package App::Kit::Role::HTTP;

## no critic (RequireUseStrict) - Moo::Role does strict/warnings
use Moo::Role;

our $VERSION = '0.1';

has http => (
    is => ( $INC{'App/Kit/Util/RW.pm'} || $ENV{'App-Kit-Util-RW'} ? 'rw' : 'rwp' ),
    lazy    => 1,
    default => sub {
        require HTTP::Tiny;
        eval { require HTTP::Tiny::Multipart };    # enable multipart support if possible, otherwise be silent # Perl::DependList-NO_DEP(HTTP::Tiny::Multipart)
        return HTTP::Tiny->new();
    },
);

1;

__END__

=encoding utf-8

=head1 NAME

App::Kit::Role::HTTP - A Lazy Façade method role for an HTTP client

=head1 VERSION

This document describes App::Kit::Role::HTTP version 0.1

=head1 SYNOPSIS

In your class:

   with 'App::Kit::Role::HTTP';

Then later in your program:

    $app->http->get(…)

=head1 DESCRIPTION

Add lazy façade HTTP client support to your class.

=head1 INTERFACE

This role adds one lazy façade method:

=head2 http()

Returns a L<HTTP::Tiny> object for reuse after lazy loading the module.

L<HTTP::Tiny::Multipart> is also loaded if it is available.

=head1 DIAGNOSTICS

Throws no warnings or errors of its own.

=head1 CONFIGURATION AND ENVIRONMENT

Requires no configuration files or environment variables.

=head1 DEPENDENCIES

L<Moo::Role>, L<HTTP::Tiny>

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-app-kit@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 AUTHOR

Daniel Muey  C<< <http://drmuey.com/cpan_contact.pl> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2013, Daniel Muey C<< <http://drmuey.com/cpan_contact.pl> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
