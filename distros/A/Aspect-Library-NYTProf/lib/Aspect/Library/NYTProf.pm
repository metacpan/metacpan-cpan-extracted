package Aspect::Library::NYTProf;

use 5.008002;
use strict;
use warnings;
use Devel::NYTProf    3.01 ();
use Aspect::Modular   1.00 ();
use Aspect::Advice::Around ();

our $VERSION = '1.00';
our @ISA     = 'Aspect::Modular';
our $DEPTH   = 0;

sub get_advice {
	Aspect::Advice::Around->new(
		lexical  => $_[0]->lexical,
		pointcut => $_[1],
		code     => sub {
			DB::enable_profile() unless $DEPTH++;
			$_->proceed;
			DB::disable_profile() unless --$DEPTH;
		},
	);
}

END {
	DB::finish_profile();
}

1;

__END__

=pod

=head1 NAME

Aspect::Library::NYTProf - Allows pointcut-targetted NYTProf profiling

=head1 SYNOPSIS

  # Only profile code that runs in constructors
  use Aspect;
  aspect NYTProf => call qr/::new$/;
  
  # Using this profile pattern from the command line
  NYTPROF=start=no perl -d:NYTProf script.pl

=head1 DESCRIPTION

B<Aspect::Library::NYTProf> provides a pre-built L<Aspect> library for doing
L<Devel::NYTProf> profiling on a targetted subset of your application.

This is implemented using the built-in C<DB::enable_profile()> and
C<DB::disable_profile()> functions you might normally use with
L<Devel::NYTProf>, but allows for targetting the profiling using the full
range of pointcuts available in L<Aspect>.

For example, the following allows profiling of C<Foo::bar()>, but B<only>
when called in scalar context.

  aspect NYTProf => call 'Foo::bar' & wantscalar;

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Aspect-Library-NYTProf>

For other issues, contact the author.

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 SEE ALSO

L<Aspect>, L<Aspect::Library::Profiler>

=head1 COPYRIGHT

Copyright 2010 - 2011 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
