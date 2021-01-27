[![MetaCPAN Release](https://badge.fury.io/pl/Art-World.svg)](https://metacpan.org/release/Art-World) [![Gitlab pipeline](https://gitlab.com/smonff/art-world/badges/master/pipeline.svg)](https://gitlab.com/smonff/art-world/-/commits/master) [![Gitlab coverage](https://gitlab.com/smonff/art-world/badges/master/coverage.svg)](https://gitlab.com/smonff/art-world/-/commits/master)
# NAME

Art::World - Agents interactions modeling  🎨

# SYNOPSIS

    use Art::World;

    my $artwork = Art::World->new_artwork(
      creator => [ $artist, $another_artist ]  ,
      value => 100,
      owner => 'smonff' );

# DESCRIPTION

`Art::World` is an attempt to model and simulate a system describing the
interactions and influences between the various _agents_ of the art world.

More informations about the purposes and aims of this project can be found in
it's [Art::World::Manual](https://metacpan.org/pod/Art%3A%3AWorld%3A%3AManual). Especially, the
[HISTORY](https://metacpan.org/pod/Art%3A%3AWorld%3A%3AManual#HISTORY) and the
[OBJECTIVES](https://metacpan.org/pod/Art%3A%3AWorld%3A%3AManual#OBJECTIVES) section could be very handy to
understand how this is an artwork using programming.

# ROLES

## Abstraction

This is were all kind of weird phenomenons happen. See the Manual about how it
works.

## Active

Provide a `participate` method.

## Buyer

Provide a `aquire` method requiring some `money`. All this behavior and
attributes are encapsulated in the `Buyer` role because there is no such thing
as somebody in the art world that buy but doesn't sale.

## Collectionable

If it's collectionable, it can go to a `Collector` collection or in a `Museum`.

## Event

All the necessary attributes and methodes for having fun between Art::world's Agents.

## Exhibit

Role for [`Places`](https://metacpan.org/pod/Art%3A%3AWorld#Place) that display some  [`Artworks`](https://metacpan.org/pod/Art%3A%3AWorld#Artwork).

## Fame

`Fame` role provide ways to control the aura and reputation that various
`Agents`, `Places` or `Works` have. Cannot be negative.

It has an handy `bump_fame()` method that self-bump the fame count. It can be
passed a positive `Num`, a negative `Num` (so that the fame will get lower)
and even no parameter, in that case it will just add 1.

    my $artist = Art::World->new_artist(
      reputation => 0.42,
      name => 'Questular Rontok'
    );

    say $artist->bump_fame;               # ==>  1.42
    say $artist->bump_fame( 0.0042 );     # ==>  1.4242

If you try to update the fame to a negative value, nothing happens and a nice
warning is displayed.

The fame can be consummed by pretty much everything. A `Place` or and `Agent`
have a fame through it's reputation, and an `Artwork` too through it's
aura.

Classes that consume `Fame` can have two different kind of attributes for
storing the `Fame`:

- aura

    For `Works` only.

- reputation

    For `Agents`, `Places`, etc.

## Market

It is all about offer and demand. Involve a price but should involve more money
I guess.

## Manager

A role for those who _take care_ of exhibitions and other organizational
matters.

## Showable

Only an object that does the `Showable` role can be exhibited. An object should
be exhibited only if it reached the `Showable` stage.

# CLASSES

## Agent

They are the activists of the Art World, previously known as the _Wildlife_.

    my $agent = Art::World->new_agent( name => $f->person_name );

    $agent->participate;    # ==>  "That's interesting"

A generic entity that can be any activist of the `Art::World`. Provides all
kind of `Agent` classes and roles.

The `Agent` got an a `networking( $people )` method. When it is passed and
`ArrayRef` of various implementation classes of `Agents` (`Artist`,
`Curator`, etc.) it bumps the `reputation` attributes of all of 1/10 of the
`Agent` with the highest reputation. If this reputation is less than 1, it is
rounded to the `$self-`config->{ FAME }->{ DEFAULT\_BUMP }> constant.

The bump coefficient can be adjusted in the configuration through `{ FAME }-`{
BUMP\_COEFFICIENT }>.

There is also a special way of bumping fame when `Manager`s are in a Networking
activity: The `influence()` method makes possible to apply the special
`$self-`config->{ FAME }->{ MANAGER\_BUMP }> constant. Then the `Agent`s
reputations are bumped by the `MANAGER_BUMP` value multiplicated by the highest
networking `Manager` reputation. This is what the `influence()` method
returns:

    return $self->config->{ FAME }->{ MANAGER_BUMP } * $reputation;

The default values can be edited in `art.conf`.

## Art

Will be what you decide it to be depending on how you combine all the entities.

## Article

Something in a `Magazine` of `Website` about `Art`, `Exhibitions`, etc.

## Artist

The artist got a lots of wonderful powers:

- `create`
- `have_idea` all day long

    In the beginning of their carreer they are usually underground, but this can
    change in time.

        $artist->is_underground if not $artist->has_collectors;

## Artwork

The base thing producted by artists. Artwork is subclass of
[`Work`Art::World::Work](https://metacpan.org/pod/WorkArt%3A%3AWorld%3A%3AWork) that have a `Showable` and `Collectionable` role.

## Book

Where a lot of theory is written by `Critics`

## Collector

## Collective

They do stuff together. You know, art is not about lonely `Artists` in their `Workshop`.

## Concept

`Concept` is an abstract class that does the `Abstraction` role.

## Critic

## Curator

A special kind of Agent that _can_ select Artworks, define a thematic, setup
everything in the space and write a catalog.

## Exhibition

An `Event` that is organised by a `Curator`.

## Gallery

Just another kind of [`Place`](https://metacpan.org/pod/Art%3A%3AWorld#Place), mostly commercial.

Since it implements the [`Buyer`](https://metacpan.org/pod/Art%3A%3AWorld#Buyer) role, a gallery can both
`acquire()` and `sell()`.

## Idea

When some abstractions starts to become something in the mind of an `Agent`

## Institution

A `Place` that came out of the `Underground`.

## Magazine

## Museum

Yet another kind of `Place`, an institution with a lot of [`Artworks`](https://metacpan.org/pod/Art%3A%3AWorld#Artwork) in the basement.

## Opening

## Place

## Playground

A generic space where `Art::World` `Agents` can do all kind of weird things.

## Public

## School

## Sex

## Squat

## Theory

When some abstract concept turns to some said or written stuff.

## Website

## Work

There are not only `Artworks`. All `Agent`s produce various kind of work or
help consuming or implementing `Art`.

## Workshop

A specific kind of [`Playground`](https://metacpan.org/pod/Art%3A%3AWorld#Playground) where you can build things tranquilly.

# META UTILS

A couple of utilities that makes a sort of meta-programming very simple. It is
more like a reminder for my bad memory than something very interesting. Largely
inspired by [this Perl Monks thread](https://www.perlmonks.org/?node_id=1043195).

    Art::World::Meta->get_all_attributes( $artist );
    # ==>  ( 'id', 'name', 'reputation', 'artworks', 'collectors', 'collected', 'status' )

## get\_class( Object $klass )

Returns the class of the object.

## get\_set\_attributes\_only( Object $clazz )

Returns only attributes that are set for a particular object.

## get\_all\_attributes( Object $claxx )

Returns even non-set attributes for a particular object.

# AUTHORS

Sébastien Feugère <sebastien@feugere.net>

## Contributors

> Ezgi Göç
>
> Joseph Balicki
>
> Nadia Boursin-Piraud
>
> Nicolas Herubel
>
> Pierre Aubert
>
> Seb. Hu-Rillettes
>
> Toby Inkster

# ACKNOWLEDGMENT

This project was made possible by the greatness of [Zydeco](https://zydeco.toby.ink/).

# COPYRIGHT AND LICENSE

Copyright 2006-2020 Sebastien Feugère

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.
