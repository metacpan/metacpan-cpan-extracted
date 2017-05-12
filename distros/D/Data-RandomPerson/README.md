# NAME

Data::RandomPerson - Create random person data.

# SYNOPSIS

    use Data::RandomPerson;

    my $r = Data::RandomPerson->new();

    my $p = $r->create();

# DESCRIPTION

## Overview

Returns an object that can be used to create random people and
return the data in a hash. The data is a hash reference with the
following keys:

- gender

    This is either 'm' or 'f'

- age

    The age of the person, as an integer.

- dob

    The date of birth of the person based upon how old they are in the
    current year. The month and day portion are selected randomly.

- firstname

    The person's first name based on their gender. The names are picked
    from Data::RandomPerson::Name::{Male,Female} unless other classes are
    supplied to the new method.

- lastname

    The person's last name. The names are picked from
    Data::RandomPerson::Name::Last
    unless another class is supplied to the new method.

- title

    The person's title based on their age and gender.

## Constructors and initialization

- new( HASH )

    Create the Data::RandomPerson object. By default
    Data::RandomPerson::Names::{Male,Female,Last} 
    are used to supply the male, female and last names. To pass in other
    classes to use you just put male => 'MyNames::Male' as arguments to 
    the method. 
    The three keys are 'male', 'female', and 'last'.

## Class and object methods

- \_pick\_gender( )

    Returns 'm' or 'f' with equal probability. This can be overridden
    to adjust the ratio on males to females in your target population.

- \_pick\_age( )

    Returns an age between 1 and 100. This can be overridden to return
    values in the range required of your target population.

- \_pick\_dob( )

    Calculates the date of birth from the age in the format
    YYYY-MM-DD. The YYYY value is the current year minus the age, MM and
    DD and random, valid, values. This method should not need to be
    overridden unless the date format is not what you require.

- \_pick\_title( )

    Return a suitable title based on the age and gender of the person.
    The ratios used here are completely made up and until I can get hold
    of some hard data, like a copy of the electoral roll, it can only be
    a best guess.

- \_pick\_lastname( )

    Returns a last name from the class loaded by the init() method. You
    should not need to override this method.

- \_pick\_firstname( )

    Returns a first name of the correct gender from the class loaded by the
    init() method. You should not need to override this method.

- create( )

    Returns a newly created person as a hash reference with the following
    keys: gender, age, dob, firstname, lastname and title. A new person is 
    returned for each call of the method although there is no guarantee of
    uniqueness.

# DIAGNOSTICS

- Unknown argument 'XXX' passed to new

    There are only three arguments that can be optionally passed to new. These
    are 'male', 'female' and 'last' and they should be the classes that will be
    used to get the male, female and last names.

- Unable to load 'XXX': ...

    A class given to load instead of the default class could not be loaded.
    Hopefully a sensible reason will be given.

# SEE ALSO

- Data::RandomPerson::Choice

    A simple class for selecting elements from a weighted list

- Data::RandomPerson::Names::Female
- Data::RandomPerson::Names::Last
- Data::RandomPerson::Names::Male
- Data::RandomPerson::Names::AncientGreekFemale
- Data::RandomPerson::Names::AncientGreekMale
- Data::RandomPerson::Names::ArabicFemale
- Data::RandomPerson::Names::ArabicLast
- Data::RandomPerson::Names::ArabicMale
- Data::RandomPerson::Names::BasqueFemale
- Data::RandomPerson::Names::BasqueMale
- Data::RandomPerson::Names::CelticFemale
- Data::RandomPerson::Names::CelticMale
- Data::RandomPerson::Names::EnglishFemale
- Data::RandomPerson::Names::EnglishLast
- Data::RandomPerson::Names::EnglishMale
- Data::RandomPerson::Names::HindiFemale
- Data::RandomPerson::Names::HindiMale
- Data::RandomPerson::Names::JapaneseFemale
- Data::RandomPerson::Names::JapaneseMale
- Data::RandomPerson::Names::LatvianFemale
- Data::RandomPerson::Names::LatvianMale
- Data::RandomPerson::Names::ModernGreekFemale
- Data::RandomPerson::Names::ModernGreekLast
- Data::RandomPerson::Names::ModernGreekMale
- Data::RandomPerson::Names::SpanishFemale
- Data::RandomPerson::Names::SpanishLast
- Data::RandomPerson::Names::SpanishMale
- Data::RandomPerson::Names::ThaiFemale
- Data::RandomPerson::Names::ThaiMale
- Data::RandomPerson::Names::VikingFemale
- Data::RandomPerson::Names::VikingMale

# AUTHOR

Peter Hickman (peterhi@ntlworld.com)

# COPYRIGHT

Copyright (c) 2005, Peter Hickman. 

Copyright (c) 2014, Michiel Beijen.

This module is free software. It may be used, redistributed and/or modified under the
same terms as Perl itself.
