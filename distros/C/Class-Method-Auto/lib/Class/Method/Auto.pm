package Class::Method::Auto;

use strict;
use warnings;

our $VERSION = "1.00";

use attributes 'get';

sub my_croak($$) {
	my ($package, $method) = @_;
	require Carp;
	Carp::croak "Undefined subroutine &${package}::$method called";
}

sub import {
	shift;
	my $target = caller;
	my ($regexp, $check_attributes, @methods);
	for (@_) {
		if (ref($_) eq 'Regexp') {
			$regexp = $_;
		} elsif ($_ eq '-attributes') {
			$check_attributes = 1;
		} else {
			push(@methods, $_);
		}
	}
	if (@methods) { # install for every method in @_
		for my $method(@methods) {
			my $autosub = sub {
				my $package = caller;
				unshift(@_, $package);
				my @isa;
				{
					no strict 'refs';
					@isa = @{$package.'::ISA'};
				}
				for (@isa) {
					my $sub = $_->can($method);
					goto &{$sub} if defined $sub;
				}
				my_croak($package, $method);
			};
			{ 
				no strict 'refs';
				*{"${target}::$method"} = $autosub unless defined *{"${target}::$method"}{'CODE'};
			}
		}
	} else { # install globally;
		my $autoload = sub {
			my $method = our $AUTOLOAD;
			$method =~ s/.*:://;
			my $package = caller;
			if ($regexp) {
				my_croak($package, $method) unless ($method =~ $regexp);
			}
			unshift(@_, $package);
			my $sub = $package->can($method);
			my_croak($package, $method) unless defined $sub;
			if ($check_attributes) {
				my %attr;
				@attr{get($sub)} = undef;
				my_croak($package, $method) unless exists $attr{'method'};
			}
			goto &{$sub};
		};
		{ 
			no strict 'refs';
			if (defined *{"${target}::AUTOLOAD"}{'CODE'}) {
				require Carp;
				Carp::croak "There already seems to be a routine named AUTOLOAD in $target";
			} else {
				*{"${target}::AUTOLOAD"} = $autoload;
			}
		}
	}
}


1;
__END__

=head1 NAME

Class::Method::Auto - Turn subroutine calls into class method calls

=head1 SYNOPSIS

  # in Foo.pm
  package Foo;
  
  sub bar {
    ...
  }
  
  # in Baz.pm
  package Baz;
  
  use Class::Method::Auto 'bar';
  
  use base 'Foo';
  
  bar("Moose!"); # same as __PACKAGE__->bar("Moose!")

=head1 DESCRIPTION

Class::Method::Auto allows you to call inherited class methods directly without 
prefixing them with the class name.

There are two methods of telling Class::Method::Auto which methods to call 
automatically: By explicitly giving it a list of method names or by specifying 
a filter for the methods.

In the first case, Class::Method::Auto creates a subroutine in the importing 
package for every name in the list that C<unshift>'s the calling package name
onto C<@_> and jumps to the method in the first package where is it defined.

  package Blurp;
  
  use Class::Method::Auto qw[bar baz]; # creates Blurp::bar and Blurp::baz
  
In the second case, you can specify a regular expression for the 
method names to be tested against or the string C<-attributes>, which causes
Class::Method::Auto to check whether the called method has the <method> 
attribute to make sure only real methods are called.

When specifying a filter, the method AUTOLOAD is installed in the importing
package for dispatching.

  package Foo;
  
  sub my_method :method {
    ...
  }
  
  sub no_method {
    ...
  }

  sub _private {
    ...
  }

  package Moose;
  
  use base 'Foo';
  
  use Class::Method::Auto '-attributes', qr/^[^_]/;
  
  # now my_method(...) can be called, but not no_method or _private
  
=head1 BUGS

Due to the subroutine calling mechanism in Perl, only method in base classes
can be called automatically via Class::Method::Auto.

=head1 SEE ALSO

L<attributes>

=head1 AUTHOR

Bernhard Bauer, E<lt>bauerb@in.tum.deE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Bernhard Bauer

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.


=cut
