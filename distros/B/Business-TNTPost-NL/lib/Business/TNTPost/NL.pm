package Business::TNTPost::NL;

use strict;
use Business::TNTPost::NL::Data qw/:ALL/;
use Carp;
use List::Util qw/reduce/;

our $VERSION = 0.11;
our $ERROR   = undef;

use base qw/Class::Accessor::Fast/;

BEGIN {
    __PACKAGE__->mk_accessors(
        qw/cost large machine priority receipt register tracktrace weight zone/
    );
}

=pod

=head1 NAME

Business::TNTPost::NL - Calculate Dutch (TNT Post) shipping costs

=head1 SYNOPSIS

  use Business::TNTPost::NL;

  my $tnt = Business::TNTPost::NL->new();
     $tnt->country('DE');
     $tnt->weight('534');
     $tnt->large(1);
     $tnt->priority(1);
     $tnt->tracktrace(1);
     $tnt->register(1);

  my $costs = $tnt->calculate or die $Business::TNTPost::NL::ERROR;


or

  use Business::TNTPost::NL;

  my $tnt = Business::TNTPost::NL->new();
  my $costs = $tnt->calculate(
                  country    =>'DE',
                  weight     => 534,
                  large      => 1,
                  tracktrace => 1,
                  register   => 1,
              ) or die $Business::TNTPost::NL::ERROR;

=head1 DESCRIPTION

This module calculates the shipping costs for the Dutch TNT Post,
based on country, weight and priority shipping (or not), etc.

The shipping cost information is based on 'Tarieven Januari 2011'.

It returns the shipping costs in euro or undef (which usually means
the parcel is heavier than the maximum allowed weight; check
C<$Business::TNTPost::NL::ERROR>).

=head2 METHODS

The following methods can be used

=head3 new

C<new> creates a new C<Business::TNTPost::NL> object. No more, no less.

=cut

sub new {
    my ( $class, %parameters ) = @_;
    my $self = bless( {}, ref($class) || $class );
    return $self;
}

=pod

=head3 country

Sets the country (ISO 3166, 2-letter country code) and returns the
zone number used by TNT Post (or 0 for The Netherlands (NL)).

This value is mandatory for the calculations.

Note that the reserved IC has been used for the Canary Islands. This
has not been adopted by ISO 3166 yet. The Channel Islands are completely
ignored due to a lack of a code.

=cut

sub country {
    my ( $self, $cc ) = @_;

    if ($cc) {
        my $zones = Business::TNTPost::NL::Data::zones();
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

Returns the shipping costs in euro, or undef (see $Business::TNTPost::NL::ERROR
in that case).

=cut

sub calculate {
    my ( $self, %opt ) = @_;

    # Set the options
    for (
        qw/country weight large priority tracktrace
        register receipt machine/
      )
    {
        $self->$_( $opt{$_} ) if ( defined $opt{$_} );
    }

    croak "Not enough information!"
      unless ( defined $self->zone && defined $self->weight );

    # > 2000 grams automatically means 'tracktrace'
    $self->tracktrace(1) if ( $self->weight > 2000 );

    # Zone 1..4 (with tracktrace) automagically means 'priority'
    $self->priority(1) if ( $self->tracktrace );

    # Zone 3,4 + small automagically means 'priority'
    $self->priority(1) if( $self->zone > 3 && !$self->large );

    # All zones (above NL) are now priority by default
    $self->priority(1) if $self->zone;

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
        push @p, 'world';    # world
        if ( $self->register ) {
            push @p, 'register',    # w/register
              ( $self->zone < 4 )   # w/register/(europe|world)
                ? 'europe'
                : 'world',
              ( $self->machine )   # w/register/(e|w)/(stamp|machine)
                ? 'machine'
                : 'stamp';
        }
        elsif ( $self->tracktrace ) {
            push @p, 'plus', 'zone', $self->zone;    # w/plus/zone/[1..4]
        }
        else {
            push @p, 'basic',           # w/basic
              ( $self->zone < 4 )       # w/basic/(europe|world)
                ? 'europe'
                : 'world',
              ( $self->large )          # w/basic/(e|w)/(large|small)
                ? 'large'
                : 'small';

        if( !$self->large ) {
        # w/basic/(e|w)/small/(machine|stamp)
                push @p, ( $self->machine ) ? 'machine' : 'stamp';
            }

            ### priority is now always the default
            push @p, 'priority';
            #push @p,
            #  ( $self->priority )       # w/basic/(e|w)/(l|s)/(m|s)?/(p|s)
            #    ? 'priority'
            #    : 'standard';
        }
    }
    else {
        push @p, 'netherlands';         # netherlands
        if ( $self->register ) {
            push @p, 'register';        # n/register
        }
        else {
            push @p, ( $self->large )   # n/(large|small)
              ? 'large'
              : 'small';
        }
        ( push @p, ( $self->machine ) ? 'machine' : 'stamp' )
            unless $self->large;;
    }
    # debug
    # print (join " :: ", @p), "\n";
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

=head3 tracktrace

Sets and/or returns the value of this options. Defaults to undef (meaning:
no track & trace feature wanted). When a parcel destined for abroad
weighs over 2 kilograms, default is 1, while over 2kg it's not even
optional anymore.

=head3 register

Sets and/or returns the value of this options. Defaults to undef (meaning:
parcel is not registered (Dutch: aangetekend)).

=head3 machine

Sets and/or returns the value of this options. Defaults to undef (meaning:
stamps will be used, not the machine (Dutch: frankeermachine)).

Only interesting for destinies within NL. Note that "Pakketzegel AVP"
and "Easystamp" should also use this option.

=head1 BUGS

Please do report bugs/patches to
L<http://rt.cpan.org/Public/Dist/Display.html?Name=Business-TNTPost-NL>

=head1 CAVEAT

The Dutch postal agency (TNT Post) uses many, many, many various ways
for you to ship your parcels. Some of them are included in this module,
but a lot of them not (maybe in the future? Feel free to patch ;-)

This module handles the following shipping ways (page numbers refer to the
TNT Post booklet (sorry, all in Dutch)).

'Brieven' and 'Pakketten' either paid by 'frankeermachine'. For both,
'aangetekend' is optional. The pagenumbers used: 18, 19, 20, 21.

These should be the most commom methods of shipment.

=head1 AUTHOR

Menno Blom,
E<lt>blom@cpan.orgE<gt>,
L<http://menno.b10m.net/perl/>

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=head1 SEE ALSO

L<http://www.tntpost.nl/>,
L<http://www.tntpost.nl/zakelijk/Images/TNP%20TB%20digitaal_2_tcm210-527873.pdf>,
L<http://www.iso.org/iso/en/prods-services/iso3166ma/index.html>

=cut

1;
