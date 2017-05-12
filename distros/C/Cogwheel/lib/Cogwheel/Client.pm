#!/usr/bin/env perl
package Cogwheel::Client;
use strict;
use Cogwheel;
use Carp;

extends qw(Cogwheel::Object Sprocket::Client);
with qw(Cogwheel::Role::Plugins);

has '+name' => (
    default => sub { 'Test Client' },
    handles => [qw(Name)],
);

has ClientList => (
    isa     => 'ArrayRef',
    is      => 'ro',
    default => sub { [qw(localhost:31337)] },
    lazy    => 1,
);

has LogLevel => (
    isa     => 'Int',
    is      => 'ro',
    default => sub { 4 },
    lazy    => 1,
);

has TimeOut => (
    isa     => 'Int',
    is      => 'ro',
    default => sub { 0 },
    lazy    => 1,
);

no Moose;
1;
__END__

=head1 NAME

Cogwheel::Client - A Cogwheel Client baseclass

=head1 VERSION

Version 0.01

=cut

=head1 SYNOPSIS

    my $client = Cogwheel::Client->new(
           ClientList => ['localhost:31337'],
           Plugins    => [
               {
                   Plugin   => MyApp::Plugin;->new(),
                   Priority => 0,
               },
           ],
       );

=head1 DESCRIPTION

Represents a networking Client in the Cogwheel framework.

=head1 ATTRIBUTES

=over

=item Name

Name for the Client

=item Plugins

An ArrayRef of Plugin objects

=item TimeOut

Timeout for connection to the server

=item ClientList

ArrayRef of Servers to connect to

=item Logger

An optional logging object, it must provide the C<log> method

=item LogLevel

The minimum level for logging in the default logger. THis will default to 'warning' (4).

=back

=head1 METHODS

=over

=item new

Create a new Cogwheel::Client. You can pass in any of the attributes defined above.

=item add_plugin
=item remove_last_plugin
=item push_plugin

These methods are imported from L<Cogwheel::Role::Plugins>. 

=item pidbase
=item pidfile
=item daemonize
=item foreground
=item progname
=item shutdown

These methods are imported from L<MooseX::Daemonize>.

=item log

This method is imported from L<Cogwheel::Role::Logging>.

=item meta

This method is imported from L<Moose>.

=back


=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

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
