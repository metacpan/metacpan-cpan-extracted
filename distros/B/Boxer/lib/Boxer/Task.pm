package Boxer::Task;

=encoding UTF-8

=cut

use v5.14;
use utf8;
use Role::Commons -all;
use namespace::autoclean 0.16;
use autodie;

use Moo;
use MooX::StrictConstructor;
with qw( MooX::Role::Logger Boxer::Role::Interact );

use strictures 2;
no warnings "experimental::signatures";

=head1 VERSION

Version v1.4.3

=cut

our $VERSION = "v1.4.3";

=head1 DESCRIPTION

This is the base class for L<Boxer> tasks.

Tasks coerce, validate, and process application commands.

Currently implemented tasks:

=over 4

=item *

L<Classify|Boxer::Task::Classify>

=item *

L<Serialize|Boxer::Task::Serialize>

=item *

L<Bootstrap|Boxer::Task::Bootstrap>

=back


=head1 IDEAS

Tasks are separated from commands
to allow for different front-end interfaces,
even if currently only a single command-line tool is provided.

=head2 wrappers

Might be useful to provide wrappers for existing command-line tools,
preserving full behavior of the underlying tool
only extending it with relevant boxer options.

Examples:

=over 4

=item *

C<debootstrap-boxer [...] [--boxer-node=NODE[,NODE2...]] [...]>

=back

=head2 web

Would be cool to offer a web service
where you could request a customized system image
to be generated for you on demand.

=head1 AUTHOR

Jonas Smedegaard C<< <dr@jones.dk> >>.

=cut

our $AUTHORITY = 'cpan:JONASS';

=head1 COPYRIGHT AND LICENCE

Copyright © 2013-2016 Jonas Smedegaard

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

=cut

1;
