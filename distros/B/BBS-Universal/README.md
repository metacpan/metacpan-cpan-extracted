# BBS::Universal

![BBS::Universal Logo](files/files/BBS/BBS_Universal.png?raw=true "BBS::Universal")

A Perl based TCP-IP BBS catering to retro computers and that modem experience.

Installing is at your own risk and likely will not be very useful to you at the moment, but if you want to track progress, then go ahead.

## INSTALLING

```bash
        perl Makefile.PL
        make
        make test
 [sudo] make install
        make veryclean
```

You will need a properly configured MySQL server.  You also need to modify the "conf/bbs.rc" to reflect your MySQL installation (including account) and make sure the file is not world readable.  You also need to run the "sql/database_setup.sql" file in mysql:

```bash
        sudo mysql -u root --skip-password < sql/database_setup.sql
```

You can use the default menu files or change them to your own taste.  See the manual for details.

## DESCRIPTION

A 100% Perl BBS server.  It supports ASCII, ANSI, ATASCII and PETSCII text formats.

* NOTE:  This is still a work in progress.  The ASCII and ANSI features work fine.  ATASCII and PETSCII have not yet been refined and tested.  Also, file upload/download has not been tested.

## CONFIGURATION

The system requires a very minimal static configuration file to give access to the database.  The rest of the configuration is stored in the database.

The file **conf/bbs.rc** :

```
# Minimum Configuration for BBS Universal.  Only Database info goes here.
# The rest resides in the Database.  Comments and empty lines are ignored
# Make this file belong only to you via "chmod 600".

# Change the username and password to whatever you set your account to.

DATABASE NAME     = BBSUniversal
DATABASE TYPE     = mysql
DATABASE USERNAME = bbssystem
DATABASE PASSWORD = bbspass
DATABASE HOSTNAME = localhost
DATABASE PORT     = 3306
```

## LICENSE AND COPYRIGHT

Copyright © 2023-2026 Richard Kelsch

This program is free software; you can redistribute it and/or modify it under the terms of the Perl Artistic License.

