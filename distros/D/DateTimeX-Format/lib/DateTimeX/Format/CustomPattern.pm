package DateTimeX::Format::CustomPattern;
use Moose::Role;

use strict;
use warnings;

use Carp;

use namespace::clean -except => 'meta';

has 'pattern' => (
	isa         => 'Maybe[Str]'
	, is        => 'rw'
	, required  => 1
	, predicate => 'has_pattern'
);

around 'parse_datetime' => sub {
	my ( $sub, $self, $time, $env, @args ) = @_;

	croak "The key 'override' is not present in the env HashRef"
		unless exists $env->{override}
	;
	croak '"time" is a required argument "time" for ->parse_datetime($time ...);'
		unless defined $time;
	;

	## Set Pattern: from args, then from object
	my $pattern;
	if ( defined $env->{override}{pattern} ) {
		$pattern = $env->{override}{pattern}
	}
	elsif ( $self->has_pattern ) {
		$pattern = $self->pattern;
	}
	else {
		croak "No pattern supplied to constructor or the call to parse_datetime"
	}

	$env->{ pattern } = $pattern;
	
	## Calls the sub ( time, env, addtl args )
	my $dt = $self->$sub( $time , $env , @args );

};

## KEEP IT HERE -- Roles in this care *ARE* order specific
with 'DateTimeX::Format';

1;

__END__

=head1 NAME

DateTimeX::Format::CustomPattern - A Moose::Role for building DateTime Formats that require patterns

=head1 DESCRIPTION

It adds an attribute "pattern", and behavies consistant with the call-overriding environment of L<DateTimeX::Format>.

=head1 SYNOPSIS
	
	package DateTimeX::Format::RequiresPattern;
	use Moose;
	with 'DateTimeX::Format::CustomPattern';

	package main;

	my $dt = DateTimeX::Format::RequiresPattern->new({
		locale       => $locale
		, time_zone  => $timezone
		, pattern    => '%H:%M:%S'
		, debug      => 0|1
		, defaults   => 0|1
	});

	$dt->parse_datetime( $time, {pattern => '%H:%M'} );

=head1 OBJECT ENVIRONMENT

All of these slots correspond to your object environment: they can be supplied in the constructor, or through accessors.

=over 4

=item * pattern( $str )

Can be overridden in the call to ->parse_datetime.

=back
