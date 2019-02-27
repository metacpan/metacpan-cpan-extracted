package Boxer::Types;

=encoding UTF-8

=cut

use v5.14;
use utf8;
use strictures 2;
use version;
use Role::Commons -all;

use Path::Tiny;

use Type::Library -base,
	-declare => qw( DataDir ClassDir NodeDir SkelDir Basename Suite );
use Type::Utils -all;
use Types::Common::String qw(NonEmptySimpleStr LowerCaseSimpleStr);
use Types::Path::Tiny qw(Dir);

use namespace::autoclean 0.16;

=head1 VERSION

Version v1.2.0

=cut

our $VERSION = version->declare("v1.2.0");

declare DataDir, as Dir, coercion => 1, message {
	'Must be an existing directory containing directories for boxer classes and/or boxer nodes';
};

declare ClassDir, as Dir,
	coercion => 1,
	message {'Must be an existing directory containing boxer classes'};

declare NodeDir, as Dir,
	coercion => 1,
	message {'Must be an existing directory containing boxer nodes'};

declare SkelDir, as Dir,
	coercion => 1,
	message {'Must be an existing directory containing boxer skeleton files'};

declare Basename, as NonEmptySimpleStr,
	where { $_ eq path($_)->basename },
	message {'Must be a bare filename with no directory parts'};

declare Suite, as LowerCaseSimpleStr,
	coercion => 1,
	message {'Must be a single lowercase word'};

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
