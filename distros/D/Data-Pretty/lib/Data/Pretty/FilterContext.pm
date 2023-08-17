package Data::Pretty::FilterContext;
BEGIN
{
    use strict;
    use warnings;
    use vars qw( $VERSION );
    our $VERSION = 'v0.1.0';
};

use strict;
use warnings;

sub new {
    my($class, $obj, $oclass, $type, $ref, $pclass, $pidx, $idx) = @_;
    return bless {
        object => $obj,
        class => $ref && $oclass,
        reftype => $type,
        is_ref => $ref,
        pclass => $pclass,
        pidx => $pidx,
        idx => $idx,
    }, $class;
}

sub object_ref {
    my $self = shift;
    return $self->{object};
}

sub class {
    my $self = shift;
    return $self->{class} || "";
}

{
    no warnings 'once';
    *is_blessed = \&class;
}

sub reftype {
    my $self = shift;
    return $self->{reftype};
}

sub is_scalar {
    my $self = shift;
    return $self->{reftype} eq "SCALAR";
}

sub is_array {
    my $self = shift;
    return $self->{reftype} eq "ARRAY";
}

sub is_hash {
    my $self = shift;
    return $self->{reftype} eq "HASH";
}

sub is_code {
    my $self = shift;
    return $self->{reftype} eq "CODE";
}

sub is_ref {
    my $self = shift;
    return $self->{is_ref};
}

sub container_class {
    my $self = shift;
    return $self->{pclass} || "";
}

sub container_self {
    my $self = shift;
    return "" unless $self->{pclass};
    my $idx = $self->{idx};
    my $pidx = $self->{pidx};
    return Data::Pretty::fullname("self", [@$idx[$pidx..(@$idx - 1)]]);
}

sub expr {
    my $self = shift;
    my $top = shift || "var";
    $top =~ s/^\$//; # it's always added by fullname()
    my $idx = $self->{idx};
    return Data::Pretty::fullname($top, $idx);
}

sub object_isa {
    my($self, $class) = @_;
    return $self->{class} && $self->{class}->isa($class);
}

sub container_isa {
    my($self, $class) = @_;
    return $self->{pclass} && $self->{pclass}->isa($class);
}

sub depth {
    my $self = shift;
    return scalar @{$self->{idx}};
}

1;
# NOTE: POD
__END__
=encoding utf-8

=head1 NAME

Data::Pretty::FilterContext - Data Dump Beautifier Filter Context

=head1 SYNOPSIS

    use Data::Pretty::FilterContext;
    my $ctx = Data::Pretty::FilterContext->new( $rval, $class, $type, $ref, $pclass, $pidx, $idx );

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

The context object provide methods that can be used to determine what kind of object is currently visited and where it is located. The context object has the following interface

=head1 CONSTRUCTOR

=head2 new

This takes the following arguments and returns the newly instantiated object.

=over 4

=item * C<$rval>

The value passed as a reference.

=item * C<$class>

The object class, if any.

=item * C<$type>

The data type, such as C<ARRAY>, C<CODE>, C<GLOB>, C<HASH>, C<REF>, C<REGEXP>, C<SCALAR> or C<VSTRING>

=item * C<$ref>

The data reference as returned by L<perlfunc/ref>

=item * C<$pclass>

A container class, if any

=item * C<$pidx>

=item * C<$idx>

=back

=head1 METHODS

=head2 object_ref

Alternative way to obtain a reference to the current object

=head2 class

If the object is blessed this return the class. Returns "" for objects not blessed.

=head2 reftype

Returns what kind of object this is. It's a string like C<ARRAY>, C<CODE>, C<GLOB>, C<HASH>, C<REF>, C<REGEXP>, C<SCALAR> or C<VSTRING>

=head2 is_ref

Returns true if a reference was provided.

=head2 is_blessed

Returns true if the object is blessed. Actually, this is just an alias for C<< $ctx->class >>.

=head2 is_array

Returns true if the object is an array

=head2 is_hash

Returns true if the object is a hash

=head2 is_scalar

Returns true if the object is a scalar (a string or a number)

=head2 is_code

Returns true if the object is a function (aka subroutine)

=head2 container_class

Returns the class of the innermost container that contains this object. Returns "" if there is no blessed container.

=head2 container_self

Returns an textual expression relative to the container object that names this object. The variable C<$self> in this expression is the container itself.

=head2 object_isa( $class )

Returns TRUE if the current object is of the given class or is of a subclass.

=head2 container_isa( $class )

Returns TRUE if the innermost container is of the given class or is of a subclass.

=head2 depth

Returns how many levels deep have we recursed into the structure (from the original dump_filtered() arguments).

=head2 expr

=head2 expr( $top_level_name )

Returns an textual expression that denotes the current object. In the expression C<$var> is used as the name of the top level object dumped. This can be overridden by providing a different name as argument.

=head1 SEE ALSO

L<Data::Pretty>

=head1 CREDITS

Credits to Gisle Aas for the original L<Data::Dump> version and to Breno G. de Oliveira for maintaining it.

=head1 COPYRIGHT & LICENSE

Copyright(c) 2023 DEGUEST Pte. Ltd.

All rights reserved

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
