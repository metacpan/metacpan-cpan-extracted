package App::Kit::Obj::Ex;

## no critic (RequireUseStrict) - Moo does strict
use Moo;

our $VERSION = '0.1';

has _app => (
    is       => 'ro',
    required => 1,
);

if ( !defined &runcom ) {
    *runcom = sub {
        die "Due to compile time Shenanigans in an underlying module, you must 'use App::Kit::Util::RunCom;' to enable runcom().\n";
    };
}

sub fsleep {
    my ( $self, $n ) = @_;
    select( undef, undef, undef, abs($n) );    ## no critic - encapsulate the voodoo here so its OK
    return 1;
}

Sub::Defer::defer_sub __PACKAGE__ . '::whereis' => sub {
    require Unix::Whereis;
    return sub {
        shift;
        goto &Unix::Whereis::whereis;
    };
};

Sub::Defer::defer_sub __PACKAGE__ . '::run_cmd' => sub {
    require IPC::Open3::Utils;
    return sub {
        shift;
        goto &IPC::Open3::Utils::run_cmd;
    };
};

Sub::Defer::defer_sub __PACKAGE__ . '::put_cmd_in' => sub {
    require IPC::Open3::Utils;
    return sub {
        shift;
        goto &IPC::Open3::Utils::put_cmd_in;
    };
};

Sub::Defer::defer_sub __PACKAGE__ . '::spork' => sub {
    require Acme::Spork;
    return sub {
        shift;
        goto &Acme::Spork::spork;
    };
};

# TODO: $app->ex->as_user($user, sub {…}[, @args])

1;

__END__

=encoding utf-8

=head1 NAME

App::Kit::Obj::Ex - system execution utility object

=head1 VERSION

This document describes App::Kit::Obj::Ex version 0.1

=head1 SYNOPSIS

    my $ex = App::Kit::Obj::Ex->new();
    $ex->run_cmd(…)

=head1 DESCRIPTION

system execution utility object

=head1 INTERFACE

=head2 new()

Returns the object.

Takes one required attribute: _app. It should be an L<App::Kit> object for it to use internally.

=head2 whereis()

Lazy wrapper of L<Unix::Whereis>’s whereis().

=head2 run_cmd()

Lazy wrapper of L<IPC::Open3::Utils>’s run_cmd().

=head2 put_cmd_in()

Lazy wrapper of L<IPC::Open3::Utils>’s put_cmd_in().

=head2 spork()

Lazy wrapper of L<Acme::Spork>’s spork().

=head2 runcom()

Takes one or more strings (to be output as a sort of header) or array refs (arguments to L<Running::Commentary>’s run().

If you do not call 'use App::Kit::Util::RunCom;' at begin time this method will raise an exception reminding you to do so.

See L<App::Kit::Util::RunCom> for more info on why that has to be that way.

=head2 fsleep()

Encapsulated fractional second sleep logic (via four argument select).

Takes the fractional seconds to sleep.

Return true (i.e. not the value of select()) after it is done.

=head1 DIAGNOSTICS

=over 4

=item C<< Due to compile time Shenanigans in an underlying module, you must 'use App::Kit::Util::RunCom;' to enable runcom(). >>

You called runcom() without setting it up first at compile time per its documentation.

=back

=head1 CONFIGURATION AND ENVIRONMENT

Requires no configuration files or environment variables.

=head1 DEPENDENCIES

L<Unix::Whereis>, L<IPC::Open3::Utils>, L<Acme::Spork>, L<Running::Commentary> (via App::Kit::Util::RunCom)

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
