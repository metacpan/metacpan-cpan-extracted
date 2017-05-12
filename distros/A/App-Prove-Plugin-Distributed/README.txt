App-Prove-Plugin-Distributed version 0.01
=========================================

App-Prove-Plugin-Distributed is a plugin for App::Prove to distribute jobs to multiple workers (servers).

SYNOPSIS
  
   # Using the default IPC::Open3 processes as workers
   prove -PDistributed -j5 t/*

   # Using the LSF jobs as workers
   prove -PDistributed --distributed-type=LSF -j5 t/*

INSTALLATION

To install this module type the following:

   perl Makefile.PL
   make
   make test
   make install

DEPENDENCIES

This module requires these other modules and libraries:

   Carp
   Cwd
   Getopt::Long
   IO::Select
   IO::Socket::INET
   Sys::Hostname
   Test::More

SUPPORT

Bug reports and suggestions for improvements can be sent to
<lsf@cpan.org> or at github <https://github.com/shin82008/App-Prove-Plugin-Distributed/>.

COPYRIGHT AND LICENCE

  © 2012 Shin Leong. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.12.4 or,
at your option, any later version of Perl 5 you may have available.


