#!/usr/local/bin/perl

use inc::Module::Install;

name        ('Apache-Session-SQLite3');
author      ('Autrijus Tang <autrijus@autrijus.org>');
abstract    ('Use DBD::SQLite 1.x for Apache::Session storage');
license	    ('perl');
version_from('lib/Apache/Session/SQLite3.pm');
requires    (qw(
    DBD::SQLite     1.00
    Apache::Session 0.15
));
WriteAll    ( sign => 1 );
