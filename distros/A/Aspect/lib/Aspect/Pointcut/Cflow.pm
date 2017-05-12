package Aspect::Pointcut::Cflow;

use strict;
use Carp                   ();
use Params::Util           ();
use Aspect::Pointcut       ();
use Aspect::Pointcut::Call ();
use Aspect::Point::Static  ();

our $VERSION = '1.04';
our @ISA     = 'Aspect::Pointcut';

use constant KEY  => 0;
use constant SPEC => 2;





######################################################################
# Constructor Methods

sub new {
	my $class = shift;

	# Check and default the cflow key
	my $key = @_ > 1 ? shift : 'enclosing';
	unless ( Params::Util::_IDENTIFIER($key) ) {
		Carp::croak('Invalid runtime context key');
	}

	# Generate it via call
	my $call = Aspect::Pointcut::Call->new(shift);
	return bless [ $key, @$call ], $class;
}





######################################################################
# Weaving Methods

# The cflow pointcut is currently of no value at weave time, because it is
# actually implemented as something closer to cflowbelow.
sub curry_weave {
	return;
}

# The cflow pointcuts do not curry at all.
# So they don't need to clone, and can be used directly.
sub curry_runtime {
	return $_[0];
}





######################################################################
# Runtime Methods

sub compile_runtime {
	my $self = shift;
	return sub {
		my $level   = 2;
		my $caller  = undef;
		while ( my $cc = caller_info($level++) ) {
			next unless $self->[SPEC]->( $cc->{sub_name} );
			$caller = $cc;
			last;
		}
		return 0 unless $caller;
		my $static = bless {
			sub_name => $caller->{sub_name},
			pointcut => $Aspect::POINT->{pointcut},
			args     => $caller->{args},
		}, 'Aspect::Point::Static';
		$Aspect::POINT->{$self->[KEY]} = $static;
		return 1;
	};
}

sub caller_info {
	my $level = shift;

	package DB;

	my %call_info;
	@call_info{ qw(
		calling_package
		sub_name
		has_params
	) } = (CORE::caller($level))[0, 3, 4];

	return defined $call_info{calling_package}
		? {
			%call_info,
			args => [
				$call_info{has_params} ? @DB::args : ()
			],
		} : 0;
}

1;

__END__

=pod

=head1 NAME

Aspect::Pointcut::Cflow - Cflow pointcut

=head1 SYNOPSIS

  Aspect::Pointcut::Cflow->new;

=head1 DESCRIPTION

None yet.

=head1 AUTHORS

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

Marcel GrE<uuml>nauer E<lt>marcel@cpan.orgE<gt>

Ran Eilam E<lt>eilara@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2001 by Marcel GrE<uuml>nauer

Some parts copyright 2009 - 2013 Adam Kennedy.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
