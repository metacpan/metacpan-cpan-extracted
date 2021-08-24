# NAME

Data::Validate::Domain - Domain and host name validation

# VERSION

version 0.15

# SYNOPSIS

    use Data::Validate::Domain qw(is_domain);

    # as a function
    my $test = is_domain($suspect);
    die "$test is not a domain" unless $test;

    # or

    die "$test is not a domain" unless is_domain($suspect, \%options);

    # or as an object
    my $v = Data::Validate::Domain->new(%options);

    die "$test is not a domain" unless $v->is_domain($suspect);

# DESCRIPTION

This module offers a few subroutines for validating domain and host names.

# FUNCTIONS

All of the functions below are exported by default.

All of the functions return an untainted value on success and a false value
(`undef` or an empty list) on failure. In scalar context, you should check
that the return value is defined, because something like
`is_domain_label('0')` will return a defined but false value.

The value to test is always the first (and often only) argument.

Note that none of these functions test whether a domain or hostname is actually
resolvable or reachable.

## Data::Validate::Domain->new()

This method constructs a validation object. It accepts the following arguments:

- domain\_allow\_underscore

    According to RFC underscores are forbidden in hostnames but not domain names.
    By default `is_domain()`, `is_domain_label()`, and `is_hostname()` will fail
    if the value to be checked includes underscores. Setting this to a true value
    will allow the use of underscores in all functions.

- domain\_allow\_single\_label

    By default `is_domain()` will fail if you ask it to verify a domain that only
    has a single label i.e. "neely.cx" is good, but "com" would fail. If you set
    this option to a true value then `is_domain()` will allow single label domains
    through. This is most likely to be useful in combination with the
    `domain_private_tld` argument.

- domain\_disable\_tld\_validation

    Disables TLD validation for `is_domain()`. This may be useful if you need to
    check domains with new gTLDs that have not yet been added to
    [Net::Domain::TLD](https://metacpan.org/pod/Net%3A%3ADomain%3A%3ATLD).

- domain\_private\_tld

    By default `is_domain()` requires all domains to have a valid public TLD (i.e.
    com, net, org, uk, etc). This is verified using the [Net::Domain::TLD](https://metacpan.org/pod/Net%3A%3ADomain%3A%3ATLD) module.
    This behavior can be extended in two different ways. You can provide either a
    hash reference where additional TLDs are keys or you can supply a regular
    expression.

    NOTE: The TLD is normalized to the lower case form prior to the check being
    done. This is done only for the TLD check, and does not alter the output in any
    way.

    Hashref example:

        domain_private_tld => {
            privatetld1 => 1,
            privatetld2 => 1,
        }

    Regular expression example:

        domain_private_tld => qr /^(?:privatetld1|privatetld2)$/,

## is\_domain($domain, \\%options)

This can be called as either a subroutine or a method. If called as a sub, you
can pass any of the arguments accepted by the constructor as options. If called
as a method, any additional options are ignored.

This returns the untainted domain name if the given `$domain` is a valid
domain.

A dotted quad (such as 127.0.0.1) is not considered a domain and will return
false. See [Data::Validate::IP](https://metacpan.org/pod/Data%3A%3AValidate%3A%3AIP) for IP Validation.

Per RFC 1035, this sub does accept a value ending in a single period (i.e.
"domain.com.") to be a valid domain. This is called an absolute domain name,
and should be properly resolved by any DNS tool (tested with `dig`, `ssh`,
and [Net::DNS](https://metacpan.org/pod/Net%3A%3ADNS)).

- _From RFC 952_

        A "name" (Net, Host, Gateway, or Domain name) is a text string up
        to 24 characters drawn from the alphabet (A-Z), digits (0-9), minus
        sign (-), and period (.). Note that periods are only allowed when
        they serve to delimit components of "domain style names".

        No blank or space characters are permitted as part of a
        name. No distinction is made between upper and lower case. The first
        character must be an alpha character [Relaxed in RFC 1123] . The last
        character must not be a minus sign or period.

- _From RFC 1035_

        labels          63 octets or less
        names           255 octets or less

        [snip] limit the label to 63 octets or less.

        To simplify implementations, the total length of a domain name (i.e.,
        label octets and label length octets) is restricted to 255 octets or
        less.

- _From RFC 1123_

        One aspect of host name syntax is hereby changed: the
        restriction on the first character is relaxed to allow either a
        letter or a digit. Host software MUST support this more liberal
        syntax.

        Host software MUST handle host names of up to 63 characters and
        SHOULD handle host names of up to 255 characters.

## is\_hostname($hostname, \\%options)

This can be called as either a subroutine or a method. If called as a sub, you
can pass any of the arguments accepted by the constructor as options. If called
as a method, any additional options are ignored.

This returns the untainted hostname if the given `$hostname` is a valid
hostname.

Hostnames are not required to end in a valid TLD.

## is\_domain\_label($label, \\%options)

This can be called as either a subroutine or a method. If called as a sub, you
can pass any of the arguments accepted by the constructor as options. If called
as a method, any additional options are ignored.

This returns the untainted label if the given `$label` is a valid label.

A domain label is simply a single piece of a domain or hostname. For example,
the "www.foo.com" hostname contains the labels "www", "foo", and "com".

# SEE ALSO

**\[RFC 1034\] \[RFC 1035\] \[RFC 2181\] \[RFC 1123\]**

- [Data::Validate](https://metacpan.org/pod/Data%3A%3AValidate)
- [Data::Validate::IP](https://metacpan.org/pod/Data%3A%3AValidate%3A%3AIP)

# ACKNOWLEDGEMENTS

Thanks to Richard Sonnen <`sonnen@richardsonnen.com`> for writing the
Data::Validate module.

Thanks to Len Reed <`lreed@levanta.com`> for helping develop the options
mechanism for Data::Validate modules.

# SUPPORT

Bugs may be submitted at [https://github.com/houseabsolute/Data-Validate-Domain/issues](https://github.com/houseabsolute/Data-Validate-Domain/issues).

I am also usually active on IRC as 'autarch' on `irc://irc.perl.org`.

# SOURCE

The source code repository for Data-Validate-Domain can be found at [https://github.com/houseabsolute/Data-Validate-Domain](https://github.com/houseabsolute/Data-Validate-Domain).

# AUTHORS

- Neil Neely <neil@neely.cx>
- Dave Rolsky <autarch@urth.org>

# CONTRIBUTORS

- Anirvan Chatterjee <anirvan@users.noreply.github.com>
- David Steinbrunner <dsteinbrunner@pobox.com>
- Felipe Gasper <felipe@felipegasper.com>
- Gregory Oschwald <goschwald@maxmind.com>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Neil Neely.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

The full text of the license can be found in the
`LICENSE` file included with this distribution.
