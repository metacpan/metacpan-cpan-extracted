# Business-CompanyDesignator

Business::CompanyDesignator is a perl module for matching and
stripping company designators (like Limited, Ltd., LLC, GmbH, etc.)
appended to company names.

It uses the company designator dataset from here:

  <https://github.com/ProfoundNetworks/company_designator>

which is bundled with the module. You can use your own (updated or custom)
version, if you prefer.

## INSTALLATION

To install this module, run the following commands:

        perl Makefile.PL
        make
        make test
        make install


## SUPPORT AND DOCUMENTATION

After installing, you can find documentation for this module with the
perldoc command.

    perldoc Business::CompanyDesignator
    perldoc Business::CompanyDesignator::Record


## LICENSE AND COPYRIGHT

Copyright (C) 2013-2019 Gavin Carr.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

