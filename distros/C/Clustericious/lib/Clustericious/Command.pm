package Clustericious::Command;

use strict;
use warnings;
use Mojo::Base 'Mojolicious::Command';

# ABSTRACT: Command base class
our $VERSION = '1.27'; # VERSION


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Clustericious::Command - Command base class

=head1 VERSION

version 1.27

=head1 DESCRIPTION

This class is the base class for all Clustericious commands.  It
inherits everything from L<Mojolicious::Command> and will may add
Clustericious specific behavior in the future.

=head1 COMMANDS

This is a (not exhaustive) list of common Clustericious commands:

=over 4

=item *

L<apache|Clustericious::Command::apache>

=item *

L<configdebug|Clustericious::Command::configdebug>

=item *

L<configpath|Clustericious::Command::configpath>

=item *

L<configtest|Clustericious::Command::configtest>

=item *

L<configure|Clustericious::Command::configure>

=item *

L<generate app|Clustericious::Command::generate::app>

=item *

L<generate client|Clustericious::Command::generate::client>

=item *

L<hypnotoad|Clustericious::Command::hypnotoad>

=item *

L<lighttpd|Clustericious::Command::lighttpd>

=item *

L<plackup|Clustericious::Command::plackup>

=item *

L<start|Clustericious::Command::start>

=item *

L<status|Clustericious::Command::status>

=item *

L<stop|Clustericious::Command::stop>

=back

=head1 SEE ALSO

L<Clustericious>
L<Mojolicious::Command>

=head1 AUTHOR

Original author: Brian Duggan

Current maintainer: Graham Ollis E<lt>plicease@cpan.orgE<gt>

Contributors:

Curt Tilmes

Yanick Champoux

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by NASA GSFC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
