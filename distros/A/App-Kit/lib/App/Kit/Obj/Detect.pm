package App::Kit::Obj::Detect;

## no critic (RequireUseStrict) - Moo does strict
use Moo;

our $VERSION = '0.1';

Sub::Defer::defer_sub __PACKAGE__ . '::is_web' => sub {
    require Web::Detect;
    return sub {
        return 1 if Web::Detect::detect_web_fast();
        return;
    };
};

Sub::Defer::defer_sub __PACKAGE__ . '::is_interactive' => sub {
    require IO::Interactive::Tiny;
    return sub {
        shift;
        goto &IO::Interactive::Tiny::is_interactive;
    };
};

Sub::Defer::defer_sub __PACKAGE__ . '::has_net' => sub {
    require Net::Detect;
    return sub {
        shift;
        goto &Net::Detect::detect_net;
    };
};

Sub::Defer::defer_sub __PACKAGE__ . '::is_testing' => sub {
    require Test::Detect;
    return sub {
        return 1 if Test::Detect::detect_testing();
        return;
    };
};

1;

__END__

=encoding utf-8

=head1 NAME

App::Kit::Obj::Detect - context detection utility object

=head1 VERSION

This document describes App::Kit::Obj::Detect version 0.1

=head1 SYNOPSIS

    my $detect = App::Kit::Obj::Detect->new();
    $detect->is_web()

=head1 DESCRIPTION

context detection utility object

=head1 INTERFACE

=head2 new()

Returns the object, takes no arguments.

=head2 is_web()

Lazy wrapper of L<Web::Detect>’s detect_web_fast().

=head2 is_interactive()

Lazy wrapper of L<IO::Interactive::Tiny>’s is_interactive().

=head2 has_net()

Lazy wrapper of L<Net::Detect>’s detect_net().

=head2 is_testing()

Lazy wrapper of L<Test::Detect>’s detect_testing().

=head1 DIAGNOSTICS

Throws no warnings or errors of its own.

=head1 CONFIGURATION AND ENVIRONMENT

Requires no configuration files or environment variables.

=head1 DEPENDENCIES

L<Web::Detect>,  L<IO::Interactive::Tiny>, L<Net::Detect>, L<Test::Detect>

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
