# NAME

DBIx::Class::InflateColumn::JSON2Object - convert JSON columns to Perl objects

# VERSION

version 0.907

# SYNOPSIS

    # In a DBIx::Class Result
    package MyApp::Schema::Result::SomeTable;
    ... lots of DBIx::Class code...

    use DBIx::Class::InflateColumn::JSON2Object;
    DBIx::Class::InflateColumn::JSON2Object->fixed_class({
        column=>'data',      # a column storing JSON
        class=>'MyApp::SomeClass',
    });

    # later, in some code far, far away...
    my $row = $schema->resultset('SomeTable')->find(42);
    my $obj = $row->data;
    $obj->foo; # $obj ISA MyApp::SomeClass

    # store a hash as JSON after "validating" it through MyApp::SomeClass
    $schema->resultset('SomeTable')->create({
        data => {
            foo=>'bar',
        };
    })

    # you can also use it to just deflate/inflate JSON to a Perl hash
    DBIx::Class::InflateColumn::JSON2Object->no_class({
        column=>'args',
    });

    # or have a complex set of objects
    DBIx::Class::InflateColumn::JSON2Object->class_in_column({
        data_column  => 'object',        # some JSON
        class_column => 'type',          # here we store the name of the object
        namespace    => 'MyApp::Object', # the namespace of the objects
    });

    # or store a list of objects (of one class!) into an array
    DBIx::Class::InflateColumn::JSON2Object->array_of_class({
        column=>'data',      # a column storing a JSON list
        class=>'MyApp::SomeElementClass',
    });

# DESCRIPTION

TODO: short overview

## Booleans, JSON, oh my...

TODO: describe problem and the (hacky/crappy?) solution

## METHODS

Please note that you can pass more than one HASHREF per method to
install several inflator/deflators at once.

### no\_class

Install a JSON inflator/deflator for each column.

    DBIx::Class::InflateColumn::JSON2Object->no_class({
        column=>'args'
    });

You can pass a Perl datastructure to the row and it will be stored as JSON:

    $resultset->create( {
        id   => 123,
        args => {
          some => 'data',
          more => [1,1,2,3,5,8]
        }
    });
    # will be stored as '{"some":"data","more":[1,1,2,3,5,8]}'

You can also access the data directly as a Perl hash:

    my $row = $resultset->find(123);
    $row->args->{some};     # 'data'
    $row->args->{more}[5];  # 8

### fixed\_class

If plain JSON is to wobbly for you, you can define Moose objects and
have them serialized to JSON. Not only can you now add some custom
methods to the objects, but you can (ab)use the object initalisation
and all features Moose provides to define your objects.

    # Define a class
    package YourApp::Sweets;
    use Moose;
    with 'DBIx::Class::InflateColumn::JSON2Object::Role::Storable';

    has 'name'  => ( is=>'ro', isa=>'Str');
    has 'amount => ( is=>'ro', isa=>'Int');

    __PACKAGE__->meta->make_immutable;


    # In your Result class, map the class to a column
    package YourApp::Schema::Result::Thing;
    __PACKAGE__->add_columns(
      "sweets",
      { data_type => "jsonb", is_nullable => 1 }
    );
    use DBIx::Class::InflateColumn::JSON2Object;

    DBIx::Class::InflateColumn::JSON2Object->fixed_class({
        column=>'sweets',
        class=>'YourApp::Sweets',
    });

Now you can pass a plain hash, a raw JSON string, or an initiated
object to the row, and always get back the object:

    my $thing = $schema->resultset('Thing')->create({
      sweets => {
          name   => 'Manner Schnitten',
          amount => 10,
      }
    });
    ref($thing->sweets); # 'YourApp::Sweets'

### class\_in\_column

Sometimes you have a set of similar objects you want to store. TODO: explain oe1.article.paragraph

    TODO ->class_in_column(..)

You can pass an object to the row and the infered type will be stored together with the JSON-payload:

    TODO

To get back the object:

    TODO

### array\_in\_class

Sometimes you want to store a list of objects without packing them into a "Set"-Object. This only works if all objects are of the same class, as we do not want to include the class name inside the object (c.f. MooseX::Storage, KiokuDB).

    TODO ->array_in_class(..)

Just pass an arrayref of object to the row and it will be stored as JSON:

    TODO

And you get back the initated list of objects:

    TODO

# THANKS

- Parts of this code were orginally developed for [validad.com](https://www.validad.com/) and released as Open Source.
- [Maroš Kollár](https://metacpan.org/author/MAROS) wrote the prototype of `class_in_column`, orginally developed for [http://oe1.orf.at](http://oe1.orf.at).

# AUTHOR

Thomas Klausner <domm@plix.at>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2017 - 2021 by Thomas Klausner.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
