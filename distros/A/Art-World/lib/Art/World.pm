use 5.20.0;
use strict;
use warnings;

package Art::World {

  our $VERSION = '0.19';

  use Zydeco
    authority => 'cpan:SMONFF',
    # Predeclaration of types avoid use of quotes in args types declarations or
    # signatures. See https://codeberg.org/smonff/art-world/issues/37
    declare => [
      'Agent',
      'Artwork',
      'Collector',
      'Event',
      'Idea',
      'Place',
      'Theory',
     ],
    version   => $VERSION;

  use feature qw( postderef );
  no warnings qw( experimental::postderef );
  use Carp qw( carp cluck );
  use utf8;
  use Config::Tiny;
  use List::Util qw( max any );
  use Math::Round;
  use Try::Tiny;

  role Abstraction {
    has discourse ( type => Str );
    # TODO could be a table in the database
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

    requires money;

    multi method acquire ( Artwork $art ) {
      $self->pay( $art, $self );
      $art->change_owner( $self );
    }
  }

  # Dunno how but the fact of being collected should bump artist reputation
  role Collectionable {
    has owner (
      lazy    => true,
      is      => rw,
      clearer => true,
      writer  => 'set_owner',
      type    => ArrayRef[ Agent ]) = $self->creator;
    has value  ( is   => rw );
    has status (
      enum            => ['for_sale', 'sold'],
      # Create a delegated method for each value in the enumeration
      handles         => 1,
      default         => 'for_sale' );

    method $remove_from_seller_collection {
      my $meta = Art::World::Util->new_meta;
      # Removal of the to-be-sold Artwork in seller collection
      for my $owner ( $self->owner->@* ) {
        # Artists don't have a collection
        # Or maybe they can... So we should add a specific case
        if (  $meta->get_class( $owner ) !~ '^Art::World::Artist$' ) {
          while ( my ( $i, $art ) = each( $owner->collection->@* )) {
            # Removing if a matching artwork is found
            # Should be removed by id, but we don't manage that yet
            if ( $art->title =~ $self->title ) {
              # Wish I would use List::UtilsBy extract_by() for this
              splice $owner->collection->@*, $i, 1;
            }
          }
        }
      }
    }

    multi method change_owner ( Collector $buyer ) {

      # From seller collection
      $self->$remove_from_seller_collection;

      $self->clear_owner;
      $self->set_owner([ $buyer ]);
      push $buyer->collection->@*, $self;
      # TODO guess it should bump some people reputation and artwork aura now
    }

    multi method change_owner ( Coinvestor $buyers ) {

      # From Collector point of view
      $self->$remove_from_seller_collection;

      # From Artwork point of view
      $self->clear_owner;
      $self->set_owner( $buyers->members );
      push $buyers->collection->@*, $self;
      # TODO guess it should bump some people reputation and artwork aura now
    }
  }

  role Collective {

    has members! ( type => ArrayRef[ Agent ] );

    multi method acquire ( Artwork *art, Collective *collective ) {
      for my $member ( $arg->collective->members->@* ) {
        $member->pay( $arg->art, $arg->collective );
      }
      $arg->art->change_owner( $arg->collective );
    }
  }

  role Crud {
    has dbh! ( type => InstanceOf[ 'Art::World::Model' ], builder => true, lazy => true );
    has db!  ( type => HashRef[ Str ], builder => true, lazy => true );

    method insert ( Str $table, HashRef $attributes ) {
      # TODO IT MUST BE TESTED
      unless ( $self->does( 'Art::World::Unserializable' )) {
        try {
          my $row = $self->dbh->insert( ucfirst lc $table, $attributes);
        } catch {
          cluck 'You tried to insert to ' . $table . ' but this table doesn\'t exist';
        }
      }
    }

    method _build_dbh {
      use DBI;
      use Teng;
      use Teng::Schema::Loader;
      my $dbh = Teng::Schema::Loader->load(
        dbh       => DBI->connect(
          'dbi:' . $self->db->{ kind } .
          ':dbname=' . $self->db->{ name },
          '', '' ),
        namespace => __PACKAGE__ . '::Model'
       );
      return $dbh;
    }

    method _build_db {
      return {
        name => $self->config->{ DB }->{ NAME },
        kind => $self->config->{ DB }->{ KIND },
       };
    }
  }

  role Event {
    has place ( type => Place );
    has datetime ( type => InstanceOf['Time::Moment'] );
    # "guests"
    has participant ( type => ArrayRef[ Agent ] );
    has title ( type => Str, is => ro );
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

  # TODO If an Agent work is  collected, it's reputation should go up
  role Fame {
    # Private
    method $update_fame( Num $difference ) {
      # Dynamic attribute accessor
      my $attribute = $self->isa( 'Art::World::Work' ) ?
        'aura' : 'reputation';
      if ( $self->can( $attribute )) {
        if ( $self->$attribute + $difference >= 0 ) {
          $self->$attribute( $self->$attribute + $difference )
        } else {
          carp 'You tried to update ' . $attribute . ' to a value smaller ' .
            'than zero. Nothing changed.';
        }
        return $self->$attribute;
      } else {
        require Art::World::Util;
        carp 'No such attribute ' . $attribute .
          ' or we don\'t manage this kind of entity ' . Art::World::Util->new_meta->get_class( $self );
      }
    }

    multi method bump_fame( PositiveNum $gain ) {
      $self->$update_fame( $gain );
    }

    multi method bump_fame( NegativeNum $loss ) {
      $self->$update_fame( $loss )
    }

    multi method bump_fame {
      $self->$update_fame( $self->config->{ FAME }->{ DEFAULT_BUMP });
    }
  }

  role Identity {
    has id         ( type => Int );
    has name       ( type => Str );
  }

  # From the documentation
  #
  # A `Place` must `invite()` all kind of `Agents` that produce `Work` or other
  # kind of valuable social interactions. Depending of the total `reputation` of
  # the `Place` it will determine it's `underground` status: when going out of
  # the `underground`, it will become an institution.
  #
  role Invitation {
    # In case a group of Agents are invited, for an Event like a performance, a
    # concert
    multi method invite ( ArrayRef[ Agent ] *people,  Event *event  ) {
    }
  }

  # The idea here is producing discourse about art
  role Language {
    method speak ( Str $paroles) {
      say $paroles;
      # TODO Could write to a log file
    }
  }

  role Manager {
    has places ( type => ArrayRef[ Place ] );

    method organize {}

    method influence ( Int $reputation) {
      return $self->config->{ FAME }->{ MANAGER_BUMP } * $reputation;
    }
  }

  role Market {

    has money! ( type => Num, is => rw, default => 0 );

    # Can be a personal collector or a Coinvestor
    method pay ( Artwork $piece, Collector $collector  ) {
      # Divide what must be paid by each buyer
      my $must_give = Art::World::Util
        ->new_meta
        ->get_class( $collector ) !~ /^Art::World::Coinvestor$/ ?
          $piece->value :
          $piece->value / scalar $collector->members->@*;

      # The money must be divided in equal between all owners
      my $part =  $must_give / scalar $piece->owner->@*;
      # Seller(s) got their money given
      map { $_->money( $_->money + $part ) } $piece->owner->@*;
      # Buyer gives the money
      $self->money( $self->money - $must_give );
    }
  }

  role Showable {
    #requires exhibition;
    method exhibit {
      say "Show";
    }
  }

  role Space {
    # Like a small space or a large space
    # Could limit the number of person coming during an event for example
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
      class Idea  with Abstraction {
        method express {
          say $self->discourse if $self->discourse;
        }
      }
      class Theory  with Abstraction { }
    }

    class Opening with Event, Fame {
      has treat ( type => ArrayRef[ Str ]);
      has smalltalk;

      # TODO must take as parameter what is served
      method serve {
        return $self->treat->@*;
      }
    }

    # TODO Guess this is more like an Agent method or role
    class Sex with Event;

    class Playground with Crud, Identity {

      class Magazine {

        has reader;
        has writer ( type => ArrayRef[ Agent ] );

        method publish {};
      }

      class Place with Fame, Invitation, Space {

        # Like, dunno, a city ? Could be in a Geo role I guess
        has location ( type => Str );

        class Institution with Market {
          class Gallery with Exhibit, Buyer {
            has artwork ( type => ArrayRef );
            has artist ( type => ArrayRef );
            has event ( type => ArrayRef );
            has owner;
          }

          class Museum with Exhibit, Buyer;

          class School {
            # TODO much underground
            has student  ( type => ArrayRef[ Agent ]);
            # TODO Should enforce a minimum reputation
            has teachers ( type => ArrayRef[ Agent ]);;
          }
        }

        class Squat with Underground;
        class Workshop;

      }

      class Website;

    }

    class Agent with Active, Crud, Fame, Identity {

      has relationship;
      has reputation ( is => rw, type => PositiveOrZeroNum ) = 0;
      # TODO it would improve a lot the networking

      # TODO Should be done during an event
      # TODO In case the networker is a Manager, the reputation bump
      # should be higher
      method networking( ArrayRef $people ) {

        $self->dbh;
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

      class Artist with Market {

        has artworks   ( type => ArrayRef );
        has collectors ( type => ArrayRef[ Collector ], default => sub { [] });
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

        # TODO Zydeco already provides a shortcut for this through predicates
        method has_collectors {
          if ( scalar $self->collectors->@* > 1 ) {
            $self->collected( true );
          }
        }
      }

      class Collector with Active, Buyer, Market {
        has collection (
          type    => ArrayRef[ Artwork, 0 ],
          default => sub { [] },
          is      => rw, );
        class Coinvestor with Collective {
          # TODO the Coinvestor money should be automatically build from all the
          # investors
        }
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

      class Director with Manager;

      class Public with Unserializable? {
        # TODO could have an ArrayRef of Agents attribute
        method visit( ConsumerOf[ Event ] $event ) {
          say "I visited " . $event->title;
        }
      }
    }


    class Work extends Concept with Fame, Identity {

      has creation_date;
      has creator!(
        is   => ro,
        type => ArrayRef[ Agent ] );

      # TODO it conflicts a bit with the Identity's name attribute
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
  }
}

1;
__END__

=encoding UTF-8

=head1 NAME

Art::World - Modeling of creative processes

=head1 SYNOPSIS

  use Art::World;

  my $artwork = Art::World->new_artwork(
    creator => [ $artist, $another_artist ]  ,
    owner   => 'smonff'
    title   => 'Corrupted art institutions likes critical art'
    value   => 100, );

  my $museum = Art::World->new_museum(
    money => 1000,
    name  => 'Contemporary Museum of Art::World'
  );

  $museum->acquire( $artwork );

=head1 DESCRIPTION

C<Art::World> is an attempt to model and simulate a system describing the
interactions and influences between the various I<agents> of the art world.

It tries to draw a schematization of the interactions between art, institutions,
influences and unexpected parameters during the social processes of artistic
creation.

More informations about the purposes and aims of this project can be found in
it's L<Art::World::Manual>. Especially, the
L<HISTORY|Art::World::Manual/"HISTORY"> and the
L<OBJECTIVES|Art::World::Manual/"OBJECTIVES"> section could be very handy to
understand how this is an artwork using programming.

=head1 MOTIVATIONS

This project is a self-teaching experiment around the modern Perl
object-oriented programming toolkit. In late 2020, I read a bit about
L<Corrina|https://github.com/Ovid/Cor/wiki> and immediatly wanted to restart and
experiment my old C<Art::World> project. While searching for something somewhat
close to Corrina, since Corrina was only a draft and RFC, I discovered the
Zydeco toolkit by Toby Inkster and immediatly felt very enthusiastic to use it
to implement my idea. I hope it is a decent example of the possibilities this
wonderful framework make possible.

It is possible that this toolkit may be used by an art management software as it
could be needed in an art galery or a museum.

=head1 ROLES

=head2 Abstraction

This is were all kind of weird phenomenons between abstract artistic entities happen. See the
L<Manual|Art::World::Manual> about how it works.

=head2 Active

Is used to dissociate behaviors belonging to performers as opposed to the
public. Provide a C<participate> method.

=head2 Buyer

All those behaviors and attributes are encapsulated in the C<Buyer> role because
there is no such thing as somebody in the art world that buy but doesn't sale.

The C<aquire> method is requiring some C<money>. The C<money> is provided by the
C<Market> role.

  $collector->acquire( $artwork );

Those behaviors are delegated to the C<change_owner()> method, and to
the C<pay()> method from the C<Market> role.

When a C<Collector> C<acquire()> an C<Artwork>, the C<Artwork> C<ArrayRef> of
owners is automatically cleared and substituted by the new owner(s).
C<acquire()> will remove the value of the C<Artwork> from the owner's money.

  $artwork->change_owner( $self );

When the paiement occurs, the money is allocated to all the artwork owners
involved and removed from the buyer's fortune.

  $self->pay( $artwork );

It delegate the payment to the C<pay()> method of the C<Market> role. If the
payment is provided by an individual C<Buyer>, only one payment is done an the
money is dispatched to all the sellers. If a C<Collective> buy the good, each
member procede to a paiement from the C<Co-investors> point of view.

=head2 Collectionable

The C<collectionnable> provide a series of attributes for the ownership and
collectionability of artworks.

If it's collectionable, it can go to a C<Collector> collection or in a
C<Museum>. A collectionable item is automatically owned by it's creator.

C<Collectionable> provides a C<change_owner()> multi method that accepts either
C<Collectors> or C<Coinvestors> as an unique parameter. It takes care of setting
appropriately the new artwork owners and delegate the removal of the item from
the seller's collection.

A private methode, C<$remove_from_seller_collection> is also available to take
care of the removal of the I<to-be-sold> C<Artwork> in the seller collection.
Since those can be owned by many persons, and that C<Artists> can own their own
artworks, but for now cannot be collectors, they are excluded from this
treatment.

=head2 Collective

They do stuff together. You know, art is not about lonely C<Artists> in their
C<Workshop>.

This has first been designed for collectors, but could be used to
activate any kind of collective behavior.

This is quite a problem because what if a group of people wants to buy? We have
a C<Coinvestor> class implementing the C<Collective> role that provide a
I<collective-acquirement> method.

It's C<acquire()> multi method provide a way to collectively buy an item by
overriding the C<Buyer> role method. C<Coinvestor> is a class
inheriting from C<Collector> that implement the C<Collective> role so it would
be able to collectively acquire C<Works>.

Note that the signatures are different between C<Buyer> and C<Collective> roles:

  $collector->acquire( $artwork );
    # ==> using the method from the Buyer role

  $coinvestors->acquire({ art => $artwork, collective => $coinvestors });
    # ==> using the method from the Collective role

Just pass a self-reference to the coinvestor object and they will be able to organize and buy together.

=head2 Crud

The C<Crud> role makes possible to serialize most of the entities. For this to be
possible, they need to have a corresponding table in the database, plus they
need to not have a C<unserializable?> tag attribute. A Zydeco tag role is a role
without behavior that can only be checked using C<does>.

The Crud role is made possible thanks to L<Teng>, a simple DBI wrapper and O/R
Mapper. C<Teng> is used through it's L<schema loader|Teng::Schema::Loader> that
directly instanciate an object schema from the database.

When trying to update a value, it is necessary to pass a table name and a
hashref of attributes corresponding to the columns values. The table name is not case
sensitive when using C<Art::World> C<Crud> helpers.

  my $row = $self->dbh
    ->insert( 'agent', {
      name => $artist->name,
      reputation => $artist->reputation });

Note that it is extremely important that the testing of the database should be
done in the C<t/crud.t> file. If you want to test database or model
functionnalities in other tests, remind to create objects by specifiying the
config parameter that use the C<test.conf> file: only the database referenced in
C<test.conf> will be available on cpantesters and C<art.db> wont be available there,
only C<t/test.db> is available.

=head2 Event

All the necessary attributes and methodes for having fun between Art::world's Agents.

=head2 Exhibit

Role for L<C<Places>|Art::World/"Place"> that display some  L<C<Artworks>|Art::World/"Artwork">.

=head2 Fame

C<Fame> role provide ways to control the aura and reputation that various
C<Agents>, C<Places> or C<Works> have. Cannot be negative.

It has an handy C<bump_fame()> method that I<self-bump> the fame count. It can
be used in three specific maneers:

=over 2

=item pass a C<PositiveNum>

The fame will go higher

=item pass a C<NegativeNum>

The fame he fame will go lower

=item no parameter

In that case the value defined by C<< $self->config->{ FAME }->{ DEFAULT_BUMP } >>
will be used to increase the reputation.

=back

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

=head2 Identity

Provide C<id> and a C<name> attributes.

=head2 Invitation

=head2 Language

Useful when criticizing art or participating to all kind of events, especially
fo networking.

=head2 Manager

A role for those who I<take care> of exhibitions and other organizational
matters. See how being a C<Manager> influence an C<Agent> in the L<CLASSES>
section.

=head2 Market

It is all about offer, demand and C<money>. It is possible that a day, the
discourse that some people have can influence the C<Market>.

It provide a C<pay()> method that can be used by entities consumming this role
to exchange artworks on the market. This method accept an C<Artwork> as an and a
Collector as parameters. It smartly find how many people bought the good
and to how many sellers the money should be dispatched.

=head2 Showable

Only an object that does the C<Showable> role can be exhibited. An object should
be exhibited only if it reached the C<Showable> stage.

=head2 Space

Could limit the number of person attending an event for example

=head2 Underground

Provide an C<experiment()> method.

=head2 Writing

This is much more than small talk.

=head1 CLASSES

=head2 Agent

They are the activists of the Art World, previously known as the I<Wildlife>.

  my $agent = Art::World->new_agent(
    id         => 1,
    name       => Art::World::Util->new_person->fake_name,
    reputation => 10 # Would default to zero if none specified
  );

  $agent->participate;    # ==>  "That's interesting"

A generic entity that can be any activist of the C<Art::World>. Provides all
kind of C<Agent> classes and roles.

The C<Agent> got an a C<networking( $people )> method that makes possible to
leverage it's C<relationships>. When it is passed and C<ArrayRef> of various implementation
classes of C<Agents> (C<Artist>, C<Curator>, etc.) it bumps the C<reputation>
attributes of all of 1/10 of the C<Agent> with the highest reputation. If this
reputation is less than 1, it is rounded to the C<< $self->config->{ FAME }->{
DEFAULT_BUMP } >> constant.

The bump coefficient can be adjusted in the configuration through C<< { FAME }->{
BUMP_COEFFICIENT } >>.

There is also a special way of bumping fame when C<Manager>s are in a Networking
activity: The C<influence()> method makes possible to apply the special
C<< $self->config->{ FAME }->{ MANAGER_BUMP } >> constant. Then the C<Agent>s
reputations are bumped by the C<MANAGER_BUMP> value multiplicated by the highest
networking C<Manager> reputation. This is what the C<influence()> method
returns:

  return $self->config->{ FAME }->{ MANAGER_BUMP } * $reputation;

The default values can be edited in C<art.conf>.

=head2 Art

Will be what you decide it to be depending on how you combine all the entities.

This is where we are waiting to receive some I<unexpected parameters>: in other
words, an C<INI> file can be provided.

=head2 Article

Something in a C<Magazine> of C<Website> about C<Art>, C<Exhibitions>, etc.

=head2 Artist

In the beginning of their carreer they are usually underground and produce
experimental art, but this can change in time.

  my $artist = Art::World->new_artist(
    name => 'Andy Cassrol',
  );

  say $artist->is_homogenic;
  #==> false


After getting collected, artists become homogenic.

  $artist->is_underground if not $artist->has_collectors;

The artist got a lots of wonderful powers:

=over

=item C<create>

When the basic abstractions of Art are articulated, a creation occurs. It
doesn't mean that it will create an C<Artwork>, because it requires the
intervention of other C<Agents>. The C<Artist> creates through a work concept.
This articulation can group the different attributes of the C<Abstraction> role:
C<discourse>, C<file>, C<idea>, C<process>, C<project> and C<time>.

=item C<have_idea>

All day long

=back

=head2 Artwork

The base thing producted by artists. Artwork is subclass of
L<C<Work>|Art::World#Work> that have a C<Showable> and C<Collectionable> role.
They are usually considered as goods by the C<Market> but are also subject of
appreciation by the C<Public>. A lot of C<Event> happen around them.

The C<collectionable> role provide their C<value> while they have their own
attributes for C<material> and C<size>. The later limits the amount of atworks
that can be put in a C<Place>'s space during an C<Event>.

=head2 Book

Where a lot of theory is written by C<Critics>

=head2 Coinvestor

C<Coinvestor> extend the C<Collector> class by providing an arrayref attribute
of C<members> through the C<Collective> role. This role makes also possible to
invest in artworks I<collectively>.

=head2 Collector

A C<Collector> is mostly an C<Agent> that consume the C<Buyer> and C<Market>
roles and that have a C<collection> attribute.

  my $collector = Art::World
    ->new_collector(
      name => Art::World::Util->new_person->fake_name,
      money => 10_000,
      id => 4 );

  my $artwork = Art::World
    ->new_artwork(
      creator => $artist  ,
      title   => 'Destroy capitalism',
      value   => 9_999 );

  $collector->acquire( $artwork ),

  say $collector->money;
  #==> 1

  say $_->title for ( $collector->collection->@* );
  #==> Destroy capitalism

=head2 Concept

C<Concept> is an abstract class that does the C<Abstraction> role. It should be
extended but cannot be instanciated.

=head2 Critic

=head2 Curator

A special kind of Agent that I<can> select Artworks, define a thematic, setup
everything in the space and write a catalog. They mostly do C<Exhibition>.

=head2 Director

=head2 Exhibition

An C<Event> that is organised by a C<Curator>.

  my $exhibition = Art::World->new_exhibition(
    curator => [ $curator ],
    title   => $title,
    creator => [ $curator ]);

=head2 Gallery

Just another kind of L<C<Place>|Art::World/"Place">, mostly commercial.

Since it implements the L<C<Buyer>|Art::World/"Buyer"> role, a gallery can both
C<acquire()> and C<sell()>.

Major place for C<Agent->networking> activities. Always check it's C<space>
though!

=head2 Idea

When some abstractions starts to become something in the mind of an C<Agent>.

  my $art_concept = Art::World->new_idea(
    discourse => 'I have idead. Too many ideas. I store them in a file.',
    file => [ $another_concept, $weird_idea ],
    idea => 'idea',
    name => 'Yet Another Idea',
    process => [],
    project => 'My project',
    time => 5,
   );

=head2 Institution

A C<Place> that came out of the C<Underground>.

=head2 Magazine

=head2 Museum

Yet another kind of C<Place>, an institution with a lot of L<C<Artworks>|Art::World/"Artwork"> in the basement.

=head2 Opening

An C<Event> where you can consume free treats and speak with other networkers
from the art world.

  my $t = Art::World::Util->new_time( source => '2020-02-16T08:18:43' );
  my $opening_event = Art::World->new_opening(
    place     => $place,
    datetime => $t->datetime,
    name => 'Come See Our Stuff',
    smalltalk => $chat,
    treat     => [ 'Red wine', 'White wine', 'Peanuts', 'Candies' ]);

=head2 Place

A C<Place> must C<invite()> all kind of C<Agents> that produce C<Work> or other kind
of valuable social interactions. Depending of the total C<reputation> of the
C<Place> it will determine it's C<underground> status: when going out of the
C<underground>, it will become an institution.

=head2 Playground

A generic space where C<Art::World> C<Agents> can do all kind of weird things.

=head2 Public

They participate and visit events.

=head2 School

=head2 Sex

=head2 Squat

A place were art world agents are doing things. A squat that is not underground
anymore become an institution.

=head2 Theory

When some abstract concept turns to some said or written stuff.

=head2 Website

=head2 Work

There are not only C<Artworks>. All C<Agent>s produce various kind of work or
help consuming or implementing C<Art>.

It got an C<aura> attribute, see the L<C<Fame>|Art::World/"Fame"> about it or
read about L<Walter
Benjamin|https://en.wikipedia.org/wiki/Walter_Benjamin#%22The_Work_of_Art_in_the_Age_of_Mechanical_Reproduction%22>.

=head2 Workshop

A specific kind of L<C<Playground>|Art::World/"Playground"> where you can build things tranquilly.

=head1 AUTHOR

Sébastien Feugère <sebastien@feugere.net>

=head1 ACKNOWLEDGEMENTS

Thanks to everyone who has contributed to ack in any way, including Adrien
Lucca, Toby Inkster, Ezgi Göç, Pierre Aubert, Seb. Hu-Rillettes, Joseph Balicki,
Nicolas Herubel and Nadia Boursin-Piraud.

This project was made possible by the greatness of the L<Zydeco|https://zydeco.toby.ink/> toolkit.

=head1 COPYRIGHT AND LICENSE

Copyright 2006-2021 Sebastien Feugère

This library is free software; you can redistribute it and/or modify it under
the Artistic License 2.0.
