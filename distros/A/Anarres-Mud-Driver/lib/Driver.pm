package Anarres::Mud::Driver;

use strict;
use warnings;
use Anarres::Mud::Driver::Compiler;

BEGIN {
	use strict;
	use vars qw($VERSION @ISA @EXPORT_OK %EXPORT_TAGS);
	use Exporter;

	$VERSION     = '0.26';
	@ISA         = qw(Exporter);
	@EXPORT_OK   = ();
	%EXPORT_TAGS = ();
}

=head1 NAME

Anarres::Mud::Driver - A game driver for LP Muds.

=head1 SYNOPSIS

  use Anarres::Mud::Driver;

=head1 DESCRIPTION

This is an EXPERIMENTAL LP Mud driver written in Perl. The principle
is to parse the LPC as would a traditional driver, build and typecheck
a parse tree, then generate Perl source code from the parse tree. More
traditional drivers would here generate and interpret bytecode.

Generated Perl code is in a package namespace generated from the LPC
filename of the object to be compiled.

This program contains some interesting curiosities, such as an
emulation for a full 'C' style switch statement in Perl.

=head1 USAGE

The system is developer only and the interface changes quite rapidly.
A good place to start is probably reading the test files. For more
information, see 'SUPPORT' below.

=head1 BUGS

Incomplete. Experimental. Probably broken.

=head1 SUPPORT

Speak to Arren on the Anarres II LP mud (telnet mudlib.anarres.org
5000)

=head1 AUTHOR

	Shevek
	CPAN ID: SHEVEK
	cpan@anarres.org
	http://www.anarres.org/projects/

=head1 COPYRIGHT

Copyright (c) 2002 Shevek. All rights reserved.
This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=head1 SEE ALSO

perl(1).

=cut

1;
__END__
