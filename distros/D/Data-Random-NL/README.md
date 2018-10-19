# DESCRIPTION

This module provides methods to generate fake and/or random data used
for spoofing and/or faking data such as BSN numbers and KvK numbers.

None of the methods are exported by default.

# SYNOPSIS

    use Data::Random::NL qw(:all);

    my $bsn              = generate_bsn();
    my $kvk              = generate_kvk();
    my $rsin             = generate_rsin();
    my $vestigingsnummer = generate_vestingsnummer();

# A word of warning

Be aware that this module may produce numbers that are used in the real world.
BSN numbers in test situations start by convention with a `9`.

# EXPORT\_OK

- generate\_bsn
- generate\_rsin
- generate\_kvk
- generate\_vestigingsnummer

# EXPORT\_TAGS

- :all

    Get all the generate functions

- :person

    Imports all the numbers in use for a person

- :company

    Imports all the numbers in use for a company

# METHODS

## generate\_bsn

Generate a BSN (burgerservicenummer/social security number).

    generate_bsn(); # returns a BSN
    generate_bsn(9); # returns a BSN starting with a 9

## generate\_kvk

Generate a KvK (Kamer van Koophandel/Chamber of Commerce) number

    generate_kvk(); # returns a KvK number
    generate_kvk(9); # returns a KvK number starting with a 9

## generate\_rsin

Generate a RSIN number

    generate_rsin(); # returns a RSIN number
    generate_rsin(9); # returns a RSIN number starting with a 9

## generate\_vestigingsnummer

Generate a vestigings number

    generate_vestigingsnummer(); # returns a vestigings number
    generate_vestigingsnummer(9); # returns a vestigings number starting with a 9

# SEE ALSO

- bsn

    [https://www.government.nl/topics/personal-data/citizen-service-number-bsn](https://www.government.nl/topics/personal-data/citizen-service-number-bsn)

- kvk

    [https://www.kvk.nl/download/De\_nummers\_van\_het\_Handelsregister\_tcm109-365707.pdf](https://www.kvk.nl/download/De_nummers_van_het_Handelsregister_tcm109-365707.pdf)

- rsin

    [https://www.kvk.nl/english/registration/rsin-number/](https://www.kvk.nl/english/registration/rsin-number/)
