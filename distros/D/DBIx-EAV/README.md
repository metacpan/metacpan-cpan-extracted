[![Build Status](https://travis-ci.org/cafe01/dbix-eav.svg?branch=master)](https://travis-ci.org/cafe01/dbix-eav) [![Coverage Status](https://img.shields.io/coveralls/cafe01/dbix-eav/master.svg?style=flat)](https://coveralls.io/r/cafe01/dbix-eav?branch=master)
# NAME

DBIx::EAV - Entity-Attribute-Value data modeling (aka 'open schema') for Perl

# SYNOPSIS

    #!/usr/bin/env perl
    use strict;
    use warnings;
    use DBIx::EAV;

    # connect to the database
    my $eav = DBIx::EAV->connect("dbi:SQLite:database=:memory:");

    # or
    # $eav = DBIx::EAV->new( dbh => $dbh, %constructor_params );

    # create eav tables
    $eav->schema->deploy;

    # register entities
    $eav->declare_entities({
        Artist => {
            many_to_many => 'CD',
            has_many     => 'Review',
            attributes   => [qw/ name:varchar description:text rating:int birth_date:datetime /]
        },

        CD => {
            has_many     => ['Track', 'Review'],
            has_one      => ['CoverImage'],
            attributes   => [qw/ title description:text rating:int /]
        },

        Track => {
            attributes   => [qw/ title description:text duration:int /]
        },

        CoverImage => {
            attributes   => [qw/ url /]
        },

        Review => {
            attributes => [qw/ content:text views:int likes:int dislikes:int /]
        },
    });


    # insert data (and possibly related data)
    my $bob = $eav->resultset('Artist')->insert({
        name => 'Robert',
        description => '...',
        cds => [
            { title => 'CD1', rating => 5 },
            { title => 'CD2', rating => 6 },
            { title => 'CD3', rating => 8 },
            { title => 'CD4', rating => 9 },
        ]
     });

    # get attributes
    print $bob->get('name'); # Robert

    # update name
    $bob->update({ name => 'Bob' });

    # add more cds
    $bob->add_related('cds', { title => 'CD5', rating => 7 });

    # get Bob's cds via auto-generated 'cds' relationship
    print "\nAll Bob CDs:\n";
    printf " - %s (rating %d)\n", $_->get('title'), $_->get('rating')
        foreach $bob->get('cds');

    print "\nBest Bob CDs:\n";
    printf " - %s (rating %d)\n", $_->get('title'), $_->get('rating')
        foreach $bob->get('cds', { rating => { '>' => 7 } });


    # ResultSets ...


    # retrieve Bob from database
    $bob = $eav->resultset('Artist')->find({ name => 'Bob' });

    # retrieve Bob's cds directly from CD resultset
    # note the use of 'artists' relationship automaticaly created
    # from the "Artist many_to_many CD" declaration
    my @cds = $eav->resultset('CD')->search({ artists => $bob });

    # same as above
    @cds = $bob->get('cds');

    # or traverse the cds using the resultset cursor
    my $cds_rs = $bob->get('cds');

    while (my $cd = $cds_rs->next) {
        print $cd->get('title');
    }

    # delete all cds
    $eav->resultset('CD')->delete;

    # delete all cds and related data (i.e. tracks)
    $eav->resultset('CD')->delete_all;

# DESCRIPTION

An implementation of Entity-Attribute-Value data modeling with support for
entity relationships, inheritance, custom classes and multi-tenancy.
See [DBIx::EAV::Manual](https://metacpan.org/pod/DBIx::EAV::Manual).

# ALPHA STAGE

This project is in its infancy, and the main purpose of this stage is to let
other developers try it, and help identify any major design flaw before we can
stabilize the API. One exception is the ResultSet whose API (and docs :\]) I've
borrowed from [DBIx::Class](https://metacpan.org/pod/DBIx::Class), so its (API is) already stable.

# CONSTRUCTORS

## new

- Arguments: %params

Valid `%params` keys:

- dbh **(required)**

    Existing [DBI](https://metacpan.org/pod/DBI) database handle. See ["connect"](#connect).

- schema\_config

    Hashref of options used to instantiate our [DBIx::EAV::Schema](https://metacpan.org/pod/DBIx::EAV::Schema).
    See ["CONSTRUCTOR OPTIONS" in DBIx::EAV::Schema](https://metacpan.org/pod/DBIx::EAV::Schema#CONSTRUCTOR-OPTIONS).

- entity\_namespaces

    Arrayref of namespaces to look for custom [entity](https://metacpan.org/pod/DBIx::EAV::Entity) classes.

        # mimic DBIx::Class
        entity_namespaces => ['MyApp::Schema::Result']

    Class names are created by appending the entity type name to each namespace in
    the list. The first existing class is used.

    Custom entity classes are useful not only provide custom business logic, but
    also to define your entities, like DBIx::Class result classes.
    See ["CUSTOM CLASS" in DBIx::EAV::Entity](https://metacpan.org/pod/DBIx::EAV::Entity#CUSTOM-CLASS).

- resultset\_namespaces

    Arrayref of namespaces to look for custom resultset classes.

        # mimic DBIx::Class
        resultset_namespaces => ['MyApp::Schema::ResultSet']

    Class names are created by appending the entity type name to each namespace in
    the list. The first existing class is used.

## connect

- Arguments: $dsn, $user, $pass, $attrs, \\%constructor\_params

Connects to the database via `DBI->connect($dsn, $user, $pass, $attrs)`
then returns a new instance via [new(\\%constructor\_params)](#new).

# METHODS

## declare\_entities

- Arguments: \\%schema
- Return value: none

Declares entity types specified in \\%schema, where each key is the name of the
[type](https://metacpan.org/pod/DBIx::EAV::EntityType) and the value is a hashref describing its
attributes and relationships. Fully described in
["ENTITY DEFINITION" in DBIx::EAV::EntityType](https://metacpan.org/pod/DBIx::EAV::EntityType#ENTITY-DEFINITION).

You must declare your entities every time a new instance of DBIx::EAV is created.
This method stores the entities schema, and calculates a signature for each.
Next time type() is called the relevant entity type will get registerd or
updated (if the signature changed)

## resultset

- Arguments: $name
- Return value: [$rs](https://metacpan.org/pod/DBIx::EAV::ResultSet)

Returns a new [resultset](https://metacpan.org/pod/DBIx::EAV::ResultSet) instance for
[type](https://metacpan.org/pod/DBIx::EAV::EntityType) `$name`.

    my $rs = $eav->resultset('Artist');

## type

- Arguments: $name

Returns the [DBIx::EAV::EntityType](https://metacpan.org/pod/DBIx::EAV::EntityType) instance for type `$name`. If the type
instance is not already installed in this DBIx::EAV instance, we try to load
the type definition from the database. Dies if type is not registered.

    my $types = $eav->type('Artist');

See ["INSTALLED VS REGISTERED TYPES"](#installed-vs-registered-types).

## has\_type

- Arguments: $name

Returns true if [entity type](https://metacpan.org/pod/DBIx::EAV::EntityType) `$name` is installed.

## schema

Returns the [DBIx::EAV::Schema](https://metacpan.org/pod/DBIx::EAV::Schema) instance representing the physical database tables.

## table

Shortcut for `->schema->table`.

## dbh\_do

- Arguments: $stmt, \\@bind?
- Return Values: ($rv, $sth)

    Prepares `$stmt` and executes with the optional `\@bind` values. Returns the
    return value from execute `$rv` and the actual statement handle `$sth` object.

    Set environment variable `DBIX_EAV_TRACE` to 1 to get statements printed to
    `STDERR`.

# INSTALLED VS REGISTERED TYPES

# LICENSE

Copyright (C) Carlos Fernando Avila Gratz.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Carlos Fernando Avila Gratz <cafe@kreato.com.br>
