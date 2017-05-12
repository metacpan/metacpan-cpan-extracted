package Business::PostNL;

use strict;
use Business::PostNL::Data qw/:ALL/;
use Carp;
use List::Util qw/reduce/;

our $VERSION = 0.14;
our $ERROR   = undef;

use base qw/Class::Accessor::Fast/;

BEGIN {
    __PACKAGE__->mk_accessors(
        qw/cost large machine priority receipt register tracktrace weight zone/
    );
}

=pod

=head1 NAME

Business::PostNL - Calculate Dutch (PostNL) shipping costs

=head1 SYNOPSIS

  use Business::PostNL;

  my $tnt = Business::PostNL->new();
     $tnt->country('DE');
     $tnt->weight('534');
     $tnt->large(1);
     $tnt->tracktrace(1);
     $tnt->register(1);

  my $costs = $tnt->calculate or die $Business::PostNL::ERROR;


or

  use Business::PostNL;

  my $tnt = Business::PostNL->new();
  my $costs = $tnt->calculate(
                  country    =>'DE',
                  weight     => 534,
                  large      => 1,
                  tracktrace => 1,
                  register   => 1,
              ) or die $Business::PostNL::ERROR;

=head1 DESCRIPTION

This module calculates the shipping costs for the Dutch PostNL,
based on country, and weight etc.

The shipping cost information is based on 'Posttarieven
Per januari 2014'.

It returns the shipping costs in euro or undef (which usually means
the parcel is heavier than the maximum allowed weight; check
C<$Business::PostNL::ERROR>).

=head2 METHODS

The following methods can be used

=head3 new

C<new> creates a new C<Business::PostNL> object. No more, no less.

=cut

sub new {
    my ( $class, %parameters ) = @_;
    my $self = bless( {}, ref($class) || $class );
    return $self;
}

=pod

=head3 country

Sets the country (ISO 3166, 2-letter country code) and returns the
zone number used by PostNL (or 0 for The Netherlands (NL)).

This value is mandatory for the calculations.

Note that the reserved IC has been used for the Canary Islands. This
has not been adopted by ISO 3166 yet. The Channel Islands are completely
ignored due to a lack of a code.

=cut

sub country {
    my ( $self, $cc ) = @_;

    if ($cc) {
        my $zones = Business::PostNL::Data::zones();
        $self->zone( defined $zones->{$cc} ? $zones->{$cc} : '4' );
    }

    return $self->zone;
}

=pod

=head3 calculate

Method to calculate the actual shipping cost based on the input (see
methods above). These options can also be passed straight in to this method
(see L<SYNOPSIS>).

Two settings are mandatory: country and weight. The rest are given a
default value that will be used unless told otherwise.

Returns the shipping costs in euro, or undef (see $Business::PostNL::ERROR
in that case).

=cut

sub calculate {
    my ( $self, %opt ) = @_;

    # Set the options
    for ( qw/country weight large tracktrace register machine/) {
        $self->$_( $opt{$_} ) if ( defined $opt{$_} );
    }

    croak "Not enough information!"
      unless ( defined $self->zone && defined $self->weight );

    # > 2000 grams automatically means 'tracktrace'
    $self->tracktrace(1) if ( $self->weight > 2000 );

    # Fetch the interesting table
    my $ref = _pointer_to_element( table(), $self->_generate_path );
    my $table = $$ref;

    my $highest = 0;
    foreach my $key ( keys %{$table} ) {
        my ( $lo, $hi ) = split ',', $key;
        $highest = $hi if ( $hi > $highest );
        if ( $self->weight >= $lo && $self->weight <= $hi ) {
            $self->cost( $table->{$key} );
            last;
        }
    }
    $ERROR = $self->weight - $highest . " grams too heavy (max: $highest gr.)"
      if ( $highest < $self->weight );

    return ( $self->cost ) ? sprintf( "%0.2f", $self->cost ) : undef;
}

=pod

=head3 _generate_path

Internal method to create the path to walk through the pricing table.
Don't call this, use L<calculate> instead.

=cut

sub _generate_path {
    my $self = shift;

    my @p;

    if ( $self->zone ) {
        push @p, 'world';           # world

        if( $self->large ) {
            push @p, 'large',       # w/large
                     'zone',        # w/large/zone
                     $self->zone;   # w/large/zone/[1..4]
            push @p,
                ( $self->machine )
                ? 'machine'         # w/large/zone/[1..4]/machine
                : 'stamp';          # w/large/zone/[1..4]/stamp

            push @p,
                ( $self->register )
                ? 'register'        # w/large/zone/[1..4]/(m|s)/register
                : ( $self->tracktrace )
                  ? 'tracktrace'    # w/large/zone/[1..4]/(m|s)/tracktrace
                  : 'normal';       # w/large/zone/[1..4]/(m|s)/normal

        }
        else {
            push @p, 'small';       # w/small
            push @p,
                ( $self->zone < 4 )
                ? 'europe'          # w/small/europe
                : 'world';          # w/small/world
            push @p,
                ( $self->machine )
                ? 'machine'         # w/small/(e|w)/machine
                : 'stamp';          # w/small/(e|w)/stamp
            push @p,
                ( $self->register )
                ? 'register'        # w/small/(e|w)/(m|s)/register
                : 'normal';         # w/small/(e|w)/(m|s)/normal
        }
    }
    else {
        push @p, 'netherlands';                 # netherlands
        if ( $self->register ) {
            push @p, 'register';                # n/register
        }
        else {
            push @p, ( $self->large )           # n/(large|small)
              ? 'large'
              : 'small';
        }
        push @p,
            ( $self->machine )
            ? 'machine'                         # n/(r|l|s)/machine
            : 'stamp';                          # n/(r|l|s)/stamp
    }
    #print (join " :: ", @p), "\n";
    return @p;
}

=pod

=head3 _pointer_to_element

Blame L<merlyn> for this internal method. It's using L<List::Util>
to "grep" the information needed.

Don't call this, use L<calculate> instead.

=cut

sub _pointer_to_element {                       # Thanks 'merlyn'!
    require List::Util;
    return List::Util::reduce( sub { \( $$a->{$b} ) }, \shift, @_ );
}

=pod

=head3 weight

Sets and/or returns the weight of the parcel in question in grams.

This value is mandatory for the calculations.

=head3 large

Sets and/or returns the value of this option. Defaults to undef (meaning:
the package will fit through the mail slot).

=head3 priority [DEPRECATED]

PostNL still requires you to put a priority sticker on your letters and
parcels, but this seems to be solely for speed of delivery. I couldn't
find any price difference, hence this setting is ignored from now on and
only here for backwards compatability.

=head3 tracktrace

Sets and/or returns the value of this options. Defaults to undef (meaning:
no track & trace feature wanted). When a parcel destined for abroad
weighs over 2 kilograms, default is 1, while over 2kg it's not even
optional anymore.

=head3 register

Sets and/or returns the value of this options. Defaults to undef (meaning:
parcel is not registered (Dutch: aangetekend)).

=head3 receipt [DEPRECATED]

No longer an option, solely here for backwards compatibility.

=head3 machine

Sets and/or returns the value of this options. Defaults to undef (meaning:
stamps will be used, not the machine (Dutch: frankeermachine)).

Only interesting for destinies within NL. Note that "Pakketzegel AVP"
and "Easystamp" should also use this option.

=head1 BUGS

Please do report bugs/patches to
L<http://rt.cpan.org/Public/Dist/Display.html?Name=Business-PostNL>

=head1 CAVEAT

The Dutch postal agency (PostNL) uses many, many, many various ways
for you to ship your parcels. Some of them are included in this module,
but a lot of them not (maybe in the future? Feel free to patch ;-)

=head1 AUTHOR

Menno Blom,
E<lt>blom@cpan.orgE<gt>

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=head1 SEE ALSO

L<http://www.postnl.nl/>,
L<http://www.postnl.nl/zakelijk/Images/Tarievenkaart-januari-2014-PostNL_tcm210-681029.PDF>,
L<http://www.iso.org/iso/en/prods-services/iso3166ma/index.html>

=cut

1;
