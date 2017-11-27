package Chloro::Group;

use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.07';

use Moose;
use MooseX::StrictConstructor;

use Chloro::Types qw( CodeRef HashOfFields NonEmptyStr NonEmptySimpleStr );

with 'Chloro::Role::FormComponent';

has _fields => (
    traits   => ['Hash'],
    isa      => HashOfFields,
    coerce   => 1,
    init_arg => 'fields',
    required => 1,
    handles  => {
        fields    => 'values',
        get_field => 'get',
    },
);

has repetition_key => (
    is       => 'ro',
    isa      => NonEmptyStr,
    required => 1,
);

has is_empty_checker => (
    is      => 'ro',
    isa     => NonEmptySimpleStr,
    default => '_group_is_empty',
);

## no critic (Subroutines::ProhibitBuiltinHomonyms)
sub dump {
    my $self = shift;

    return (
        repetition_key => $self->repetition_key(),
        fields => { map { $_->name() => { $_->dump() } } $self->fields() },
    );
}
## use critic

__PACKAGE__->meta()->make_immutable();

1;

# ABSTRACT: A field in a form

__END__

=pod

=encoding UTF-8

=head1 NAME

Chloro::Group - A field in a form

=head1 VERSION

version 0.07

=head1 SYNOPSIS

See L<Chloro>.

=head1 DESCRIPTION

This class represents a group in a form.

=head1 METHODS

This class has the following methods:

=head2 Chloro::Group->new()

You'll probably make groups by using the C<group()> subroutine exported by
L<Chloro>, but you can make one using this constructor.

The constructor accepts the following parameters:

=over 4

=item * name

The name of the group. This is required.

=item * human_name

A more friendly version of the name. This defaults to the same value as
C<name>.

=item * fields

An array reference of L<Chloro::Field> objects for this group. This is
required.

=item * repetition_key

The name of the key field for repetitions.

=item * is_empty_checker

This is an optional method I<on the field's form> that will be used to extract
this field's value.

=back

=head2 $group->name()

The name as passed to the constructor.

=head2 $group->human_name()

A more friendly name, which defaults to the same value as C<< $group->name()
>>.

=head2 $group->fields()

Returns a list of L<Chloro::Field> objects for this group

=head2 $group->get_field($name)

Given a name, returns the field of that name in the group, if one exists.

=head2 $group->repetition_key()

The name of the repetition key field for this group.

=head2 $group->is_empty_checker()

Returns the method used to determine whether the group is empty. This defaults
to L<_group_is_empty>, a method provided by L<Chloro::Role::Form>.

=head2 $group->dump()

Returns a data structure representing the group definition. This exists
primarily for testing.

=head1 ROLES

This class consumes the L<Chloro::Role::FormComponent> role.

=head1 SUPPORT

Bugs may be submitted at L<http://rt.cpan.org/Public/Dist/Display.html?Name=Chloro> or via email to L<bug-chloro@rt.cpan.org|mailto:bug-chloro@rt.cpan.org>.

I am also usually active on IRC as 'autarch' on C<irc://irc.perl.org>.

=head1 SOURCE

The source code repository for Chloro can be found at L<https://github.com/autarch/Chloro>.

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Dave Rolsky.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

The full text of the license can be found in the
F<LICENSE> file included with this distribution.

=cut
