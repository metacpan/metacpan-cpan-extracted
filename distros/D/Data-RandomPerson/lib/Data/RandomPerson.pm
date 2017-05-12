package Data::RandomPerson;

use strict;
use warnings;

use Data::Random qw(rand_date);
use Data::RandomPerson::Choice;
use Module::Find;

our $VERSION = '0.60';

sub new {
    my ( $class, %args ) = @_;

    my $self = bless {}, $class;

    ##
    ## Set up the defaults for the various name classes
    ## and see if they are being overwritten
    ##

    my $base_class = 'Data::RandomPerson::Names';

    my $male_class   = $base_class . '::Male';
    my $female_class = $base_class . '::Female';
    my $last_class   = $base_class . '::Last';

    foreach my $key ( sort keys %args ) {
        if ( lc $key eq 'male' ) {
            $male_class = $args{$key};
            delete( $args{$key} );
        }
        elsif ( lc $key eq 'female' ) {
            $female_class = $args{$key};
            delete( $args{$key} );
        }
        elsif ( lc $key eq 'last' ) {
            $last_class = $args{$key};
            delete( $args{$key} );
        }
        elsif ($key eq 'type') {
            $male_class   = $base_class . '::' . $args{$key} . 'Male';
            $female_class = $base_class . '::' . $args{$key} . 'Female';
            $last_class   = $base_class . '::' . $args{$key} . 'Last';
        }
        else {
            die "Unknown argument '$key' passed to new";
        }
    }

    ##
    ## Now load the classes
    ##

    eval "use $male_class;";
	die "Unable to load '$male_class': $@" if $@;

    eval "use $female_class;";
	die "Unable to load '$female_class': $@" if $@;

    eval "use $last_class;";
	die "Unable to load '$last_class': $@" if $@;

    $self->{mn} = $male_class->new();
    $self->{fn} = $female_class->new();
    $self->{ln} = $last_class->new();

    return $self;
}

################################################################################
# Subclass these if you want to change the gender, age and title calculated
################################################################################

sub _pick_gender {
    my ($self) = @_;

    return ( rand() < 0.5 ) ? 'm' : 'f';
}

sub _pick_age {
    my ($self) = @_;

    return int( rand() * 100 ) + 1;
}

sub _pick_title {
    my ($self) = @_;

    my $choice = Data::RandomPerson::Choice->new();

    if ( $self->{gender} eq 'm' ) {
        $choice->add( 'mr', 30 );
        $choice->add('dr')   if $self->{age} > 26;
        $choice->add('prof') if $self->{age} > 34;
        $choice->add('rev')  if $self->{age} > 34;
    }
    else {
        $choice->add('miss');
        $choice->add('ms') if $self->{age} > 16;
        $choice->add( 'mrs', 20 ) if $self->{age} > 16;
        $choice->add('dr')   if $self->{age} > 26;
        $choice->add('prof') if $self->{age} > 34;
        $choice->add('rev')  if $self->{age} > 34;
    }

    return ucfirst $choice->pick();
}

################################################################################
# These methods do not, typically, need to be overridden
################################################################################

sub _pick_lastname {
    my ($self) = @_;

    return $self->{ln}->get();
}

sub _pick_firstname {
    my ($self) = @_;

    return ( $self->{gender} eq 'm' ) ? $self->{mn}->get() : $self->{fn}->get();
}

sub _pick_dob {
    my ($self) = @_;

    my $year = ( localtime() )[5] + 1900 - $self->{age};
    my $dob  = rand_date(min => "$year-01-01", max => "$year-12-31");

    return $dob;
}

sub create {
    my ($self) = @_;

    ## These settings have no prerequisites

    $self->{gender}   = $self->_pick_gender();
    $self->{age}      = $self->_pick_age();
    $self->{dob}      = $self->_pick_dob();
    $self->{lastname} = $self->_pick_lastname();

    ## This setting requires gender

    $self->{firstname} = $self->_pick_firstname();

    ## This setting requires gender and age

    $self->{title} = $self->_pick_title();

    return { dob => $self->{dob}, gender => $self->{gender}, age => $self->{age}, firstname => $self->{firstname}, lastname => $self->{lastname}, title => $self->{title} };
}

sub available_types {
    my @backends = sort { $a cmp $b } findsubmod Data::RandomPerson::Names;
    my %backends = map {$_ => 1} @backends;
    my @available;
    for my $backend (grep {/Last$/} @backends) {
        if ($backend =~ /::(\w+)Last$/) {
            next if !$backends{'Data::RandomPerson::Names::' . $1 . 'Female'};
            next if !$backends{'Data::RandomPerson::Names::' . $1 . 'Male'};
            push @available, $1;
        }
    }
    return @available;
}

1;

__END__

=head1 NAME

Data::RandomPerson - Create random person data.

=head1 SYNOPSIS

  use Data::RandomPerson;

  my $r = Data::RandomPerson->new();
  my $p = $r->create();
  print $p->{firstname}, ' ', $p->{lastname}, "\n";

=head1 DESCRIPTION

=head2 Overview

Returns an object that can be used to create random people and
return the data in a hash. The data is a hash reference with the
following keys:

=over 4

=item gender

This is either 'm' or 'f'

=item age

The age of the person, as an integer.

=item dob

The date of birth of the person based upon how old they are in the
current year. The month and day portion are selected randomly.

=item firstname

The person's first name based on their gender. The names are picked
from Data::RandomPerson::Name::{Male,Female} unless other classes are
supplied to the new method.

=item lastname

The person's last name. The names are picked from
Data::RandomPerson::Name::Last
unless another class is supplied to the new method.

=item title

The person's title based on their age and gender.

=back

=head2 Constructors and initialization

=over 4

=item new(%options)

Create the Data::RandomPerson object. By default
Data::RandomPerson::Names::{Male,Female,Last}
are used to supply the male, female and last names.

If you want to generate names from a specific type, you can use the 'type'
parameter like this:

    my $r = Data::RandomPerson->new(type => 'Spanish');

The list of available types is obtained by calling available_types().
Only name lists that have collections for female, male and last names can
be specified here.

You can also choose to override the classes for last names, female or male
names. To do that, use the keys 'female', 'male', and 'last'.
Please note that in this case you need to specify the FULL class name.
For instance to create persons using a Celtic first name, use:

    my $r = Data::RandomPerson->new(
        female => 'Data::RandomPerson::Names::CelticFemale',
        male   => 'Data::RandomPerson::Names::CelticMale',
    );

=back

=head2 Class and object methods

=over 4

=item _pick_gender()

Returns 'm' or 'f' with equal probability. This can be overridden
to adjust the ratio on males to females in your target population.

=item _pick_age()

Returns an age between 1 and 100. This can be overridden to return
values in the range required of your target population.

=item _pick_dob()

Calculates the date of birth from the age in the format
YYYY-MM-DD. The YYYY value is the current year minus the age, MM and
DD and random, valid, values. This method should not need to be
overridden unless the date format is not what you require.

=item _pick_title()

Return a suitable title based on the age and gender of the person.
The ratios used here are completely made up and until I can get hold
of some hard data, like a copy of the electoral roll, it can only be
a best guess.

=item _pick_lastname()

Returns a last name from the class loaded by the init() method. You
should not need to override this method.

=item _pick_firstname()

Returns a first name of the correct gender from the class loaded by the
init() method. You should not need to override this method.

=item create()

Returns a newly created person as a hash reference with the following
keys: gender, age, dob, firstname, lastname and title. A new person is
returned for each call of the method although there is no guarantee of
uniqueness.

=item available_types()

Returns the list of available name types. These are the types you can request
in a call to new(). Usage:

    my @types = Data::RandomPerson::available_types();

=back

=head1 DIAGNOSTICS

=over 4

=item Unknown argument 'XXX' passed to new

There are only three arguments that can be optionally passed to new. These
are 'male', 'female' and 'last' and they should be the classes that will be
used to get the male, female and last names.

=item Unable to load 'XXX': ...

A class given to load instead of the default class could not be loaded.
Hopefully a sensible reason will be given.

=back

=head1 AUTHOR

Peter Hickman (peterhi@ntlworld.com)

=head1 COPYRIGHT

Copyright (c) 2005, Peter Hickman.

Copyright (c) 2014, Michiel Beijen.

This module is free software. It may be used, redistributed and/or modified under the
same terms as Perl itself.
