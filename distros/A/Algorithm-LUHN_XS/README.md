# NAME

Algorithm::LUHN\_XS - XS Version of the original Algorithm::LUHN

# SYNOPSIS

    use Algorithm::LUHN_XS qw/check_digit is_valid/;

    $c = check_digit("43881234567");
    print "It works\n" if is_valid("43881234567$c");

    $c = check_digit("A2C4E6G8"); # this will cause an error

    print "Valid LUHN characters are:\n";
    my %vc = Algorithm::LUHN_XS::valid_chars();
    for (sort keys %vc) {
      print "$_ => $vc{$_}\n";
    }

    Algorithm::LUHN_XS::valid_chars(map {$_ => ord($_)-ord('A')+10} A..Z);
    $c = check_digit("A2C4E6G8");
    print "It worked again\n" if is_valid("A2C4E6G8$c");

# DESCRIPTION

This module is an XS version of the original Perl Module Algorithm::LUHN, which
was written by Tim Ayers.  It should work exactly the same, only substantially
faster.

The rest of the documentation is a copy of the original docs.

This module calculates the Modulus 10 Double Add Double checksum, also known as
the LUHN Formula. This algorithm is used to verify credit card numbers and
Standard & Poor's security identifiers such as CUSIP's and CSIN's.

You can find plenty of information about the algorithm by searching the web for
"modulus 10 double add double".

# FUNCTION

- is\_valid CHECKSUMMED\_NUM

    This function takes a credit-card number and returns true if
    the number passes the LUHN check.

    Ie it returns true if the final character of CHECKSUMMED\_NUM is the
    correct checksum for the rest of the number and false if not. Obviously the
    final character does not factor into the checksum calculation. False will also
    be returned if NUM contains in an invalid character as defined by
    valid\_chars(). If NUM is not valid, $Algorithm::LUHN\_XS::ERROR will contain the
    reason.

    This function is equivalent to

        substr $N,length($N)-1 eq check_digit(substr $N,0,length($N)-1)

    For example, `4242 4242 4242 4242` is a valid Visa card number,
    that is provided for test purposes. The final digit is '2',
    which is the right check digit. If you change it to a '3', it's not
    a valid card number. Ie:

        is_valid('4242424242424242');   # true
        is_valid('4242424242424243');   # false

- check\_digit NUM

    This function returns the checksum of the given number. If it cannot calculate
    the check\_digit it will return undef and set $Algorithm::LUHN\_XS::ERROR to contain
    the reason why.

- valid\_chars LIST

    By default this module only recognizes 0..9 as valid characters, but sometimes
    you want to consider other characters as valid, e.g. Standard & Poor's
    identifers may contain 0..9, A..Z, @, #, \*. This function allows you to add
    additional characters to the accepted list.

    LIST is a mapping of `character` => `value`.
    For example, Standard & Poor's maps A..Z to 10..35
    so the LIST to add these valid characters would be (A, 10, B, 11, C, 12, ...)

    Please note that this _adds_ or _re-maps_ characters, so any characters
    already considered valid but not in LIST will remain valid.

    If you do not provide LIST,
    this function returns the current valid character map.

# SEE ALSO

[Algorithm::LUHN](https://metacpan.org/pod/Algorithm::LUHN) is the original pure perl module this is based on.

[Algorithm::CheckDigits](https://metacpan.org/pod/Algorithm::CheckDigits) provides a front-end to a large collection
of modules for working with check digits.

[Business::CreditCard](https://metacpan.org/pod/Business::CreditCard) provides three functions for checking credit
card numbers. [Business::CreditCard::Object](https://metacpan.org/pod/Business::CreditCard::Object) provides an OO interface
to those functions.

[Business::CardInfo](https://metacpan.org/pod/Business::CardInfo) provides a class for holding credit card details,
and has a type constraint on the card number, to ensure it passes the
LUHN check.

[Business::CCCheck](https://metacpan.org/pod/Business::CCCheck) provides a number of functions for checking
credit card numbers.

[Regexp::Common](https://metacpan.org/pod/Regexp::Common) supports combined LUHN and issuer checking
against a card number.

[Algorithm::Damm](https://metacpan.org/pod/Algorithm::Damm) implements a different kind of check digit algorithm,
the [Damm algorithm](https://en.wikipedia.org/wiki/Damm_algorithm)
(Damm, not Damn).

[Math::CheckDigits](https://metacpan.org/pod/Math::CheckDigits) implements yet another approach to check digits.

Tim Ayers has also written a
[review of LUHN modules](http://neilb.org/reviews/luhn.html),
which covers them in more detail than this section.

# REPOSITORY

[https://github.com/krschwab/Algorithm-LUHN\_XS](https://github.com/krschwab/Algorithm-LUHN_XS)

# AUTHOR

This module was written by
Kerry Schwab (http://search.cpan.org/search?author=KSCHWAB).

# COPYRIGHT

Copyright (c) 2018 Kerry Schwab. All rights reserved.
Derived from Algorithm::LUHN, which is (c) 2001 by Tim Ayers.

# LICENSE

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

# CREDITS

Tim Ayers, for the original pure perl version of Algorithm::LUHN

The inspiration for this module was a PerlMonks post I made here:
[https://perlmonks.org/?node\_id=1226543](https://perlmonks.org/?node_id=1226543), and I received help 
from several PerlMonks members:

    [AnomalousMonk](https://perlmonks.org/?node_id=634253)

    [BrowserUK](https://perlmonks.org/?node_id=171588)

    [Corion](https://perlmonks.org/?node_id=5348)

    [LanX](https://perlmonks.org/?node_id=708738)

    [tybalt89](https://perlmonks.org/?node_id=1172229)
