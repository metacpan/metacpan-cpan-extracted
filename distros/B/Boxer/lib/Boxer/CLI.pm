package Boxer::CLI;

=encoding UTF-8

=head1 NAME

Boxer::CLI - boxer command line utils

=cut

use v5.14;
use utf8;
use Role::Commons -all;
use namespace::autoclean 0.16;

use App::Cmd::Setup -app;

use strictures 2;
no warnings "experimental::signatures";

=head1 VERSION

Version v1.4.2

=cut

our $VERSION = "v1.4.2";

=head1 SYNOPSIS

 use Boxer::CLI;
 BOXER::CLI->run;

=head1 DESCRIPTION

Support library for the L<boxer> command-line tool.

=head1 SEE ALSO

L<boxer>, L<Boxer>.

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
