package Acme::Everything;

# A _huge_ amount of work went into making sure Class::Autouse handles
# pretty much every corner case properly, so we'll just hook into it,
# rather than writing our own autoload code.
use 5.006;
use strict;
use Class::Autouse ':superloader';

our $VERSION = '1.01';

# Define our replacement load method
sub _load {
	# We'll try to do this the normal way once,
	# and if that doesn't work, we'll bring CPANPLUS into it.
	eval { $_ = Class::Autouse::__load( @_ ) };

	# We only care if we couldn't find the class
	return $_ unless $@;
	die $@ unless $@ =~ /^Can't locate /;

	# Try to install the module, and then call __load again.
	# But this time, don't catch errors.
	require CPANPLUS;
	CPANPLUS::install( $_[0] );
	Class::Autouse::__load( @_ );
}

# Replace Class::Autouse's version with ours
*Class::Autouse::__load = *Class::Autouse::_load;
*Class::Autouse::_load  = *_load;

1;

__END__

=head1 NAME

Acme::Everything - Effectively loads every class in CPAN

=head1 SYNOPSIS

    use Acme::Everything;

    Any::Module->any_method;

=head1 DESCRIPTION

B<Acme::Everything> is the ultimate run-time loader. With one 'use' line,
you effectively load all 20,000,000 odd lines of code in CPAN.

Run ANY method in ANY class, and Acme::Everything will download and/or
load the module as needed at runtime, including its recursive installation
dependencies, and every class all the way up the @ISA path as needed.

For all of this, Acme::Everything is implemented in only 13 lines of code,
by using CPANPLUS and linking parasitically into Class::Autouse 'superloader'.

The only restriction is that Acme::Everything will ONLY work when calling as a
method. Calling as a function will not cause the magic to happen.

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Acme-Everything>

For other issues, or commercial enhancement or support, contact the author.

=head1 AUTHORS

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 SEE ALSO

L<Class::Autouse>, L<CPANPLUS>, L<http://ali.as/>

=head1 COPYRIGHT

Copyright 2002 - 2006 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
