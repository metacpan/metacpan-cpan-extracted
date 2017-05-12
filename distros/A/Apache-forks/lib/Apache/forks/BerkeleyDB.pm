package Apache::forks::BerkeleyDB;

$VERSION = 0.03;

use strict;
use warnings;
use Carp ();
use vars qw(@ISA);

use constant BASE => 'forks::BerkeleyDB';

BEGIN {
	@ISA = qw(Apache::forks::Common);
	require Apache::forks::Common;

	{
		no warnings 'redefine';
		*debug = *debug = \&Apache::forks::Common::debug;
		*childinit = *childinit = \&Apache::forks::Common::childinit;
	}

	__PACKAGE__->_load_forks();
}


package
	Apache::forks::BerkeleyDB::shared;	# hide from PAUSE

use vars qw(@ISA);
BEGIN {
	@ISA = qw(Apache::forks::Common);
}
use constant BASE => 'forks::BerkeleyDB::shared';

sub import {
	shift;
	_forks_shared->import(@_);
}

1;

__END__

=pod

=head1 NAME

Apache::forks::BerkeleyDB - Transparent Apache ithreads integration using forks::BerkeleyDB

=head1 VERSION

This documentation describes version 0.03.

=head1 SYNOPSIS

 # Configuration in httpd.conf

 PerlModule Apache::forks::BerkeleyDB  # this should come before all other modules!

Do NOT change anything in your scripts. The usage of this module is transparent.

=head1 DESCRIPTION

Transparent Apache ithreads integration using forks::BerkeleyDB.  This module enables the
ithreads API to be used among multiple processes in a pre-forking Apache http
environment.

=head1 USAGE

The module should be loaded upon startup of the Apache daemon.  You must be
using at least Apache httpd 1.3.0 or 2.0 for this module to work correctly.

Add the following line to your httpd.conf:

 PerlModule Apache::forks::BerkeleyDB

or the following to the first PerlRequire script (i.e. startup.pl):

 use Apache::forks::BerkeleyDB;

It is very important to load this module before all other perl modules!

A Common usage is to load the module in a startup file via the PerlRequire
directive. See eg/startup.pl in this distribution.  In this case, be sure
that the module is first to load in the startup script, and that the
PerlRequre directive to load the startup script is the first mod_perl directive
in your httpd.conf file.

=head1 NOTES

See L<Apache::forks> for more information.

=head1 TODO

=head1 CAVIATS

=head1 BUGS

=head1 AUTHOR

Eric Rybski, <rybskej@yahoo.com>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2007-2008 Eric Rybski <rybskej@yahoo.com>.
All rights reserved.  This program is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<Apache::forks>, L<forks::BerkeleyDB>, L<forks::BerkeleyDB::shared>.

=cut
