# NAME

Acme::AjiFry - AjiFry Language (アジフライ語) Translator



# VERSION

This document describes Acme::AjiFry version 0.09



# SYNOPSIS

    use Acme::AjiFry;

    my $ajifry = Acme::AjiFry->new();

    print $ajifry->to_AjiFry('おさしみ')."\n"; # outputs => "食えアジフライお刺身食え食えお刺身ドボドボ岡星ドボドボ"
    print $ajifry->to_Japanese('食えアジフライお刺身食え食えお刺身ドボドボ岡星ドボドボ')."\n"; # outputs => "おさしみ"



# DESCRIPTION

Acme::AjiFry is the AjiFry-Language translator.
This module can translate Japanese into AjiFry-Language, and vice versa.
If you would like to know about AjiFry-Language, please refer to the following web site (Japanese Web Site).
[http://ja.uncyclopedia.info/wiki/%E3%82%A2%E3%82%B8%E3%83%95%E3%83%A9%E3%82%A4%E8%AA%9E](http://ja.uncyclopedia.info/wiki/%E3%82%A2%E3%82%B8%E3%83%95%E3%83%A9%E3%82%A4%E8%AA%9E)

# METHODS

- new

    new is the constructor of this module.

- to\_Japanese

    This function needs a AjiFry-Language string as parameter.
    It returns Japanese which was translated from AjiFry-Language.

- to\_AjiFry

    This function needs a string as parameter.
    It returns AjiFry-Language which was translated from Japanese.

# DEPENDENCIES

- Encode (version 2.39 or later)



# BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
`bug-acme-ajifry@rt.cpan.org`, or through the web interface at
[http://rt.cpan.org](http://rt.cpan.org).



# AUTHOR

moznion  `<moznion[at]gmail.com>`



# LICENCE AND COPYRIGHT

Copyright (c) 2012, moznion `<moznion[at]gmail.com>`. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See [perlartistic](http://search.cpan.org/perldoc?perlartistic).
