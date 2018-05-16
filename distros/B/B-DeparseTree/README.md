[![Build Status](https://travis-ci.org/rocky/p5-B-DeparseTree.png)](https://travis-ci.org/rocky/p5-B-DeparseTree)

SYNOPSIS
--------

Perl's B::Deparse but we save abstract tree information and associate
that with Perl text fragments.  These are fragments accessible by OP
address. With this, you can determine get exactly where you inside Perl in
a program with granularity finer that at a line number boundary.

Uses for this could be in stack trace routines like _Carp_. It is used
in the [deparse](https://metacpan.org/pod/Devel::Trepan::Deparse)
command extension to
[Devel::Trepan](https://metacpan.org/pod/Devel::Trepan).

See [Exact Perl location with B::Deparse (and Devel::Callsite)](http://blogs.perl.org/users/rockyb/2015/11/exact-perl-location-with-bdeparse-and-develcallsite.html).

INSTALLATION
------------

Currently we only support Perl 5.18, 5.20, 5.22, 5.24 and 5.26.

To install this Devel::Trepan, run the following commands:

	perl Build.PL
	make
	make test
	[sudo] make install

LICENSE AND COPYRIGHT
---------------------

Copyright (C) 2015, 2017, 2018 Rocky Bernstein <rocky@cpan.org>
