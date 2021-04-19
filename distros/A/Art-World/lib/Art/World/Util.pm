use 5.20.0;
use strict;
use warnings;

package Art::World::Util {

  use Zydeco;

  use feature qw( postderef );
  no warnings qw( experimental::postderef );

  class Math {
    method pick ( Int $min, Int $max ) {
      return $min + int ( rand ( $max - $min ));
    }
  }

  class Meta {
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

    method random_set_of_agents ( Int $num ) { }
  }

  # Makes possible to generate fake Persons very easily
  class Person {

    require Faker;
    has firstname ( isa => Str )     = $self->generator->person_first_name;
    has lastname  ( isa => Str )     = $self->generator->person_last_name;
    has generator ( isa => InstanceOf[ 'Faker' ] )  = Faker->new;
    has fake_name ( isa => Str )     = $self->firstname .' '. $self->lastname;

    method generate_discourse( ArrayRef $buzz = [] ) {
      for ( 0 .. int rand( 3 )) { push $buzz->@*, Faker->new->company_buzzword_type1 };
      return join ' ', $buzz->@*;
    }
  }

  class String {
    method titlify( Str $token ) {
      return join '', map { ucfirst lc $_ } split /(\s+)/, $token;
    }
  }

  class Time {
    require Time::Moment;
    # YYYY-MM-DDThh:mm:ss
    has source! (
      isa =>
      ( Str ) &
      ( StrMatch[ qr/ \A \d{4} - \d{2} - \d{2} T \d{2} : \d{2} : \d{2} \z /x ] ));
    has datetime ( isa => InstanceOf[ 'Time::Moment' ], lazy => true ) = Time::Moment->from_string( $self->source . 'Z' );
  }
}

1;

__END__

=encoding UTF-8

=head1 NAME

Art::World::Util - Generating all kind of data for the Art::World

=head1 SYNOPSIS

  use Art::World::Util;

  say Art::World::Util->new_person->fake_name;
  #==> Firtname Lastname

  say Art::World::Util->new_math->pick( 10, 1000 ));
  #==> 666

=head1 DESCRIPTION

C<Art::World::Util> provide useful generation tools for automated C<Agents>
creation, data manipulation and other utilities that are not strictly related to
the Art::World entities.

=head2 Methods

=head3 Art::World::Math

Artists usually don't like maths too much.

=head4 pick()

Pick an integer between a range that can be passed as a parameter. Mostly a way
to not have to memorize C<$min + int ( rand ( $max - $min ))>.

=head3 Art::World::Meta

Looks like the Art::World::Meta toolkit. See
L<https://metacpan.org/pod/Class::MOP::Class> for extreme cases.

  my $meta = $self->meta;

Also there is the Zydeco's C<$class> object.

This is a couple of utilities that makes a sort of meta-programming very simple. It is
more like a reminder for my bad memory than something very interesting. Largely
inspired by L<this Perl Monks thread|https://www.perlmonks.org/?node_id=1043195>.

  Art::World::Meta->get_all_attributes( $artist );
  # ==>  ( 'id', 'name', 'reputation', 'artworks', 'collectors', 'collected', 'status' )

Mostly useless since Zydeco rely on Moo(se) so the Moose Meta Object Protocol is
available.

=head4 get_class( Object $klass )

Returns the class of the object.

=head4 get_set_attributes_only( Object $clazz )

Returns only attributes that are set for a particular object.

=head4  get_all_attributes( Object $claxx )

Returns even non-set attributes for a particular object.

=head3 Art::World::Person

=head4 fake_name()

Generate a complete person name using L<Faker>.

=head3 Art::World::String

=head4 titlify()

=head3 Art::World::Time

Handy way for generating a L<Time::Moment> object that can be used for C<Events> for example.

  my $t = Art::World::Util->new_time( source => '2020-02-16T08:18:43' );

=head1 AUTHOR

Sébastien Feugère <sebastien@feugere.net>

=head1 COPYRIGHT AND LICENSE

Copyright 2006-2021 Sebastien Feugère

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.
