use v5.16;
use strict;
use warnings;
use utf8;

package Art::World {

  our $VERSION = '0.17';

  use Zydeco version => $VERSION, authority => 'cpan:SMONFF';

  role Active {
    method participate {
      say "That's interesting";
    }
  }


  role Buyer {
    requires money;
    method acquire ( Num $price ) {
      say "I bought !";
    }

    method sale ( Num $price ) {
      say "I sold !";
    }
  }


  role Collectionable {
    # Should be an object of type Agent
    has owner;
    has value ( is => rw );
    has status (
      enum     => ['for_sale', 'sold'],
      handles  => 1,
      default  => 'for_sale'
    );
    method belongs_to {
      return $self->owner;
    }
  }

  role Concept {
    # Here should exist all the possible interractions of Concept entities
    method idea_of_project {}
    method idea_file {}
    # etc.
  }

  role Space {
    has space;
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

  role Underground {
    method experiment {
      say "Underground";
    }
  }

  class Abstraction with Concept {
    has idea!, process, file!, discourse, time, project;
  }

  class Event {
    has place;
    has datetime;
    # "guests"
    has participants;
    class Opening {
      has treat;
      has smalltalk;
    };
    class Sex;
  }

  class Playground {

    class Collective;
    class Magazine {
      has reader;
    };


    class Place with Space {
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

  class Wildlife {

    class Agent with Active {
      # Should be required but will be moved to the Crudable area
      has id         ( type => Int );
      has name!       ( type => Str );
      has reputation ( type => Int );

      class Artist {

        has artworks   ( type => ArrayRef );
        has collectors ( type => ArrayRef, default => sub { [] } );
        has collected  ( type => Bool, default => false, is => rw );
        has status (
          enum => [ 'underground', 'homogenic' ],
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

        # factory underground_artist does underground

        method has_collectors {
          if ( scalar @{ $self->collectors }  > 1 ) {
            $self->collected( true );
          }
        }

        # method new ($id, $name, @artworks, @collectors) {
        #     self.bless(:$id, :$name, :@artworks, :@collectors);
        # }
      }


      class Collector with Active, Buyer {
        has money! ( type => Num );
        # Actually an ArrayRef of Artworks
        has collection (
          type    => ArrayRef[Any, 0, 100],
          default => sub { [] }
        ) ;
      }

      class Critic;

      class Curator;

      class Public {
        method visit {
          say "I visited";
        }
      }
    }


    #use Art::Behavior::Crudable;
    # does Art::Behavior::Crudable;
    # has relations

  }

  class Work {

    has creation_date;
    has creator (
      is => ro,
      # ArrayRed of Artists
      type => ArrayRef[ Object ]
    );

    class Article;

    class Artwork with Showable, Collectionable  {

      has creation_date;
      has creator (
        is => ro,
        # Should be ArrayRed of Artists
        type => ArrayRef[ Object ]
      );
      has material;
      has size;
    }

    class Book;

    class Exhibition;
  }
}

1;
__END__

=encoding UTF-8

=head1 NAME

Art::World - Agents interactions modeling  🎨

=head1 SYNOPSIS

  use Art::World;

  my $artwork = Art->new_artwork(
    creator => [ $artist, $another_artist ]  ,
    value => 100,
    owner => $f->person_name );

=head1 DESCRIPTION

C<Art::World> is an attempt to model and simulate a system describing the
interactions and influences between the various I<agents> of the art world.

More informations about the purposes and aims of this project can be found in
it's L<manual|Art::World::Manual>. Especially, the
L<history|Art::World::Manual/"HISTORY"> and the
L<objectives|Art::World::Manual/"OBJECTIVES"> section could be very handy to
understand how this is an artwork using programming.

=head1 ROLES

=head2 Active

Provide a C<participate> method.

=head2 Buyer

Provide a C<aquire> method requiring some C<money>. All this behavior and
attributes are encapsulated in the C<Buyer> role because there is no such thing
as somebody in the art world that buy but doesn't sale.

=head2 Collectionable

If it's collectionable, it can go to a C<Collector> collection or in a C<Museum>.

=head2 Concept

=head2 Exhibit

Role for L<C<Places>|Art::World/"Place"> that display some  L<C<Artworks>|Art::World/"Artwork">.

=head2 Market

It is all about offer and demand. Involve a price but should involve more money
I guess.

=head2 Showable

Only an object that does the C<Showable> role can be exhibited. An object should
be exhibited only if it reached the C<Showable> stage.

=head1 CLASSES

=head2 Agent

They are the activists of the Art World, well known as the I<wildlife>.

  my $agent = Art::World->new_agent( name => $f->person_name );

  $agent->participate;    # ==>  "That's interesting"

A generic entity that can be any activist of the C<Art::World>. Provides all
kind of C<Agent> classes and roles.

=head2 Art

Will be what you decide it to be depending on how you combine all the entities.

=head2 Article

Something in a C<Magazine> of C<Website> about C<Art>, C<Exhibitions>, etc.

=head2 Artwork

The base thing producted by artists. Artwork is subclass of
L<C<Work>Art::World::Work> that have a C<Showable> and C<Collectionable> role.


=head2 Artist

The artist got a lots of wonderful powers:

=over

=item C<create>

=item C<have_idea> all day long

In the beginning of their carreer they are usually underground, but this can
change in time.

  $artist->is_underground if not $artist->has_collectors;

=back

=head2 Book

Where a lot of theory is written by C<Critics>

=head2 Collector

=head2 Collective

They do stuff together. You know, art is not about lonely C<Artists> in their C<Workshop>.

=head2 Critic

=head2 Curator

=head2 Event

=head2 Exhibition

=head2 Gallery

Just another kind of L<C<Place>|Art::World/"Place">, mostly commercial.

Since it implements the L<C<Buyer>|Art::World/"Buyer"> role, a gallery can both
C<acquire()> and C<sell()>.

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

=head2 Website

=head2 Work

There are not only C<Artworks>. All C<Agent>s produce various kind of work or
help consuming or implementing C<Art>.

=head2 Workshop

A specific kind of L<C<Playground>|Art::World/"Playground"> where you can build things tranquilly.

=head1 AUTHOR

Seb. Hu-Rillettes <shr@balik.network>

=head1 CONTRIBUTORS

Sébastien Feugère <sebastien@feugere.net>

=head1 COPYRIGHT AND LICENSE

Copyright 2006-2020 Seb. Hu-Rillettes

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.
