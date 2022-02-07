package Boxer::Types;

=encoding UTF-8

=cut

use v5.14;
use utf8;
use Role::Commons -all;
use namespace::autoclean;

use Path::Tiny;

use Type::Library -base, -declare => qw(
	WorldName DataDir ClassDir NodeDir SkelDir Basename Suite SerializationList );
use Type::Utils;
use Types::Standard qw( ArrayRef Split Str Tuple StrMatch slurpy );
use Types::Common::String qw( NonEmptySimpleStr LowerCaseSimpleStr );
use Types::Path::Tiny qw(Dir);

use strictures 2;
no warnings "experimental::signatures";

=head1 VERSION

Version v1.4.3

=cut

our $VERSION = "v1.4.3";

declare WorldName, as LowerCaseSimpleStr,
	coercion => 1,
	message {'Must be a single lowercase word'};

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

my $SerializationList = "Type::Tiny"->new(
	name   => 'SerializationList',
	parent =>
		Tuple [ slurpy ArrayRef [ StrMatch [qr{^(?:preseed|script)$}] ] ],
);
declare SerializationList,
	as $SerializationList->plus_coercions( Split [qr/[^a-z]+/] ),
	coercion => 1,
	message {'Must be one or more of these words: preseed script'};

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
