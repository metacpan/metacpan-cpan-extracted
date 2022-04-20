# pdfolay - insert a PDF document over/under another document

A.k.a. `App::PDF::Overlay`

This program will read the given input PDF file(s) and copy them
into a new output document.

Optionally, an overlay PDF document can be specified. If so, the pages
of the overlay document are inserted over (or, with option
--behind, behind) the pages of the source documents.

## Installation

To install this module, run the following commands:

	perl Makefile.PL
	make
	make test
	make install

## Support and Documentation

Development of this module takes place on GitHub:
https://github.com/sciurius/pdfolay.

You can find documentation for this module with the perldoc command.

    perldoc App::PDF::Overlay

or

    pdfolay --man

Please report any bugs or feature requests using the issue tracker on
GitHub.

## Copyright and Licence

Copyright (C) 2022 Johan Vromans

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

