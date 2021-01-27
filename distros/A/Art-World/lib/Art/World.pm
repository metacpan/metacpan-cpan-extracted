use 5.24.1; # Dunno how to make tests pass for v5.22.1 to v5.24.0 so this is how it is
use strict;
use warnings;

package Art::World {

  our $VERSION = '0.18';

  use Zydeco
    authority => 'cpan:SMONFF',
    # Predeclaration of types avoid use of quotes in args types declarations or
    # signatures. See https://gitlab.com/smonff/art-world/-/issues/37
    declare => [
      'Agent',
      'Artwork',
      'Collector',
      'Idea',
      'Place',
      'Theory',
     ],
    version   => $VERSION;

  use feature qw( postderef );
  no warnings qw( experimental::postderef );
  use Carp;
  use utf8;
  use Config::Tiny;
  use DDP;
  use Faker;
  use List::Util qw( max any );
  use Math::Round;

  role Abstraction {
    has discourse ( type => Str );
    has file! ( type => ArrayRef[ Idea ], );
    has idea! ( type => Str, is => rw,  trigger => true );
    has process ( type => ArrayRef );
    has project ( type => Str );
    has time ( type => Int );
    # Here should exist all the possible interractions of Concept entities
    method initiate_process {
      return $self->idea;
    }
    method insert_to_file {}
    # etc.
    method _trigger_idea {
      push $self->file->@*, $self->idea;
    }
  }

  role Active {
    method participate {
      say "That's interesting";
    }
  }

  role Buyer {
    requires money;           # Num $price
    method acquire ( Artwork $art ) {
      $self->money( $self->money - $art->value );
      push $self->collection->@*, $art;
      say "I bought for " . $art->value . " worth of art!" ;
    }

    method sale ( Artwork $art ) {
      $self->money( $self->money + $art->value );
      # TODO DELETE FROM COLLECTION
      # Using a grep filtering on the collection by id seems like a good idea
      # ...
      say "I sold !";
    }
  }

  # Dunno how but the fact of being collected should bump artist reputation
  role Collectionable {
    has owner  ( type => ArrayRef[ Collector ]);
    has value  ( is   => rw );
    has status (
      enum            => ['for_sale', 'sold'],
      # Create a delegated method for each value in the enumeration
      handles         => 1,
      default         => 'for_sale' );
    method belongs_to {
      return $self->owner;
    }
  }

  role Event with Fame {
    has place;
    has datetime;
    # "guests"
    has participants;
  }

  role Exhibit {
    has public;
    has exhibition ( type => ArrayRef );
    has artist ( type => ArrayRef );
    has artwork ( type => ArrayRef );

    method display {
      say "Shoooow";
    }
  }

  role Fame {
    # TODO If an Agent work is  collected, it's reputation should go up
    method bump_fame( Num $gain = $self->config->{ FAME }->{ DEFAULT_BUMP } ) {
      # Dynamic attribute accessor
      my $attribute = $self->isa( 'Art::World::Work' ) ?
          'aura' : 'reputation';
      if ( $self->can( $attribute )) {
        if ( $self->$attribute + $gain >= 0 ) {
          $self->$attribute( $self->$attribute + $gain )
        } else {
          carp 'You tried to update ' . $attribute . ' to a value smaller ' .
              'than zero. Nothing changed.';
        }
        return $self->$attribute;
      } else {
        carp 'No such attribute ' . $attribute .
            ' or we don\'t manage this kind of entity ' . Meta->get_class( $self );
      }
    }
  }

  role Language {
    method speak {}
  }

  role Manager {
    has places ( type => ArrayRef[ Place ] );

    method organize {}

    method influence ( Int $reputation) {
      return $self->config->{ FAME }->{ MANAGER_BUMP } * $reputation;
    }
  }

  role Market {
    #has money;
    has price;
  }

  role Showable {
    #requires exhibition;
    method exhibit {
      say "Show";
    }
  }

  role Space {
    has space;
  }

  role Underground {
    method experiment {
      say "Underground";
    }
  }

  role Writing {
    method write ( Theory $concepts ) {}
  }

  class Art {

    has config (
      is => ro,
      lazy => true,
      default => sub { Config::Tiny->read( './art.conf' )}
    );

    # TODO an implemented project (Work, Exhibition) should inherit of this
    # TODO some stuff should extends this
    abstract class Concept {
      class Idea  with Abstraction { }
      class Theory  with Abstraction { }
    }

    class Opening with Event, Fame {
      has treat;
      has smalltalk;
    }

    class Sex with Event;

    class Playground {

      class Collective;
      class Magazine {
        has reader;
      }

      class Place with Space, Fame {
        class Institution {

          class School {
            has student;
            has teachers;
          }

          class Gallery with Exhibit, Buyer {

            has artwork (  type => ArrayRef );
            has artist (  type => ArrayRef );
            has event ( type => ArrayRef );
            has owner;
            has money;

            # Should be moved to an Opening role
            method serve {
              say "What would you drink?";
            }
          }

          class Museum with Exhibit;

        }

        class Squat with Underground;
        class Workshop;
      }

      class Website;
    }

    class Agent with Active, Fame {
      # Should be required but will be moved to the Crudable area
      has id         ( type => Int );
      has name!      ( type => Str );
      has reputation ( is => rw, type => PositiveOrZeroNum );

      # TODO Should be done during an event
      # TODO In case the networker is a Manager, the reputation bump
      # should be higher
      method networking( ArrayRef $people ) {
        my $highest_reputation = max map { $_-> reputation } $people->@*;
        my $bump = $highest_reputation > 1 ?
          round( $highest_reputation * $self->config->{ FAME }->{ BUMP_COEFFICIENT } / 100) :
          $self->config->{ FAME }->{ DEFAULT_BUMP };
        for my $agent ( $people->@* ) {
          $agent->bump_fame( $bump );
        }

        if ( any { $_->does( 'Art::World::Manager' ) } $people->@* ) {
          my @managers = grep { $_->does( 'Art::World::Manager' )} $people->@*;
          my $highest_influence_manager    =  max map { $self } @managers;
          # Bump all the other persons with the Manager->influence thing
          # but not the Manager with the highest influence otherwise it would
          # increase it's own reputation
          my @all_the_other = grep { $_->id != $highest_influence_manager->id } $people->@*;
          for my $agent ( @all_the_other ) {
            # The influence() methode is only a way of bumping_fame() with a special bumper
            $agent->bump_fame( $highest_influence_manager->influence( $agent->reputation ));
          }
        }
      }

      class Artist {

        has artworks   ( type => ArrayRef );
        has collectors ( type => ArrayRef[Collector], default => sub { [] } );
        has collected  ( type => Bool, default => false, is => rw );
        has status (
          enum => [ 'underground', 'homogenic' ],
          # Create a delegated method for each value in the enumeration
          handles => 1,
          default => sub {
            my $self = shift;
            $self->has_collectors ? 'homogenic' : 'underground' });

        method create {
          say $self->name . " create !";
        }

        method have_idea {
          say $self->name . ' have shitty idea' if true;
        }

        method perform {}

        # factory underground_artist does underground

        method has_collectors {
          if ( scalar $self->collectors->@* > 1 ) {
            $self->collected( true );
          }
        }
      }


      class Collector with Active, Buyer {
        has money! ( type => Num, is => rw );
        has collection (
          type    => ArrayRef[Artwork, 0 ],
          default => sub { [] },
          is      => rw, );
      }

      class Critic with Language, Writing {};

      class Curator with Manager, Writing {
        has exhibition( type  => ArrayRef );
        method select( Artwork $art ) {
          push $self->exhibition->@*, $art;
        }
        method define( Theory $thematic ) { }
        method setup( Place $space ) { }
        method write( Theory $catalog ) { }
      }

      class Director with Manager { }

      class Public {
        method visit {
          say "I visited";
        }
      }
      #use Art::Behavior::Crudable;
      # does Art::Behavior::Crudable;
      # has relations
    }


    class Work extends Concept with Fame {

      has creation_date;
      has creator(
        is   => ro,
        # TODO Should be an ArrayRef of Agents
        type => ArrayRef[ Object ] );

      has title(
        is   => ro,
        type => Str );

      # Same as Agent->reputation
      has aura( is => rw, type => PositiveOrZeroNum );

      class Article

      class Artwork with Showable, Collectionable  {
        has material;
        has size;
      }

      class Book;

      # BUG doesn't have the Work attributes.
      # Multiple inheritance is not fine
      class Exhibition with Event {
        has curator! (
          is   => ro,
          type => ArrayRef[ Curator ] );
      }
    }

    # Looks like the Art::World::Meta toolkit
    class Meta {
      # TODO See also Zydeco's $class object
      method get_class( Object $klass ) {
        return ref $klass;
      }

      method get_set_attributes_only( Object $clazz ) {
        return keys %{ $clazz };
      }

      method get_all_attributes( Object $claxx ) {
        return keys( %{
          'Moo'->_constructor_maker_for(
            $self->get_class( $claxx )
              )->all_attribute_specs
                     });
      }

      method generate_discourse( ArrayRef $buzz = [] ) {
        for ( 0 .. int rand( 3 )) { push $buzz->@*, Faker->new->company_buzzword_type1 };
        return join ' ', $buzz->@*;
      }

      method titlify( Str $token ) {
        return join '', map { ucfirst lc $_ } split /(\s+)/, $token;
      }
    }
  }
}

1;
__END__

=encoding UTF-8

=head1 NAME

Art::World - Agents interactions modeling  🎨

=head1 SYNOPSIS

  use Art::World;

  my $artwork = Art::World->new_artwork(
    creator => [ $artist, $another_artist ]  ,
    value => 100,
    owner => 'smonff' );

=head1 DESCRIPTION

C<Art::World> is an attempt to model and simulate a system describing the
interactions and influences between the various I<agents> of the art world.

More informations about the purposes and aims of this project can be found in
it's L<Art::World::Manual>. Especially, the
L<HISTORY|Art::World::Manual/"HISTORY"> and the
L<OBJECTIVES|Art::World::Manual/"OBJECTIVES"> section could be very handy to
understand how this is an artwork using programming.

=head1 ROLES

=head2 Abstraction

This is were all kind of weird phenomenons happen. See the Manual about how it
works.

=head2 Active

Provide a C<participate> method.

=head2 Buyer

Provide a C<aquire> method requiring some C<money>. All this behavior and
attributes are encapsulated in the C<Buyer> role because there is no such thing
as somebody in the art world that buy but doesn't sale.

=head2 Collectionable

If it's collectionable, it can go to a C<Collector> collection or in a C<Museum>.

=head2 Event

All the necessary attributes and methodes for having fun between Art::world's Agents.

=head2 Exhibit

Role for L<C<Places>|Art::World/"Place"> that display some  L<C<Artworks>|Art::World/"Artwork">.

=head2 Fame

C<Fame> role provide ways to control the aura and reputation that various
C<Agents>, C<Places> or C<Works> have. Cannot be negative.

It has an handy C<bump_fame()> method that self-bump the fame count. It can be
passed a positive C<Num>, a negative C<Num> (so that the fame will get lower)
and even no parameter, in that case it will just add 1.

  my $artist = Art::World->new_artist(
    reputation => 0.42,
    name => 'Questular Rontok'
  );

  say $artist->bump_fame;               # ==>  1.42
  say $artist->bump_fame( 0.0042 );     # ==>  1.4242

If you try to update the fame to a negative value, nothing happens and a nice
warning is displayed.

The fame can be consummed by pretty much everything. A C<Place> or and C<Agent>
have a fame through it's reputation, and an C<Artwork> too through it's
aura.

Classes that consume C<Fame> can have two different kind of attributes for
storing the C<Fame>:

=over 2

=item aura

For C<Works> only.

=item reputation

For C<Agents>, C<Places>, etc.

=back

=head2 Market

It is all about offer and demand. Involve a price but should involve more money
I guess.

=head2 Manager

A role for those who I<take care> of exhibitions and other organizational
matters.

=head2 Showable

Only an object that does the C<Showable> role can be exhibited. An object should
be exhibited only if it reached the C<Showable> stage.

=head1 CLASSES

=head2 Agent

They are the activists of the Art World, previously known as the I<Wildlife>.

  my $agent = Art::World->new_agent( name => $f->person_name );

  $agent->participate;    # ==>  "That's interesting"

A generic entity that can be any activist of the C<Art::World>. Provides all
kind of C<Agent> classes and roles.

The C<Agent> got an a C<networking( $people )> method. When it is passed and
C<ArrayRef> of various implementation classes of C<Agents> (C<Artist>,
C<Curator>, etc.) it bumps the C<reputation> attributes of all of 1/10 of the
C<Agent> with the highest reputation. If this reputation is less than 1, it is
rounded to the C<$self->config->{ FAME }->{ DEFAULT_BUMP }> constant.

The bump coefficient can be adjusted in the configuration through C<{ FAME }->{
BUMP_COEFFICIENT }>.

There is also a special way of bumping fame when C<Manager>s are in a Networking
activity: The C<influence()> method makes possible to apply the special
C<$self->config->{ FAME }->{ MANAGER_BUMP }> constant. Then the C<Agent>s
reputations are bumped by the C<MANAGER_BUMP> value multiplicated by the highest
networking C<Manager> reputation. This is what the C<influence()> method
returns:

  return $self->config->{ FAME }->{ MANAGER_BUMP } * $reputation;

The default values can be edited in C<art.conf>.

=head2 Art

Will be what you decide it to be depending on how you combine all the entities.

=head2 Article

Something in a C<Magazine> of C<Website> about C<Art>, C<Exhibitions>, etc.

=head2 Artist

The artist got a lots of wonderful powers:

=over

=item C<create>

=item C<have_idea> all day long

In the beginning of their carreer they are usually underground, but this can
change in time.

  $artist->is_underground if not $artist->has_collectors;

=back

=head2 Artwork

The base thing producted by artists. Artwork is subclass of
L<C<Work>Art::World::Work> that have a C<Showable> and C<Collectionable> role.

=head2 Book

Where a lot of theory is written by C<Critics>

=head2 Collector

=head2 Collective

They do stuff together. You know, art is not about lonely C<Artists> in their C<Workshop>.

=head2 Concept

C<Concept> is an abstract class that does the C<Abstraction> role.

=head2 Critic

=head2 Curator

A special kind of Agent that I<can> select Artworks, define a thematic, setup
everything in the space and write a catalog.

=head2 Exhibition

An C<Event> that is organised by a C<Curator>.

=head2 Gallery

Just another kind of L<C<Place>|Art::World/"Place">, mostly commercial.

Since it implements the L<C<Buyer>|Art::World/"Buyer"> role, a gallery can both
C<acquire()> and C<sell()>.

=head2 Idea

When some abstractions starts to become something in the mind of an C<Agent>

=head2 Institution

A C<Place> that came out of the C<Underground>.

=head2 Magazine

=head2 Museum

Yet another kind of C<Place>, an institution with a lot of L<C<Artworks>|Art::World/"Artwork"> in the basement.

=head2 Opening

=head2 Place

=head2 Playground

A generic space where C<Art::World> C<Agents> can do all kind of weird things.

=head2 Public

=head2 School

=head2 Sex

=head2 Squat

=head2 Theory

When some abstract concept turns to some said or written stuff.

=head2 Website

=head2 Work

There are not only C<Artworks>. All C<Agent>s produce various kind of work or
help consuming or implementing C<Art>.

=head2 Workshop

A specific kind of L<C<Playground>|Art::World/"Playground"> where you can build things tranquilly.

=head1 META UTILS

A couple of utilities that makes a sort of meta-programming very simple. It is
more like a reminder for my bad memory than something very interesting. Largely
inspired by L<this Perl Monks thread|https://www.perlmonks.org/?node_id=1043195>.

  Art::World::Meta->get_all_attributes( $artist );
  # ==>  ( 'id', 'name', 'reputation', 'artworks', 'collectors', 'collected', 'status' )

=head2 get_class( Object $klass )

Returns the class of the object.

=head2 get_set_attributes_only( Object $clazz )

Returns only attributes that are set for a particular object.

=head2  get_all_attributes( Object $claxx )

Returns even non-set attributes for a particular object.

=head1 AUTHORS

Sébastien Feugère <sebastien@feugere.net>

=head2 Contributors

=over 2

Ezgi Göç

Joseph Balicki

Nadia Boursin-Piraud

Nicolas Herubel

Pierre Aubert

Seb. Hu-Rillettes

Toby Inkster

=back

=head1 ACKNOWLEDGMENT

This project was made possible by the greatness of L<Zydeco|https://zydeco.toby.ink/>.

=head1 COPYRIGHT AND LICENSE

Copyright 2006-2020 Sebastien Feugère

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.
