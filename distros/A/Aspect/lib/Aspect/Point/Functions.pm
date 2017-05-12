package Aspect::Point::Functions;

=pod

=head1 NAME

Aspect::Point::Functions - Allow point context methods to be called as functions

=head1 SYNOPSIS

  use Aspect::Point::Functions;
  
  # This code is equivalent to the SYNOPSIS for Aspect::Point
  my $advice_code = sub {
      print type;           # The advice type ('before')
      print pointcut;       # The matching pointcut ($pointcut)
      print enclosing;      # Access cflow pointcut advice context
      print sub_name;       # The full package_name::sub_name
      print package_name;   # The package name ('Person')
      print short_name;     # The sub name (a get or set method)
      print self;           # 1st parameter to the matching sub
      print (args)[1];      # 2nd parameter to the matching sub
      original->( x => 3 ); # Call matched sub independently
      return_value(4)       # Set the return value
  };

=head1 DESCRIPTION

In the AspectJ toolkit for Java which L<Aspect> is inspired by, the join point
context information is retrieved through certain keywords.

In L<Aspect> this initially proved too difficult to achieve without heavy
source code rewriting, and so an alternative approach was taken using a topic
object and methods.

This B<experimental> package attempts to implement the original function/keyword
style of call.

It is considered unsupported at this time.

=cut

use strict;
use Exporter      ();
use Aspect::Point ();

our $VERSION = '1.04';
our @ISA     = 'Exporter';
our @EXPORT  = qw{
	type
	pointcut
	original
	sub_name
	package_name
	short_name
	self
	wantarray
	args
	exception
	return_value
	enclosing
	topic
	proceed
};

sub type () {
	$_->{type};
}

sub pointcut () {
	$_->{pointcut};
}

sub original () {
	$_->{original};
}

sub sub_name () {
	$_->{sub_name};
}

sub package_name () {
	my $name = $_->{sub_name};
	return '' unless $name =~ /::/;
	$name =~ s/::[^:]+$//;
	return $name;
}

sub short_name () {
	my $name = $_->{sub_name};
	return $name unless $name =~ /::/;
	$name =~ /::([^:]+)$/;
	return $1;
}

sub self () {
	$_->{args}->[0];
}

sub wantarray () {
	$_->{wantarray};
}

sub args {
	if ( defined CORE::wantarray ) {
		return @{$_->{args}};
	} else {
		@{$_->{args}} = @_;
	}
}

sub exception (;$) {
	unless ( $_->{type} eq 'after' ) {
		Carp::croak("Cannot call exception in $_->{exception} advice");
	}
	return $_->{exception} if defined CORE::wantarray();
	$_->{exception} = $_[0];
}

sub return_value (;@) {
	# Handle usage in getter form
	if ( defined CORE::wantarray() ) {
		# Let the inherent magic of Perl do the work between the
		# list and scalar context calls to return_value
		return @{$_->{return_value} || []} if $_->{wantarray};
		return $_->{return_value} if defined $_->{wantarray};
		return;
	}

	# We've been provided a return value
	$_->{exception}    = '';
	$_->{return_value} = $_->{wantarray} ? [ @_ ] : pop;
}

sub enclosing () {
	$_[0]->{enclosing};
}

sub topic () {
	Carp::croak("The join point method topic in reserved");
}

sub proceed () {
	my $self = $_;

	unless ( $self->{type} eq 'around' ) {
		Carp::croak("Cannot call proceed in $self->{type} advice");
	}

	local $_ = ${$self->{topic}};

	if ( $self->{wantarray} ) {
		$self->return_value(
			Sub::Uplevel::uplevel(
				2,
				$self->{original},
				@{$self->{args}},
			)
		);

	} elsif ( defined $self->{wantarray} ) {
		$self->return_value(
			scalar Sub::Uplevel::uplevel(
				2,
				$self->{original},
				@{$self->{args}},
			)
		);

	} else {
		Sub::Uplevel::uplevel(
			2,
			$self->{original},
			@{$self->{args}},
		);
	}

	${$self->{topic}} = $_;

	return;
}

1;

=pod

=head1 AUTHORS

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2011 Adam Kennedy.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
