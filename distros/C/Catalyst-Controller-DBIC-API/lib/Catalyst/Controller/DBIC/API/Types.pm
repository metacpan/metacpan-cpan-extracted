package Catalyst::Controller::DBIC::API::Types;
$Catalyst::Controller::DBIC::API::Types::VERSION = '2.006002';
#ABSTRACT: Provides shortcut types and coercions for DBIC::API
use warnings;
use strict;

use MooseX::Types -declare => [
    qw( OrderedBy GroupedBy Prefetch SelectColumns AsAliases ResultSource
        ResultSet Model SearchParameters JoinBuilder )
];
use MooseX::Types::Moose(':all');


subtype Prefetch, as Maybe[ArrayRef[Str|HashRef]];
coerce Prefetch, from Str, via { [$_] }, from HashRef, via { [$_] };


subtype GroupedBy, as Maybe[ArrayRef[Str]];
coerce GroupedBy, from Str, via { [$_] };


subtype OrderedBy, as Maybe[ArrayRef[Str|HashRef|ScalarRef]];
coerce OrderedBy, from Str, via { [$_] }, from HashRef, via { [$_] };


subtype SelectColumns, as Maybe[ArrayRef[Str|HashRef]];
coerce SelectColumns, from Str, via { [$_] }, from HashRef, via { [$_] };


subtype SearchParameters, as Maybe[ArrayRef[HashRef]];
coerce SearchParameters, from HashRef, via { [$_] };


subtype AsAliases, as Maybe[ArrayRef[Str]];


subtype ResultSet, as class_type('DBIx::Class::ResultSet');


subtype ResultSource, as class_type('DBIx::Class::ResultSource');


subtype JoinBuilder,
    as class_type('Catalyst::Controller::DBIC::API::JoinBuilder');


subtype Model, as class_type('DBIx::Class');

1;

__END__

=pod

=head1 NAME

Catalyst::Controller::DBIC::API::Types - Provides shortcut types and coercions for DBIC::API

=head1 VERSION

version 2.006002

=head1 TYPES

=head2 Prefetch as Maybe[ArrayRef[Str|HashRef]]

Represents the structure of the prefetch argument.

Coerces Str and HashRef.

=head2 GroupedBy as Maybe[ArrayRef[Str]]

Represents the structure of the grouped_by argument.

Coerces Str.

=head2 OrderedBy as Maybe[ArrayRef[Str|HashRef|ScalarRef]]

Represents the structure of the ordered_by argument

Coerces Str.

=head2 SelectColumns as Maybe[ArrayRef[Str|HashRef]]

Represents the structure of the select argument

Coerces Str.

=head2 SearchParameters as Maybe[ArrayRef[HashRef]]

Represents the structure of the search argument

Coerces HashRef.

=head2 AsAliases as Maybe[ArrayRef[Str]]

Represents the structure of the as argument

=head2 ResultSet as class_type('DBIx::Class::ResultSet')

Shortcut for DBIx::Class::ResultSet

=head2 ResultSource as class_type('DBIx::Class::ResultSource')

Shortcut for DBIx::Class::ResultSource

=head2 JoinBuilder as class_type('Catalyst::Controller::DBIC::API::JoinBuilder')

Shortcut for Catalyst::Controller::DBIC::API::JoinBuilder

=head2 Model as class_type('DBIx::Class')

Shortcut for model objects

=head1 AUTHORS

=over 4

=item *

Nicholas Perez <nperez@cpan.org>

=item *

Luke Saunders <luke.saunders@gmail.com>

=item *

Alexander Hartmaier <abraxxa@cpan.org>

=item *

Florian Ragwitz <rafl@debian.org>

=item *

Oleg Kostyuk <cub.uanic@gmail.com>

=item *

Samuel Kaufman <sam@socialflow.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Luke Saunders, Nicholas Perez, Alexander Hartmaier, et al..

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
