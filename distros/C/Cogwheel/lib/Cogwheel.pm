package Cogwheel;
our $VERSION = 0.03;
use Moose;
use Cogwheel::Object;
use Cogwheel::Types;
{

    sub import {
        my $CALLER = caller();

        strict->import;
        warnings->import;

        # we should never export to main
        return if $CALLER eq 'main';
        Moose::init_meta( $CALLER, 'Cogwheel::Object' );
        Moose->import( { into => $CALLER } );

        # Do my custom framework stuff

        return 1;
    }

    sub unimport {
        goto Moose->can('unimport');
    }
}

no Moose;
1;
__END__


=head1 NAME

Cogwheel - A Client/Server Networking Framework based on Moose and Sprocket

=head1 VERSION

Version 0.01

=cut

=head1 SYNOPSIS

    package main;
    use MyApp::Plugin;
    use Cogwheel::Client;
    use Cogwheel::Server;

    my $server = Cogwheel::Server->new(
        Plugins => [
            {
                plugin   => MyApp::Plugin;->new(),
                priority => 0,
            },
        ],
    );

    my $client = Cogwheel::Client->new(
        ClientList => ['localhost:31337'],
        Plugins    => [
            {
                Plugin   => MyApp::Plugin;->new(),
                Priority => 0,
            },
        ],
    );

    POE::Kernel->run();

=head1 DESCRIPTION

Cogwheel is a framework for building Network Clients and Servers. It is based off the Sprocket library and Moose.

=head1 METHODS

None of the methods in Cogheel itself are truely public, but they are documented here for completeness.

=over

=item import

Called via C<use Cogwheel;> this will setup the metaclass system properly so that Coghweel objects inherit from C<Cogwheel::Object>. This also enables C<strict> and C<warnings>.

=item unimport

Unimports any methods exported by import;

=item meta

Imported from Moose.

=back

=head1 DEPENDENCIES

Obviously L<Moose>, and L<Sprocket>

=head1 INCOMPATIBILITIES

None reported.


=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-cogwheell@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 SEE ALSO

L<Moose>, and L<Sprocket>

=head1 AUTHOR

Chris Prather  C<< <perigrin@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright 2006, 2007 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

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
