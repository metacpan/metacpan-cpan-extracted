package Data::Focus;
use strict;
use warnings;
use Data::Focus::Lens::Composite;
use Carp;
use Exporter qw(import);
use Scalar::Util ();

our $VERSION = "0.03";

our @EXPORT_OK = qw(focus);

sub focus {
    my ($target, @lenses) = @_;
    return __PACKAGE__->new(target => $target, lens => \@lenses);
}

sub new {
    my ($class, %args) = @_;
    croak "target param is mandatory" if !exists($args{target});
    my $target = $args{target};
    my $lenses = exists($args{lens}) ?
        (ref($args{lens}) eq "ARRAY" ? $args{lens} : [$args{lens}])
        : [];
    $_ = $class->coerce_to_lens($_) foreach @$lenses;
    my $self = bless {
        target => $target,
        lenses => $lenses
    }, $class;
    return $self;
}

sub coerce_to_lens {
    my (undef, $maybe_lens) = @_;
    if(Scalar::Util::blessed($maybe_lens) && $maybe_lens->isa("Data::Focus::Lens")) {
        return $maybe_lens;
    }else {
        require Data::Focus::Lens::Dynamic;
        return Data::Focus::Lens::Dynamic->new($maybe_lens);
    }
}

sub into {
    my ($self, @lenses) = @_;
    unshift @lenses, @{$self->{lenses}};
    my $deeper = ref($self)->new(
        target => $self->{target},
        lens => \@lenses,
    );
    return $deeper;
}

sub _apply_lenses_to_target {
    my ($self, $app_class, $updater, @additional_lenses) = @_;
    my @lenses = (@{$self->{lenses}}, map { $self->coerce_to_lens($_) } @additional_lenses);
    if(@lenses == 1) {
        return $lenses[0]->apply_lens(
            $app_class, $app_class->create_part_mapper($updater), $self->{target}
        );
    }else {
        return Data::Focus::Lens::Composite->apply_composite_lens(
            \@lenses,
            $app_class,
            $app_class->create_part_mapper($updater),
            $self->{target}
        );
    }
}

sub get {
    my ($self, @lenses) = @_;
    require Data::Focus::Applicative::Const::First;
    my $ret = $self->_apply_lenses_to_target(
        "Data::Focus::Applicative::Const::First", undef, @lenses
    )->get_const;
    return defined($ret) ? $$ret : undef;
}

sub list {
    my ($self, @lenses) = @_;
    require Data::Focus::Applicative::Const::List;
    my $traversed_list = $self->_apply_lenses_to_target(
        "Data::Focus::Applicative::Const::List", undef, @lenses
    )->get_const;
    return wantarray ? @$traversed_list : $traversed_list->[0];
}

sub over {
    my $updater = pop;
    my ($self, @lenses) = @_;
    croak "updater param must be a code-ref" if ref($updater) ne "CODE";
    require Data::Focus::Applicative::Identity;
    return $self->_apply_lenses_to_target(
        "Data::Focus::Applicative::Identity", $updater, @lenses
    )->run_identity;
}

sub set {
    my $datum = pop;
    my $self = shift;
    return $self->over(@_, sub { $datum });
}

1;
__END__

=pod

=head1 NAME

Data::Focus - generic getter/setter/traverser for complex data structures

=head1 SYNOPSIS

    use Data::Focus qw(focus);

    my $target = [
        "hoge",
        {
            foo => "bar",
            quux => ["x", "y", "z"]
        }
    ];

    my $z = focus($target)->get(1, "quux", 2);
    my @xyz = focus($target)->list(1, "quux", [0,1,2]);
    ## $z: "z"
    ## @xyz: qw(x y z)

    focus($target)->set(1, "foo",  10);
    focus($target)->set(1, "quux", 11);
    ## $target: ["hoge", {foo => 10, quux => 11}]

    focus($target)->over(1, ["foo", "quux"], sub { $_[0] * $_[0] });
    ## $target: ["hoge", {foo => 100, quux => 121}]

=head1 DESCRIPTION

B<tl;dr>: This is a port of Haskell's L<lens-family-core|http://hackage.haskell.org/package/lens-family-core> package.

L<Data::Focus> provides a way to access data elements in a deep, complex and nested data structure.
So it's just a complicated version of L<Data::Diver>, but L<Data::Focus> has the following notable features.

=over

=item *

It provides a B<< generic way >> to access B<any> type of objects as long as they have appropriate "lenses".
It's like L<DBI> of accessing nested data structures.

=item *

It makes it easy to update B<immutable> objects. Strictly speaking, that means creating B<partially> modified copies of immutable objects.

=back

=head2 Concept

L<Data::Focus> focuses on some parts of a complex data structure.
The complex data is called the B<target>.
The parts it focuses on are called B<focal points>.
With L<Data::Focus>, you can get/set/modify the data at the focal points within the target.

L<Data::Focus> uses objects called B<lenses> to focus on data parts.
Lenses are like DBD::* modules in L<DBI> framework.
They know how to focus on the data parts in the target.
Different lenses are used to focus into different types of targets.

For example, consider the following code.

    my $target = ["hoge", { foo => "bar" }];
    my $part = $target->[1]{foo};
    $target->[1]{foo} = "buzz";

In Perl, we can access the data part (C<"bar">) in the C<$target> by the subscripts C<< ->[1]{foo} >>.
A lens's job is exactly what C<< ->[1]{foo} >> does here.

With L<Data::Focus> we can rewrite the above example to:

    use Data::Focus qw(focus);
    use Data::Focus::Lens::HashArray::Index;
    
    my $target = ["hoge", { foo => "bar" }];
    my $lens_1   = Data::Focus::Lens::HashArray::Index->new(index => 1);
    my $lens_foo = Data::Focus::Lens::HashArray::Index->new(index => "foo");
    my $part = focus($target)->get($lens_1, $lens_foo);
    focus($target)->set($lens_1, $lens_foo, "buzz");

(I'm sure you don't wanna write this amount of code just to access an element in the C<$target>. Don't worry. I'll shorten them below.)

Anyway, the point is, C<focus()> function wraps the C<$target> in a L<Data::Focus> object,
and methods of the L<Data::Focus> object use lenses to access data parts at the focal points.

=head2 Lenses

Every lens is a subclass of L<Data::Focus::Lens> class. Lenses included in this distribution are:

=over

=item L<Data::Focus::Lens::HashArray::Index>

Index access to a hash/array. It's like C<< $hash->{$i}, $array->[$i], @{$hash}{$i1, $i2}, @{$array}[$i1, $i2] >>.

=item L<Data::Focus::Lens::HashArray::All>

Access all values in a hash/array. It's like C<< values(%$hash), @$array >>.

=item L<Data::Focus::Lens::HashArray::Recurse>

Recursively traverse all values in a tree of hashes and arrays.

=item L<Data::Focus::Lens::Accessor>

Call an accessor method of a blessed object. It's like C<< $obj->method >>.

=item L<Data::Focus::Lens::Composite>

Composition of multiple lenses.

=item L<Data::Focus::Lens::Dynamic>

A front-end lens that dynamically creates an appropriate lens for you.

=back

All Data::Focus::HashArray::* modules optionally support immutable update. See individual documents for detail.

=head2 Lens Coercion

If you pass something that's not a L<Data::Focus::Lens> object to L<Data::Focus>'s methods,
it is coerced (cast) to a lens.

The passed value is used to create L<Data::Focus::Lens::Dynamic> lens.
Then that lens creates an appropriate lens for the given target with the passed value.
This means we can rewrite the above example to:

    use Data::Focus qw(focus);
    
    my $target = ["hoge", { foo => "bar" }];
    my $part = focus($target)->get(1, "foo");
    focus($target)->set(1, foo => "buzz");

The above is possible because L<Data::Focus::Lens::Dynamic> creates L<Data::Focus::Lens::HashArray::Index> lenses under the hood.
See L<Data::Focus::Lens::Dynamic> for detail.

=head2 Traversals

As you might already notice, a lens can have more than one focal points. This is like slices and traversals.

To obtain all elements at the focal points, use C<list()> method.

    my $target = ["a", "b", "c"];
    my @abc = focus($target)->list([0, 1, 2]);

Sometimes a lens has no focal point.
In that case, you cannot set value to the target.

=head2 Lens Composition

You can compose two lenses to create a composite lens by C<"."> operator.

    my $target = ["hoge", { foo => "bar" }];
    my $lens_1   = Data::Focus::Lens::HashArray::Index->new(index => 1);
    my $lens_foo = Data::Focus::Lens::HashArray::Index->new(index => "foo");

    my $composite = $lens_1 . $lens_foo;

    my $part = focus($target)->get($composite);
    focus($target)->set($composite, "buzz");

To compose two or more lenses at once, use L<Data::Focus::Lens::Composite>.

=head1 EXPORTABLE FUNCTIONS

These functions are exported only by request.

=head2 $focused = focus($target, @lenses)

Alias of C<< Data::Focus->new(target => $target, lens => \@lenses) >>.
It creates a L<Data::Focus> object. C<@lenses> are optional.

=head1 CLASS METHODS

=head2 $focused = Data::Focus->new(%args)

The constructor. Fields in C<%args> are:

=over

=item C<target> => SCALAR (mandatory)

The target object it focuses into.

=item C<lens> => LENS or ARRAYREF_OF_LENSES (optional)

A lens or an array-ref of lenses used for focusing.
If some of the lenses are not L<Data::Focus::Lens> objects, they are coerced. See L</Lens Coercion> for detail.

=back

=head2 $lens = Data::Focus->coerce_to_lens($maybe_lens)

Coerce C<$maybe_lens> to a L<Data::Focus::Lens> object.

If C<$maybe_lens> is already a L<Data::Focus::Lens>, it returns C<$maybe_lens>.
Otherwise, it creates a lens out of C<$maybe_lens>. See L</Lens Coercion> for detail.

=head1 OBJECT METHODS

=head2 $deeper_focused = $focused->into(@lenses)

Focus more deeply with the given C<@lenses> and return the L<Data::Focus> object.

C<$deeper_focused> is a new L<Data::Focus> object. C<$focused> remains unchanged.

    my $result1 = $focused->into("foo", "bar")->get();
    my $result2 = $focused->into("foo")->get("bar");
    my $result3 = $focused->get("foo", "bar");
    
    ## $result1 == $result2 == $result3

=head2 $datum = $focused->get(@lenses)

Get the focused C<$datum>.

The arguments C<@lenses> are optional.
If supplied, C<@lenses> are used to focus more deeply into the target to return C<$datum>.

If it focuses on nothing (zero focal point), it returns C<undef>.

If it focuses on more than one values (multiple focal points), it returns the first value.

=head2 @data = $focused->list(@lenses)

Get the focused C<@data>.

The arguments C<@lenses> are optional.
If supplied, C<@lenses> are used to focus more deeply into the target to return C<@data>.

If it focuses on nothing (zero focal point), it returns an empty list.

If it focuses on more than one values (multiple focal points), it returns all of them.

=head2 $modified_target = $focused->set(@lenses, $datum)

Set the value of the focused element to C<$datum>, and return the C<$modified_target>.

The arguments C<@lenses> are optional.
If supplied, C<@lenses> are used to focus more deeply into the target.

If it focuses on nothing (zero focal point), it modifies nothing.
C<$modified_target> is usually the same instance as the target, or its clone (it depends on the lenses used).

If it focuses on more than one values (multiple focal points), it sets all of them to C<$datum>.

=head2 $modified_target = $focused->over(@lenses, $updater)

Update the value of the focused element by C<$updater>, and return the C<$modified_target>.

The arguments C<@lenses> are optional.
If supplied, C<@lenses> are used to focus more deeply into the target.

C<$updater> is a code-ref. It is called like

    $modified_datum = $updater->($focused_datum)

where C<$focused_datum> is a datum at one of the focal points in the target.
C<$modified_datum> replaces the C<$focused_datum> in the C<$modified_target>.

If it focuses on nothing (zero focal point), C<$updater> is never called.
C<$modified_target> is usually the same instance as the target, or its clone (it depends on the lenses used).

If it focuses on more than one values (multiple focal points), C<$updater> is repeatedly called for each of them.

=head1 HOW TO CREATE A LENS

To create your own lens, you have to write a subclass of L<Data::Focus::Lens> that implements its abstract methods.
However, B<< writing your own Lens class from scratch is currently discouraged. >>
Instead we recommend using L<Data::Focus::LensMaker>.

L<Data::Focus::LensTester> provides some common tests for lenses.

=head1 MAKE YOUR OWN CLASS LENS-READY

You can associate your own class with a specific lens object by implementing C<Lens()> method in your class.
See L<Data::Focus::Lens::Dynamic> for detail.

Once C<Lens()> method is implemented, you can focus into objects of that class without explicitly creating lens objects for it.

    package My::Class;
    
    ...
    
    sub Lens {
        my ($self, $param);
        my $lens = ...; ## create a Data::Focus::Lens object
        return $lens;
    }
    
    
    package main;
    use Data::Focus qw(focus);
    
    my $obj = My::Class->new(...);
    
    focus($obj)->get("hoge");
    focus($obj)->set(foo => "bar");


=head1 RELATIONSHIP TO HASKELL

L<Data::Focus>'s API and implementation are based on Haskell packages L<lens-family-core|http://hackage.haskell.org/package/lens-family-core>
and L<lens|http://hackage.haskell.org/package/lens>.

For those familiar with Haskell's lens libraries, here is the Haskell-to-Perl mapping of terminology.

=over

=item C<Traversal>

The C<Traversal> type corrensponds to L<Data::Focus::Lens>. Currently there's no strict counterpart for C<Lens>, C<Prism> or C<Iso> type.

=item C<< (^.) >>

No counterpart in L<Data::Focus>.

=item C<< (^?) >>

C<get()> method of L<Data::Focus>.

=item C<< (^..) >>

C<list()> method of L<Data::Focus>.

=item C<< (.~) >>

C<set()> method of L<Data::Focus>.

=item C<< (%~) >>

C<over()> method of L<Data::Focus>.

=item C<Applicative>

C<Applicative> typeclass corrensponds to L<Data::Focus::Applicative>.

=back

=head1 SEE ALSO

There are tons of modules in CPAN for data access and traversal.

=over

=item *

L<Data::Diver>

=item *

L<JSON::Pointer>

=item *

L<Data::Path>

=item *

L<Data::SPath>

=item *

L<Data::DPath>

=item *

L<Data::FetchPath>

=item *

L<Data::PathSimple>

=item *

L<Data::SimplePath>

=item *

L<Data::Transformer>

=item *

L<Data::Walk>

=item *

L<Data::Traverse>

=back

=head1 REPOSITORY

L<https://github.com/debug-ito/Data-Focus>

=head1 BUGS AND FEATURE REQUESTS

Please report bugs and feature requests to my Github issues
L<https://github.com/debug-ito/Data-Focus/issues>.

Although I prefer Github, non-Github users can use CPAN RT
L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Focus>.
Please send email to C<bug-Data-Focus at rt.cpan.org> to report bugs
if you do not have CPAN RT account.


=head1 AUTHOR
 
Toshio Ito, C<< <toshioito at cpan.org> >>


=head1 LICENSE AND COPYRIGHT

Copyright 2015 Toshio Ito.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.


=cut

