[![CPAN version](https://badge.fury.io/pl/CPAN-Plugin-Sysdeps.svg)](http://badge.fury.io/pl/CPAN-Plugin-Sysdeps)
[![Build Status](https://github.com/eserte/cpan-plugin-sysdeps/actions/workflows/test.yml/badge.svg)](https://github.com/eserte/cpan-plugin-sysdeps/actions/workflows/test.yml)
[![Appveyor](https://ci.appveyor.com/api/projects/status/github/eserte/cpan-plugin-sysdeps?branch=master&svg=true)](https://ci.appveyor.com/project/eserte/cpan-plugin-sysdeps/branch/master)

CPAN-Plugin-Sysdeps
===================

CPAN::Plugin::Sysdeps is a CPAN.pm plugin for automatic installation
of non-CPAN dependencies, usually through the operating system's
package manager.

CPAN.pm plugin support exists since version 2.07 and is currently marked as experimental.

After installation of this module (the standard perl way --- `perl Makefile.PL && make all test install`), you can configure CPAN.pm to use this plugin:

    $ cpan
    cpan> o conf plugin_list push CPAN::Plugin::Sysdeps
    cpan> o conf commit
    
It's also possible to use the knowledge provided by CPAN::Plugin::Sysdeps using the script cpan-sysdeps.

Author: Slaven Rezić
