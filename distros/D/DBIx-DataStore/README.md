# DBIx::DataStore

## IMPORTANT NOTICE

This is the legacy release of DBIx::DataStore and has a low chance of seeing
future (non-critical bug fix) releases. It is being published for the primary
purpose of easing the maintenance of existing installations.

Future versions of this module will make attempts to maintain as much backwards
compatibility as possible, but there are no guarantees that every feature or
method will carry over unchanged from the user perspective. It is recommended
that if you do build something around this module that you pin to pre-1.0
versions. A future release which breaks functionality with what is presented
here will begin with a new major version.

This code has been in heavy production use at multiple companies for almost
fifteen years and is considered pretty (though not perfectly) stable. You are
welcome to make use of it, in the form presented here, in your own projects.
Significant feature requests for this version will likely be met with a
somewhat low priority, and development of new applications or libraries with it
is not strongly encouraged.

Critical security and bug fix requests will be reviewed.

## INSTALLATION

To install this module, run the following commands:

    perl Makefile.PL
    make
    make test
    make install


## SUPPORT AND DOCUMENTATION

After installing, you can find documentation for this module with perldoc.

    perldoc DBIx::DataStore

You can also look for information at:

    GitHub
        http://github.com/jsime/dbix-datastore-legacy

## COPYRIGHT AND LICENSE

Copyright (C) 2007 Jon Sime, Buddy Burden
Portions Copyright (C) 2002-2003 Barefoot Software

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
