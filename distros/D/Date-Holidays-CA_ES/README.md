# NAME

Date::Holidays::CA\_ES - Catalan holidays

# SYNOPSIS

    use Date::Holidays;

    my $dh = Date::Holidays->new( countrycode => 'es' );
    $dh->is_holiday(year => 2007, month => 4, day => 9 , region => 'ca')

# DESCRIPTION

This module provide the official holidays for Catalonia, an Autonomous
Community of Spain. It makes use of Date::Holidays::ES as parent class, since
the catalan holidays are the spanish ones plus some more.

The following Catalan holidays have fixed dates (remember to take a look to the
spanish ones as well!)

    6  Jan           Reis
    24 Jun           Sant Joan
    11 Sep           Diada Nacional
    26 Dec           Sant Esteve

The following Catalan holiday hasn't a fixed date:

    Pasqua Florida    Three days after the spanish holiday "Viernes Santo"

# METHODS

The methods are identical to Date::Holidays::ES ones, except those with the
"es" country code in them.

## holidays

This is the only implemented method, adding the catalan holidays to the days
provided by Date::Holidays::ES

# SEE ALSO

[Date::Holidays::ES](https://metacpan.org/pod/Date%3A%3AHolidays%3A%3AES),

# AUTHOR

Miquel Ruiz, <mruiz@cpan.org>

# COPYRIGHT & LICENSE

Copyright 2020 Miquel Ruiz.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
