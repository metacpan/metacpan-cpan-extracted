package Aspect::Library::Trace;

use 5.006;
use strict;
use warnings;
use Aspect            1.00 ();
use Aspect::Modular        ();
use Aspect::Advice::Around ();

use vars qw{$VERSION @ISA};
BEGIN {
	$VERSION = '1.00';
	@ISA     = 'Aspect::Modular';
}

sub import {
	my $class = shift;

	if ( ref($_[0]) eq 'Regexp' ) {
		Aspect::aspect( Trace => Aspect::call($_[0]) );
	}

	return 1;
}

sub get_advice {
	my $depth = 0;
	Aspect::Advice::Around->new(
		lexical  => $_[0]->lexical,
		pointcut => $_[1],
		code     => sub {
			print STDERR '  ' x $depth++ . $_[0]->sub_name . "\n";
			$_[0]->proceed;
			$depth--;
		},
	);
}

1;

__END__

=pod

=head1 NAME

Aspect::Library::Trace - Aspect-oriented function call tracing

=head1 SYNOPSIS

  use Aspect;
  use Aspect::Library::Trace;
  
  aspect Trace => call qr/^Foo::/;
  
  Foo::foo1
    Foo::foo2
      Foo::foo3
  Foo::foo2
    Foo::foo3
  Foo::foo2
    Foo::foo3

=head1 DESCRIPTION

B<L<Aspect> Oriented Programming> is a programming paradigm that increases
modularity by enabling improved separation of concerns.

It is most useful when dealing with cross-cutting concerns that would
otherwise require code to be scattered around in many places.

B<Aspect::Library::Trace> is an L<Aspect> library that implements nested
functional call tracing, in the style formerly offered by the C<dprofpp -T>
command provided by L<Devel::DProf> (before that module became unusable).

=head2 Conventional Usage

The basic usage is very simple, just create an C<Trace> aspect as shown
in the L</SYNOPSIS>.

Load Aspect, then Aspect::Library::Trace, then create the aspect using
the C<aspect> function.

Any calls to functions described in the pointcut will be printed to
C<STDERR>. Nesting is indicated via indenting.

Because the depth is tracked at a per-Aspect level, you should avoid
creating more than one trace Aspect or the indenting levels will be
mixed up and the output will become largely meaningless.

=head2 Import Usage

For even more convenience (and even less typing) you can use the
following shorthand 1-line form.

  use Aspect::Library::Trace qr/^Module::/;

When used this way, you also don't need to C<use Aspect>.

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Aspect-Library-Trace>

For other issues, contact the author.

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 SEE ALSO

L<Aspect>

=head1 COPYRIGHT

Copyright 2009 - 2011 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
