package Class::Adapter::Builder;

=pod

=head1 NAME

Class::Adapter::Builder - Generate Class::Adapter classes

=head1 SYNOPSIS

  package My::Adapter;
  
  use strict;
  use Class::Adapter::Builder
      ISA     => 'Specific::API',
      METHODS => [ qw{foo bar baz} ],
      method  => 'different_method';
  
  1;

=head1 DESCRIPTION

C<Class::Adapter::Builder> is another mechanism for letting you create
I<Adapter> classes of your own.

It is intended to act as a toolkit for generating the guts of many varied
and different types of I<Adapter> classes.

For a simple base class you can inherit from and change a specific method,
see L<Class::Adapter::Clear>.

=head2 The Pragma Interface

The most common method for defining I<Adapter> classes, as shown in the
synopsis, is the pragma interface.

This consists of a set of key/value pairs provided when you load the module.

  # The format for building Adapter classes
  use Class::Adapter::Builder PARAM => VALUE, ...

=over 4

=item ISA

The C<ISA> param is provided as either a single value, or a reference
to an C<ARRAY> containing is list of classes.

Normally this is just a straight list of classes. However, if the value
for C<ISA> is set to C<'_OBJECT_'> the object will identify itself as
whatever is contained in it when the C<-E<gt>isa> and C<-E<gt>can> method
are called on it.

=item NEW

Normally, you need to create your C<Class::Adapter> objects separately:

  # Create the object
  my $query = CGI->new( 'param1', 'param2' );
  
  # Create the Decorator
  my $object = My::Adapter->new( $query );

If you provide a class name as the C<NEW> param, the Decorator will
do this for you, passing on any constructor arguments.

  # Assume we provided the following
  # NEW => 'CGI',
  
  # We can now do the above in one step
  my $object = My::Adapter->new( 'param1', 'param2' );

=item AUTOLOAD

By default, a C<Class::Adapter> does not pass on any methods, with the
methods to be passed on specified explicitly with the C<'METHODS'>
param.

By setting C<AUTOLOAD> to true, the C<Adapter> will be given the
standard C<AUTOLOAD> function to to pass through all unspecified
methods to the parent object.

By default the AUTOLOAD will pass through any and all calls, including
calls to private methods.

If the AUTOLOAD is specifically set to 'PUBLIC', the AUTOLOAD setting
will ONLY apply to public methods, and any private methods will not
be passed through.

=item METHODS

The C<METHODS> param is provided as a reference to an array of all
the methods that are to be passed through to the parent object as is.

=back

Any params other than the ones specified above are taken as translated
methods.

  # If you provide the following
  # foo => bar
  
  # It the following are equivalent
  $decorator->foo;
  $decorator->_OBJECT_->bar;

This capability is provided primarily because in Perl one of the main
situations in which you hit the limits of Perl's inheritance model is
when your class needs to inherit from multiple different classes that
containing clashing methods.

For example:

  # If your class is like this
  package Foo;
  
  use base 'This', 'That';
  
  1;

If both C<This-E<gt>method> exists and C<That-E<gt>method> exists,
and both mean different things, then C<Foo-E<gt>method> becomes
ambiguous.

A C<Class::Adapter> could be used to wrap your C<Foo> object, with
the C<Class::Adapter> becoming the C<That> sub-class, and passing
C<$decorator-E<gt>method> through to C<$object-E<gt>that_method>.

=head1 METHODS

Yes, C<Class::Adapter::Builder> has public methods and later on you will
be able to access them directly, but for now they are remaining
undocumented, so that I can shuffle things around for another few
versions.

Just stick to the pragma interface for now.

=cut

use 5.005;
use strict;
use Carp           ();
use Class::Adapter ();

use vars qw{$VERSION};
BEGIN {
	$VERSION = '1.07';
}





#####################################################################
# Constructor

sub new {
	my $class = ref $_[0] || $_[0];
	return bless {
		target  => $_[1],
		isa     => [ 'Class::Adapter' ],
		modules => {},
		methods => {},
	}, $class;
}

sub import {
	my $class = shift;

	# Must have at least one param
	return 1 unless @_;

	# Create the Builder object
	my $target = caller;
	my $self   = $class->new( $target );
	unless ( $self ) {
		Carp::croak("Failed to create Class::Adapter::Builder object");
	}

	# Process the option pairs
	while ( @_ ) {
		my $key   = shift;
		my $value = shift;
		if ( $key eq 'NEW' ) {
			$self->set_NEW( $value );
		} elsif ( $key eq 'ISA' ) {
			$self->set_ISA( $value );
		} elsif ( $key eq 'AUTOLOAD' ) {
			$self->set_AUTOLOAD( $value );
		} elsif ( $key eq 'METHODS' ) {
			$self->set_METHODS( $value );
		} else {
			$self->set_method( $key, $value );
		}
	}

	# Generate the code
	my $code = $self->make_class or Carp::croak(
		"Failed to generate Class::Adapter::Builder class"
	);

	# Compile the combined code via a temp file so that debugging works
	#require File::Temp;
	#my ($fh, $filename) = File::Temp::tempfile();
	#$fh->print("$code");
	#close $fh;
	#require $filename;
	#print "Loaded '$filename'\n";

	eval "$code";
	$@ and Carp::croak(
		"Error while compiling Class::Adapter::Builder class '$target' ($@)"
	);

	$target;
}





#####################################################################
# Main Methods

sub set_NEW {
	my $self     = shift;
	$self->{new} = shift;

	# We always need Scalar::Util to pass through new
	$self->{modules}->{'Scalar::Util'} = 1;

	# Add a use for the module unless it is already loaded.
	# We test with the can call instead of just blindly require'ing in
	# case we want to NEW to something that doesn't have it's own
	# .pm file. 
	unless ( $self->{new}->can('new') ) {
		$self->{modules}->{ $self->{new} } = 1;
	}

	return 1;
}

sub set_ISA {
	my $self  = shift;
	my $array = ref $_[0] eq 'ARRAY' ? shift : [ @_ ];
	$self->{isa} = $array;
	return 1;
}

sub set_AUTOLOAD {
	my $self = shift;
	if ( $_[0] ) {
		$self->{autoload} = 1;		
		$self->{modules}->{Carp} = 1;
		if ( $_[0] eq 'PUBLIC' ) {
			$self->{autoload_public} = 1;
		}
	} else {
		delete $self->{autoload};
	}
	return 1;
}

sub set_METHODS {
	my $self  = shift;
	my $array = ref $_[0] eq 'ARRAY' ? shift : [ @_ ];
	foreach my $name ( @$array ) {
		$self->set_method( $name, $name ) or return undef;
	}
	return 1;
}

sub set_method {
	my $self = shift;
	if ( @_ == 1 ) {
		$self->{methods}->{$_[0]} = $_[0];
	} elsif ( @_ == 2 ) {
		$self->{methods}->{$_[0]} = $_[1];
	} else {
		return undef;
	}
	return 1;
}





#####################################################################
# Code Generation Functions

sub make_class {
	my $self  = shift;

	# Generate derived lists
	my %seen  = ();
	$self->{load} = [
		grep { $_ !~ /^Class::Adapter(?:::Builder)?$/ }
		sort grep { ! $seen{$_}++ }
		keys %{$self->{modules}}
	];
	$self->{fake} = [
		grep { ! $seen{$_} } grep { $_ ne '_OBJECT_' } @{$self->{isa}}
	];

	# Build up the parts of the class
	my @parts = (
		"package $self->{target};\n\n"
		. "# Generated by Class::Abstract::Builder\n"
	);

	if ( keys %{$self->{modules}} ) {
		push @parts, $self->_make_modules;
	}

	if ( $self->{new} ) {
		push @parts, $self->_make_new( $self->{new} );
	}

	my $methods = $self->{methods};
	foreach my $name ( keys %$methods ) {
		push @parts, $self->_make_method( $name, $methods->{$name} );
	}

	if ( @{$self->{isa}} == 1 ) {
		if ( $self->{isa}->[0] eq '_OBJECT_' ) {
			push @parts, $self->_make_OBJECT;
		} else {
			push @parts, $self->_make_ISA( @{$self->{isa}} );
		}
	}

	if ( $self->{autoload} ) {
		push @parts, $self->_make_AUTOLOAD( $self->{target}, $self->{autoload_public} );
	}

	return join( "\n", @parts, "1;\n" );
}

sub _make_modules {
	my $self  = shift;
	my $pkg   = $self->{target};
	my $load  = join '',
		map { "\nuse $_ ();" }
		@{$self->{load}};

	# Foo->isa('Foo') returns false if the namespace does not exist
	# Use the package command in a scope to create namespaces where needed.
	my $namespaces = join '',
		map { "\n\t$_->isa('$_') or do { package $_ };" }
		@{$self->{fake}};

	return <<"END_MODULES";
use strict;${load}
use Class::Adapter ();

BEGIN {
	\@${pkg}::ISA = 'Class::Adapter';${namespaces}
}
END_MODULES
}

sub _make_new { <<"END_NEW" }
sub new {
	my \$class  = ref \$_[0] ? ref shift : shift;
	my \$object = $_[1]\->new(\@_);
	Scalar::Util::blessed(\$object) or return undef;
	\$class->SUPER::new(\$object);
}
END_NEW



sub _make_method { <<"END_METHOD" }
sub $_[1] { shift->_OBJECT_->$_[2](\@_) }
END_METHOD



sub _make_OBJECT { <<"END_OBJECT" }
sub isa {
	ref(\$_[0])
	? shift->_OBJECT_->isa(\@_)
	: shift->isa(\@_);
}

sub can {
	ref(\$_[0])
	? shift->_OBJECT_->can(\@_)
	: shift->can(\@_);
}
END_OBJECT

sub _make_ISA {
	my $self = shift;
	my @lines = (
		"sub isa {\n",
		( map { "\treturn 1 if \$_[1]->isa('$_');\n" } @_ ),
		"\treturn undef;\n",
		"}\n",
		"\n",
		"sub can {\n",
		# If we are pretending to be a fake ISA, and we get a can call,
		# we should try to require the module (even if it doesn't exist)
		# so that we can provide an accurate answer in the case where
		# we are faking a module that exists.
		( map { "\trequire $_ unless $_->isa('UNIVERSAL');\n" } @{$self->{fake}} ),
		"\treturn 1 if \$_[0]->SUPER::can(\$_[1]);\n",
		( map { "\treturn 1 if $_->can(\$_[1]);\n" } @_ ),
		"\treturn undef;\n",
		"}\n",
	);
	return join '', @lines;
}		



sub _make_AUTOLOAD { my $pub = $_[2] ? 'and substr($method, 0, 1) ne "_"' : ''; return <<"END_AUTOLOAD" }
sub AUTOLOAD {
	my \$self     = shift;
	my (\$method) = \$$_[1]::AUTOLOAD =~ m/^.*::(.*)\\z/s;
	unless ( ref(\$self) $pub) {
		Carp::croak(
			  qq{Can't locate object method "\$method" via package "\$self" }
			. qq{(perhaps you forgot to load "\$self")}
		);
	}
	\$self->_OBJECT_->\$method(\@_);
}

sub DESTROY {
	if ( defined \$_[0]->{OBJECT} and \$_[0]->{OBJECT}->can('DESTROY') ) {
		undef \$_[0]->{OBJECT};
	}
}
END_AUTOLOAD

1;

=pod

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Class-Adapter>

For other issues, contact the author.

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 SEE ALSO

L<Class::Adapter>, L<Class::Adapter::Clear>

=head1 COPYRIGHT

Copyright 2005 - 2011 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
