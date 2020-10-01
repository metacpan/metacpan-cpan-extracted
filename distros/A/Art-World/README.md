[![MetaCPAN Release](https://badge.fury.io/pl/Art-World.svg)](https://metacpan.org/release/Art-World) [![Gitlab pipeline](https://gitlab.com/smonff/art-world/badges/master/pipeline.svg)](https://gitlab.com/smonff/art-world/-/commits/master) [![Gitlab coverage](https://gitlab.com/smonff/art-world/badges/master/coverage.svg)](https://gitlab.com/smonff/art-world/-/commits/master)
# NAME

Art::World - Agents interactions modeling  🎨

# SYNOPSIS

    use Art::World;

    my $artwork = Art->new_artwork(
      creator => [ $artist, $another_artist ]  ,
      value => 100,
      owner => $f->person_name );

# DESCRIPTION

`Art::World` is an attempt to model and simulate a system describing the
interactions and influences between the various _agents_ of the art world.

More informations about the purposes and aims of this project can be found in
it's [manual](https://metacpan.org/pod/Art%3A%3AWorld%3A%3AManual). Especially, the
[history](https://metacpan.org/pod/Art%3A%3AWorld%3A%3AManual#HISTORY) and the
[objectives](https://metacpan.org/pod/Art%3A%3AWorld%3A%3AManual#OBJECTIVES) section could be very handy to
understand how this is an artwork using programming.

# ROLES

## Active

Provide a `participate` method.

## Buyer

Provide a `aquire` method requiring some `money`. All this behavior and
attributes are encapsulated in the `Buyer` role because there is no such thing
as somebody in the art world that buy but doesn't sale.

## Collectionable

If it's collectionable, it can go to a `Collector` collection or in a `Museum`.

## Concept

## Exhibit

Role for [`Places`](https://metacpan.org/pod/Art%3A%3AWorld#Place) that display some  [`Artworks`](https://metacpan.org/pod/Art%3A%3AWorld#Artwork).

## Market

It is all about offer and demand. Involve a price but should involve more money
I guess.

## Showable

Only an object that does the `Showable` role can be exhibited. An object should
be exhibited only if it reached the `Showable` stage.

# CLASSES

## Agent

They are the activists of the Art World, well known as the _wildlife_.

    my $agent = Art::World->new_agent( name => $f->person_name );

    $agent->participate;    # ==>  "That's interesting"

A generic entity that can be any activist of the `Art::World`. Provides all
kind of `Agent` classes and roles.

## Art

Will be what you decide it to be depending on how you combine all the entities.

## Article

Something in a `Magazine` of `Website` about `Art`, `Exhibitions`, etc.

## Artwork

The base thing producted by artists. Artwork is subclass of
[`Work`Art::World::Work](https://metacpan.org/pod/WorkArt%3A%3AWorld%3A%3AWork) that have a `Showable` and `Collectionable` role.

## Artist

The artist got a lots of wonderful powers:

- `create`
- `have_idea` all day long

    In the beginning of their carreer they are usually underground, but this can
    change in time.

        $artist->is_underground if not $artist->has_collectors;

## Book

Where a lot of theory is written by `Critics`

## Collector

## Collective

They do stuff together. You know, art is not about lonely `Artists` in their `Workshop`.

## Critic

## Curator

## Event

## Exhibition

## Gallery

Just another kind of [`Place`](https://metacpan.org/pod/Art%3A%3AWorld#Place), mostly commercial.

Since it implements the [`Buyer`](https://metacpan.org/pod/Art%3A%3AWorld#Buyer) role, a gallery can both
`acquire()` and `sell()`.

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

## Website

## Work

There are not only `Artworks`. All `Agent`s produce various kind of work or
help consuming or implementing `Art`.

## Workshop

A specific kind of [`Playground`](https://metacpan.org/pod/Art%3A%3AWorld#Playground) where you can build things tranquilly.

# AUTHOR

Seb. Hu-Rillettes <shr@balik.network>

# CONTRIBUTORS

Sébastien Feugère <sebastien@feugere.net>

# COPYRIGHT AND LICENSE

Copyright 2006-2020 Seb. Hu-Rillettes

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.
