package Boxer::CLI::Command;

=encoding UTF-8

=cut

use v5.14;
use utf8;
use strictures 2;
use version;
use Role::Commons -all;

use Log::Any::Adapter qw<Screen>;
use App::Cmd::Setup-command;

use namespace::autoclean 0.16;

=head1 VERSION

Version v1.1.8

=cut

our $VERSION = version->declare("v1.1.8");

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
