Acme::Chef ![Travis CI Build Status](https://travis-ci.org/mpw96/perl-Acme-Chef.svg?branch=master)
==========
Acme::Chef and all contained modules represent a simple
interpreter of the [Chef programming language](http://www.dangermouse.net/esoteric/chef.html) designed by
David Morgan-Mar.

Installation
------------
To install this module type the following:

    perl Build.PL
    ./Build
    ./Build test
    ./Build install

On platforms that don't support the "./" notation, that would be:

    perl Build.PL
    perl Build
    perl Build test
    perl Build install

Dependencies
------------
This module requires these other modules and libraries:

* File::Temp
* Test::More

See also
--------
The source code for Acme::Chef lives at GitHub:
  https://github.com/mpw96/perl-Acme-Chef

For suggestions, inquiries and feedback please or create an [issue](https://github.com/mpw96/perl-Acme-Chef/issues).

Copyright and license
---------------------
Copyright (c) 2002-2008 Steffen Mueller

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
