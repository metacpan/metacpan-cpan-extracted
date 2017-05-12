package Aspect::Library::Timer;

use 5.008002;
use strict;
use warnings;
use Aspect::Modular 1.00 ();
use Time::HiRes   1.9718 ();

use vars qw{$VERSION @ISA};
BEGIN {
	$VERSION = '1.10';
	@ISA     = 'Aspect::Modular';
}

sub get_advice {
	my $self     = shift;
	my $pointcut = shift;
	my $handler  = @_ ? shift : \&handler;
	my $DISABLE  = 0;
	Aspect::Advice::Around->new(
		lexical  => $self->lexical,
		pointcut => $pointcut,
		code     => sub {
			# Prevent recursion in the report handler
			if ( $DISABLE ) {
				$_->proceed;
				return;
			}

			# Capture the time
			my $error = '';
			SCOPE: {
				local $@;
				my @start = Time::HiRes::gettimeofday();
				eval {
					$_->proceed;
				};
				$error = $@;
				my @stop  = Time::HiRes::gettimeofday();

				# Process the time
				$DISABLE++;
				eval {
					$handler->(
						$_->sub_name,
						\@start,
						\@stop,
						Time::HiRes::tv_interval(
							\@start,
							\@stop,
						)
					);
				};
				$DISABLE--;
			}

			die $error if $error;
			return;
		},
	);
}

sub handler {
	my ( $name, $start, $stop, $interval ) = @_;
	printf STDERR "%s - %s\n", $interval, $name;
}

1;

__END__

=pod

=head1 NAME

Aspect::Library::Timer - Predefined timer pointcut

=head1 SYNOPSIS

  use Aspect;
  
  aspect Timer => call qr/^Foo::/;

  Foo::bar();
  
  package Foo;
  
  sub bar {
      sleep 1;
  }

=head1 DESCRIPTION

C<Aspect::Library::Timer> provides support for simple timers aspects.

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Aspect-Library-Timer>

For other issues, contact the author.

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 SEE ALSO

L<Aspect>, L<Aspect::Library::ZoneTimer>

=head1 COPYRIGHT

Copyright 2009 - 2012 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
