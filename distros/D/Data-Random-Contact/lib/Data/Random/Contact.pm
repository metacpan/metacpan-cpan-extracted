package Data::Random::Contact;
BEGIN {
  $Data::Random::Contact::VERSION = '0.05';
}

use namespace::autoclean;

use Moose;

use Class::Load qw( load_class );
use Data::Random::Contact::Language::EN;
use Data::Random::Contact::Country::US;
use Data::Random::Contact::Types qw( Country Language );
use DateTime;
use Scalar::Util qw( blessed );

has language => (
    is      => 'ro',
    isa     => Language,
    default => 'Data::Random::Contact::Language::EN',
);

has country => (
    is      => 'ro',
    isa     => Country,
    default => 'Data::Random::Contact::Country::US',
);

override BUILDARGS => sub {
    my $class = shift;
    my $p     = super();

    if ( $p->{language} && !blessed $p->{language} ) {
        my $language
            = $p->{language} =~ /^Data::Random::Contact::Language::/
            ? $p->{language}
            : 'Data::Random::Contact::Language::' . $p->{language};

        load_class($language);

        $p->{language} = $language;
    }

    if ( $p->{country} && !blessed $p->{country} ) {
        my $country
            = $p->{country}
            && $p->{country} =~ /^Data::Random::Contact::Country::/
            ? $p->{country}
            : 'Data::Random::Contact::Country::' . $p->{country};

        load_class($country);

        $p->{country} = $country;
    }
    return $p;
};

my $MaxBirthdate = DateTime->today()->subtract( years => 15 );
my $MinBirthdate = DateTime->today()->subtract( years => 100 );
my $Days = $MaxBirthdate->delta_days($MinBirthdate)->in_units('days') - 1;

my $Suffix = 0;

sub person {
    my $self = shift;

    my %contact;

    $contact{gender} = _percent() <= 50 ? 'male' : 'female';

    my $salutation_meth = $contact{gender} . '_salutation';

    $contact{salutation} = $self->language()->$salutation_meth();

    my $name_meth = $contact{gender} . '_given_name';

    $contact{given} = $self->language()->$name_meth();

    my $middle_name_meth = $contact{gender} . '_middle_name';

    $contact{middle} = $self->language()->$middle_name_meth();

    $contact{surname} = $self->language()->surname();

    my $suffix_meth = $contact{gender} . '_suffix';

    $contact{suffix} = $self->language()->$suffix_meth();

    $contact{birth_date}
        = $MinBirthdate->clone()->add( days => int( rand($Days) ) );

    for my $type (qw( mobile home work )) {
        $contact{phone}{$type} = $self->country()->phone_number();
    }

    for my $type (qw( home work )) {
        $contact{address}{$type} = $self->country()->address();
    }

    $contact{email}{home}
        = join '.',
        map {lc} grep {defined} @contact{ 'given', 'middle', 'surname' };
    $contact{email}{home} .= '@' . $self->_domain();

    $contact{email}{work} = lc $contact{given} . $Suffix++;
    $contact{email}{work} .= '@' . $self->_domain();

    return \%contact;
}

sub household {
    my $self = shift;

    my %contact;

    $contact{name} = $self->language()->household_name();

    $contact{phone}{home} = $self->country()->phone_number();

    $contact{address}{home} = $self->country()->address();

    ( $contact{email}{home} = $contact{name} ) =~ s/\W/./g;
    $contact{email}{home} .= '@' . $self->_domain();

    return \%contact;
}

sub organization {
    my $self = shift;

    my %contact;

    $contact{name} = $self->language()->organization_name();

    $contact{phone}{office} = $self->country()->phone_number();

    for my $type (qw( headquarters branch )) {
        $contact{address}{$type} = $self->country()->address();
    }

    ( $contact{email}{home} = $contact{name} ) =~ s/\W/./g;
    $contact{email}{home} .= '@' . $self->_domain();

    return \%contact;
}

{

    # Fake Name Generator uses these domains, so I assume they're safe.
    my @Domains = qw(
        pookmail.com
        trashymail.com
        dodgit.com
        mailinator.com
        spambob.com
    );

    sub _domain {
        return @Domains[ int( rand( scalar @Domains ) ) ];
    }
}

sub _percent {
    return ( int( rand(100) ) ) + 1;
}

__PACKAGE__->meta()->make_immutable();

1;

# ABSTRACT: Generate random contact data



=pod

=head1 NAME

Data::Random::Contact - Generate random contact data

=head1 VERSION

version 0.05

=head1 SYNOPSIS

    use Data::Random::Contact;

    my $randomizer = Data::Random::Contact->new();

    my $person       = $rand->person();
    my $household    = $rand->household();
    my $organization = $rand->organization();

=head1 DESCRIPTION

B<This module is still alpha, and the API may change in future releases.>

This module generates random data for contacts. This is useful if you're
working an application that manages this sort of data.

It generates three types of contacts, people, households, and
organizations.

=head1 LICENSING

The data that this module uses comes from several sources. Names are based on
data from Fake Name Generator (L<http://www.fakenamegenerator.com>). This
data is dual-licensed under GPLv3 or CC BY-SA 3.0 (United Stated). See
http://www.fakenamegenerator.com/license.php for licensing details.

The address data is all B<real addresses> from the VegGuide.org website
(L<http://vegguide.org>). This data is licensed under the CC BY-NC-SA 3.0
(United Stated) license.

All other data is generated algorithmically.

Whether a license can apply to things like addresses and names is debatable,
but I am not a lawyer.

=head1 METHODS

This module provides just a few public methods:

=head2 Data::Random::Contact->new()

This constructs a new object. It accepts two optional parameters:

=over 4

=item * language

This can either be a language name like "EN" or an instantiated language
class, for example L<Data::Random::Contact::Language::EN>.

The language is used to generate names.

This defaults to "EN".

Currently this distribution only ships with one language, English
(L<Data::Random::Contact::Language::EN>).

=item * country

This can either be a country name like "US" or an instantiated country
class, for example L<Data::Random::Contact::Country::US>.

The country is used to generate phone numbers and addresses.

This defaults to "EN".

Currently this distribution only ships with one country, US
(L<Data::Random::Contact::Country::US>).

=back

=head2 $randomizer->person()

This returns a random set of data for a single person.

See L</RETURNED DATA> for details.

=head2 $randomizer->household()

This returns a random set of data for a single household.

See L</RETURNED DATA> for details.

=head2 $randomizer->organization()

This returns a random set of data for a single organization.

See L</RETURNED DATA> for details.

=head1 RETURNED DATA

Each of the methods that return contact data returns a complicated
hashref-based data structure.

=head2 Shared Data

Some of the data is shared across all contact types:

All contact types return email, phone, and address data. This data is
available under the appropriate key ("email", "phone", or "address") in the
top-level data structure.

Under that key the data is further broken down by type, which will be
something like "home", "work", "office", etc. Every contact will have all the
valid keys set. In other words, a person will always have both a home and work
email address.

The email data will always be at one of these domains: pookmail.com,
trashymail.com, dodgit.com, mailinator.com, or spambob.com.

The phone number will be a string containing all the phone number data.

Each address is further broken down as a hashref data structure.

See the appropriate language module for details on phone numbers and
addresses.

Here's an example of the shared data for a person (using US data):

    {
        address => {
            home => {
                city        => "Reno",
                postal_code => 89503,
                region      => "Nevada",
                region_abbr => "NV",
                street_1    => "501 W. 1st St.",
                street_2    => undef
            },
            work => {
                city        => "Minneapolis",
                postal_code => 55406,
                region      => "Minnesota",
                region_abbr => "MN",
                street_1    => "2823 E. Franklin Avenue",
                street_2    => undef
            }
        },
        email => {
            home => "charlotte.t.dolan\@pookmail.com",
            work => "charlotte0\@dodgit.com"
        },
        phone => {
            home   => "508-383-7535",
            mobile => "775-371-7227",
            work   => "602-995-6077"
        },
    }

=head2 Person Data

Since much of this data is language-specific, you should see the appropriate
language module for details. Some keys may be undefined, depending on the
language.

The data for a person includes:

=over 4

=item * given

The person's given name.

The set of names used is determined by the language.

=item * middle

The person's middle name or initial.

The set of names used is determined by the language.

=item * surname

The person's surname.

The set of names used is determined by the language.

=item * gender

This will be either "male" or "female".

=item * salutation

A salutation for the person ("Mr", "Ms", etc.). These salutations are
gender-specific.

The set of salutations used is determined by the language.

=item * suffix

An optional suffix like "Jr" or "III".

The set of salutations used is determined by the language.

=item * birth_date

A L<DateTime> object representing the person's birth date. The date will be
somewhere between 15 and 100 years in the past.

=item * email addresses

The email address types for a person are "home" and "work".

=item * phone numbers

The phone number types for a person are "home", "work", and "mobile".

=item * addresses

The address types for a person are "home" and "work".

=back

=head2 Household Data

The data for a person includes:

=over 4

=item * name

The household name.

The set of names used is determined by the language.

=item * email addresses

The only email address type for a household is "home".

=item * phone numbers

The only phone number type for a household is "home".

=item * addresses

The only address type for a household is "home".

=back

=head2 Organization Data

The data for a person includes:

=over 4

=item * name

The organization name.

The set of names used is determined by the language.

=item * email addresses

The only email address type for an organization is "home".

=item * phone numbers

The only phone number type for an organization is "office".

=item * addresses

The address types for a organization are "headquarters" and "branch".

=back

=head2 Data Dumps

Here are complete data dumps for each contact type:

=over 4

=item * Person

    {
        given      => "Gregory",
        middle     => "Antoine",
        surname    => "Jones",
        birth_date => bless( {'...'}, 'DateTime' ),
        salutation => "Mr",
        suffix     => "IV",
        gender     => "male",
        address => {
            home => {
                city        => "Boulder",
                postal_code => 80304,
                region      => "Colorado",
                region_abbr => "CO",
                street_1    => "2785 Iris Avenue",
                street_2    => undef
            },
            work => {
                city        => "Albuquerque",
                postal_code => 87106,
                region      => "New Mexico",
                region_abbr => "NM",
                street_1    => "2110 Central Ave SE",
                street_2    => undef
            }
        },
        email      => {
            home => "gregory.antoine.jones\@trashymail.com",
            work => "gregory0\@pookmail.com"
        },
        phone  => {
            home   => "881-348-3582",
            mobile => "727-862-8526",
            work   => "305-389-4232"
        },
    }

=item * Household

    {
        name    => "The Briley Household",
        address => {
            home => {
                city        => "Lombard",
                postal_code => undef,
                region      => "Illinois",
                region_abbr => "IL",
                street_1    => "2361 Fountain Square Dr.",
                street_2    => undef
            }
        },
        email => { home => "The.Briley.Household\@mailinator.com" },
        phone => { home => "307-342-9913" }
    }

=item * Organization

    {
        name    => "pastorate womanish",
        address => {
            branch => {
                city        => "Northbrook",
                postal_code => undef,
                region      => "Illinois",
                region_abbr => "IL",
                street_1    => "1819 Lake Cook Rd.",
                street_2    => undef
            },
            headquarters => {
                city        => "Springfield",
                postal_code => undef,
                region      => "New Jersey",
                region_abbr => "NJ",
                street_1    => "518 Millburn Ave",
                street_2    => undef
            }
        },
        email => { home   => "pastorate.womanish\@mailinator.com" },
        phone => { office => "876-278-8382" }
    }

=back

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 by Dave Rolsky.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut


__END__

