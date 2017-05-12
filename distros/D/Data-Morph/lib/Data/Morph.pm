package Data::Morph;
$Data::Morph::VERSION = '1.140400';
#ABSTRACT: Morph data from one source to another

use Moose;
use Moose::Util::TypeConstraints;
use MooseX::Types::Moose(':all');
use MooseX::Types::Structured(':all');
use MooseX::Params::Validate;
use Moose::Util::TypeConstraints;
use namespace::autoclean;



has [qw/recto verso/] =>
(
    is => 'ro',
    does => 'Data::Morph::Role::Backend',
    required => 1,
);


has map =>
(
    is => 'ro',
    isa => ArrayRef
    [
        Dict
        [
            verso =>
            (
                Str|Dict
                [
                    read => union( [Str, Tuple[Maybe[Str], CodeRef]] ),
                    write => Optional[Str|Tuple[Str, CodeRef]],
                ]
            ),
            recto =>
            (
                Str|Dict
                [
                    read => union( [Str, Tuple[Maybe[Str], CodeRef]] ),
                    write => Optional[Str|Tuple[Str, CodeRef]],
                ]
            )
        ]
    ],
    required => 1,
);


has morpher =>
(
    is => 'ro',
    isa => HashRef,
    builder => '_build_morpher',
    lazy => 1,
);

sub _build_morpher
{
    my ($self) = @_;
    my $hash = {};
    my $map = $self->map;
    my ($recto, $verso) = ($self->recto, $self->verso);

    $hash->{$recto->input_type} = sub
    {
        my ($input) = @_;

        my $instance = $verso->generate_instance($input);
        foreach my $entry (@$map)
        {
            my ($recto_map, $verso_map) = @$entry{qw/recto verso/};

            next if ref($verso_map) and
                (!exists($verso_map->{write}) || !defined($verso_map->{write}));

            my $val = $recto->retrieve
            (
                $input,
                (
                    ref($recto_map)
                    ? ref($recto_map->{read})
                        ? @{$recto_map->{read}}
                        : $recto_map->{read}
                    : $recto_map
                )
            );

            $verso->store
            (
                $instance,
                $val,
                (
                    ref($verso_map)
                    ? ref($verso_map->{write})
                        ? @{$verso_map->{write}}
                        : $verso_map->{write}
                    : $verso_map
                ),
            );
        }

        $verso->epilogue($instance);

        return $instance;
    };

    $hash->{$verso->input_type} = sub
    {
        my ($input) = @_;

        my $instance = $recto->generate_instance($input);
        foreach my $entry (@$map)
        {
            my ($recto_map, $verso_map) = @$entry{qw/recto verso/};

            next if ref($recto_map) and
                (!exists($recto_map->{write}) || !defined($recto_map->{write}));

            my $val = $verso->retrieve
            (
                $input,
                (
                    ref($verso_map)
                    ? ref($verso_map->{read})
                        ? @{$verso_map->{read}}
                        : $verso_map->{read}
                    : $verso_map
                )
            );

            $recto->store
            (
                $instance,
                $val,
                (
                    ref($recto_map)
                    ? ref($recto_map->{write})
                        ? @{$recto_map->{write}}
                        : $recto_map->{write}
                    : $recto_map
                ),
            );
        }

        $recto->epilogue($instance);

        return $instance;

    };

    return $hash;
}


sub morph
{
    my ($self, $object) = pos_validated_list
    (
        \@_,
        {isa => __PACKAGE__},
        {isa => Defined},
    );

    return match_on_type $object => %{$self->morpher};
}

1;

__END__

=pod

=head1 NAME

Data::Morph - Morph data from one source to another

=head1 VERSION

version 1.140400

=head1 SYNOPSIS

    use Data::Morph;
    use Data::Morph::Backend::Object;
    use Data::Morph::Backend::Raw;

    {
        package Foo;
        use Moose;
        use namespace::autoclean;

        has foo => ( is => 'ro', isa => 'Int', default => 1,
            writer => 'set_foo' );
        has bar => ( is => 'rw', isa => 'Str', default => '123ABC');
        has flarg => ( is => 'rw', isa => 'Str', default => 'boo');
        1;
    }

    my $map1 =
    [
        {
            recto =>
            {
                read => 'foo',
                write => 'set_foo',
            },
            verso => '/FOO',
        },
        {
            recto =>
            {
                read => ['bar', sub { my ($f) = @_; $f =~ s/\d+//; $f } ],
                write => [ 'bar', sub { "123".shift(@_) } ], # pre write
            },
            verso => 
            {
                read => '/BAR|/bar',
                write => '/BAR',
            },
        },
        {
            recto => 'flarg',
            verso => '/some/path/goes/*[2]/here/flarg'
        },
    ];

    my $obj_backend = Data::Morph::Backend::Object->new(new_instance => sub {
        Foo->new() });
    my $raw_backend = Data::Morph::Backend::Raw->new();

    my $morpher = Data::Morph->new(
        recto => $obj_backend,
        verso => $raw_backend,
        map => $map1
    );

    my $foo1 = Foo->new();
    my $hash = $morpher->morph($foo1);
    my $foo2 = $morpher->morph($hash);

    # While not the same instance, the values of the attributes for $foo1 and
    #   $foo2 match

=head1 DESCRIPTION

Data::Morph is a module that provides a solution for translating data from one
source to another via maps and backends. It is written such that data can be
shifted both directions. The L</SYNOPSIS> demonstrates a somewhat trivial
example of using the L<Data::Morph::Backend::Object> and
L<Data::Morph::Backend::Raw> that round trips the defaults out the Foo class to
a hash and back again. Not shown is the other shipped backend
L<Data::Morph::Backend::DBIC> which operates on L<DBIx::Class::Row> objects. If
a more specialized backend is needed take a look at consuming
L<Data::Morph::Role::Backend>. 

=head1 PUBLIC_ATTRIBUTES

=head2 recto

    is: ro, does: Data::Morph::Role::Backend, required: 1

One of the required backends necessary for data morphing. The term recto comes
from the terms meaning front and back of a page in a bound item such as a book.
The provided instance to this attribute via constructor argument will need to
consume the L<Data::Morph::Role::Backend> role.

Which backend that ends up in this slot or the L</verso> slot doesn't really
matter. Data morphing is a two way street of awesomeness that operates based on
the type of the input.

=head2 verso

    is: ro, does: Data::Morph::Role::Backend, required: 1

One of the required backends necessary for data morphing. The term verso comes
from the terms meaning front and back of a page in a bound item such as a book.
The provided instance to this attribute via constructor argument will need to
consume the L<Data::Morph::Role::Backend> role.

Which backend that ends up in this slot or the L</recto> slot doesn't really
matter. Data morphing is a two way street of awesomeness that operates based on
the type of the input.

=head2 map

    is: ro, isa: ArrayRef
    [
        Dict
        [
            verso =>
            (
                Str|Dict
                [
                    read => union( [Str, Tuple[Maybe[Str], CodeRef]] ),
                    write => Optional[Str|Tuple[Str, CodeRef]],
                ]
            ),
            recto =>
            (
                Str|Dict
                [
                    read => union( [Str, Tuple[Maybe[Str], CodeRef]] ),
                    write => Optional[Str|Tuple[Str, CodeRef]],
                ]
            )
        ]
    ],
    required: 1

In order to properly morph data from one source to another, a map needs to be
provided that meets the above type constraint. It looks like a bunch of
gobbledygook, but the structure and semantics are rather simple.

A map is nothing more than a array of hashes that define directives to the recto
and verso stored backends. Each directive to a backend can define a simple
string to indicate to use the same key for reading and writing values.
Otherwise, a hash is used where the keys 'read' and 'write' are used. And if
there should be a post or pre process that occurs for a read or write,
respectively, the value for 'read' or 'write' should be an array of the
directive and a coderef to be executed. The coderef will receive the value and
only the value. The return value from the coderef will used post read or pre
write.

The directives are specific to which ever backends are being used. Each has
their own exepctation.

Quick example of a map between two object backends:

    my $map = [
        {
            recto => 
            {
                read => 'get_foo',
                write => 'set_foo',
            }
            verso => 'foo',
        },
        {
            recto =>
            {
                read => 'get_bar',
                write => [ 'set_bar', sub {
                    my $f = shift(@_); $f =~ s/^123//; $f }],
            }
            verso =>
            {
                read => 'bar',
                write => [ 'bar', sub { '123' . shift(@_) } ],
            }
        },
    ];

The recto side uses get_* and set_* methods (or attribute readers/writers),
while the verso side uses a single method or attribute for reading and writing.
Also note that the 'bar' value gets a string appended on the verso side that
needs to be stripped before morphing back.

Each hash in the map array is executed in the order in which it is defined. This
is important if there are order dependant operations.

If a data element only flows one way through the process, do not define a write
element for the given recto/verso, but just a read element.

As an example, suppose the object on one side of the transaction needs a constant
not provided by the incoming data. With read-only elements and a coderef, this
constant can be provided:

    my $map = [
        {
            recto =>
            {
                read => 'get_foo',
                write => 'set_foo',
            },
            verso =>
            {
                read => [ 'some_key', sub { 42 } ],
            }
        }
    ];

Now when going verso -> recto with the data, for the 'foo' attribute on the
object, it will always get the constant. When going recto -> verso, there is no
write defined and so the element is skipped.

Please note that the value of 'some_key' will be discarded due to the post-read
coderef. Setting the key to undef will ensure just the coderef is executed.

=head1 PRIVATE_ATTRIBUTES

=head2 morpher

    is: ro, isa: HashRef, builder: _build_morpher, lazy: 1

This attribute holds the precompiled hash of states used for the
L<Moose::Util::TypeConstraints/match_on_type> matching that takes place inside
the L</morph> method. The keys are the
L<Data::Morph::Role::Backend/input_type>s defined in the backends, while the
values are coderefs that generate an instance for the opposite side of the
morph, read the values from the input, and writes the values into the new
instance.

=head1 PUBLIC_METHODS

=head2 morph

    (Defined)

This method is where the magic happens. The passed in instance is subjected to
L<Moose::Util::TypeConstraints/match_on_type> with the value from L</morpher>
used as the potential execution branches. Whether it is recto -> verso or verso
-> recto, the map is read and a return value produced.

=head1 AUTHOR

Nicholas R. Perez <nperez@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Nicholas R. Perez <nperez@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
