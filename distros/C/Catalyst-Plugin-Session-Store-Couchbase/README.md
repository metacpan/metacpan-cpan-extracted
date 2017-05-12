OVERVIEW
========

This is a Catalyst plugin to allow sessions to be stored in a Couchbase
instance.

SYNOPSIS
========

      use Catalyst qw{Session Session::Store::Couchbase Session::State::Cookie};
      MyApp->config(
        'Plugin::Session' => {
          expires => 7200,
        },
        Couchbase => {
          server => 'couchbase01.domain',
          username => 'Administrator',
          password => 'password',
          bucket => 'default',
        }
      );


You can find full documentation for this module with the perldoc command.

    perldoc Catalyst::Plugin::Session::Store::Couchbase

ACKNOWLEDGEMENTS
================

    This module was supported by Strategic Data. The module was originally
    written for their internal use, and the company has allowed me to
    produce an open-source version.

LICENSE AND COPYRIGHT
=====================

    Copyright 2013 Toby Corkindale.

    This program is free software; you can redistribute it and/or modify it
    under the terms of either: the GNU General Public License as published
    by the Free Software Foundation; or the Artistic License.

    See http://dev.perl.org/licenses/ for more information.

