package Data::Package;

=pod

=head1 NAME

Data::Package - Base class for packages that are purely data

=head1 SYNOPSIS
  
  ### Using a Data::Package
  
  use Global::Config;
  
  # Get the data in the default or a prefered format
  Global::Config->get;
  Global::Config->get('Config::Tiny');
  
  # Can we get the data in a particular format?
  Global::Config->provides('Config::Tiny');
  
  ### Creating a data package
  
  package Global::Config;
  
  use strict;
  use base 'Data::Package';
  use Config::Tiny ();
  
  # Load and return the data as a Config::Tiny object.
  sub __as_Config_Tiny {
  	local $/;
  	Config::Tiny->read_string(<DATA>);
  }
  
  1;
  
  __DATA__
  
  [section]
  foo=1
  bar=2

=head1 INTRODUCTION

In the CPAN, a variety of different mechanisms are used by a variety
of different authors in order to provide medium to large amounts of
data to support the functionality contained in theirs or other people's
modules.

In this author's opinion these mechanisms are almost never clean
and elegant and are often quite ugly. One of the worst examples was a
module that converted the Arial font into a 2.7meg perl module.

Why exactly the authors are having to resort to these measures is often
unclear, although I suspect it is primarily the ease with which modules
can be found (compared to data files). Regardless, one thing is very
clear.

There is B<no> obvious, easy and universal way in which to create and
deliver a "Data Product" via CPAN. A data product is a package in where
there is little or more likely B<no> functionality or code, and all of
the "value" in the package is contained in the data itself.

Within the global and unique namespace of perl, most of the packages
represent code in the form of APIs. However this does not mean that
code is the B<only> thing that is capable of reserving a package name.

=head1 DESCRIPTION

C<Data::Package> provides the core of what is hoped will be a highly
scalable and extendable API to create data packages and data products
that can be delivered via the CPAN (and thus anywhere else).

It provides a minimal API that separates how the developer obtains the
data in their code from the methods by which the data is actually obtained,
installed, loaded, parsed and accessed.

The intent is that the consumer of the data should not have to know or care
B<how> the data is obtained, just that they are always able to obtain the
data when they want in the format they want.

It also allows the author or provider of the data to assign the data to
a unique location within the perl namespace. The can then change or improve
the underlying install, storage and loading mechanisms without the need for
any code using that data to have to be changed.

=head2 API Overview

The core Data::Package API requires that only only two static methods
be defined, and probably only one matters if you wrote both the data
package, B<and> code that is using it.

In the simplest and (probably) most common case, where the data package
returns only a single known object type, you should only have to load
the module and then get the data from it.

  use My::Data::Package;
  
  $Data = My::Data::Package->get;

For more complex cases where the data package is capable of providing the
data in several formats, you can use the C<provides> method to find out what
types of object the data package is capable of providing.

  @classes = My::Data::Package->provides;

Your code will most likely simply be confirming that the data is available
in a particular format. Once you know you are able to get it in the format
that you want, you can simple do the following.

  $Data = My::Data::Package->get('Object::Type');

=head1 STATUS

The current implementation is considered to be a proof of concept only.

It should work, and I do want to know about bugs, but it's a little
early to be relying on it yet for production work. It does not have
a sufficiently complete unit test library for starters.

About half the implementation is done by pulling in functionality from
other dependant modules, which are not completely production-standard
themselves (in the case of L<Params::Coerce>. For a proper production
grade version, we probably shouldn't have any dependencies.

However, the API itself is stable and final, and you can write code
that uses this package safely, and any upgrades down the line should
not affect it.

=head1 METHODS

=cut

use 5.005;
use strict;
use Class::Inspector ();
use Params::Util     qw{ _CLASS };
use Params::Coerce   ();

use vars qw{$VERSION};
BEGIN {
	$VERSION = '1.05';
}





#####################################################################
# Constructor

=pod

=head2 new

The C<new> constructor is provided mainly as a convenience, and to let
you create handles to the data that can be passed around easily.

Takes no arguments, and returns a new blessed object of the same class
that you called it for.

=cut

sub new {
	my $class = ref($_[0]) || "$_[0]";
	my $self  = \$class;
	bless $self, $class;
}





#####################################################################
# Main Methods

=pod

=head2 provides [ $class ]

The C<provides> method is used to find the list of formats the data
package is capable of providing the data in, although typically it
is just going to be one.

When called without an argument, the method returns a list of all of
the classes that the data can be provides as instantiated objects of.

In this first version, it is assumed you are providing the data as some
form of object.

If provided an argument, the list will be filtered to list only those
that are of the object type you specificied. This can be used to either
limit the list, or check for a specific class you want.

In both cases, the first class returned by C<provides> is the same that
will be returned by the C<get> method when called with the same (or without
an) argument.

And either way, the method returns the classes in list context, or the
number of classes in scalar context. This also lets you do things like:

  if ( Data::Thingy->provides('Big::Thing') ) {
  	die "Data::Thingy cannot provide a Big::Thing";
  }

=cut

sub provides {
	my $class = ref $_[0] ? ref shift : shift;
	my $want  = _CLASS(shift);

	# Get the raw list of classes
	my %seen     = ();
	my @provides = grep { ! $seen{$_}++ }
	               grep { defined $_    }
	               $class->_provides;

	# Return the full list unless we were given a filter
	return @provides unless $want;

	# Filter for the class we want, loading as needed
	my @filtered = ();
	foreach my $p ( @provides ) {
		if ( Class::Inspector->loaded($p) ) {

		} else {
			eval "require $p;";
			if ( $@ ) {
				next;
			}
		}
		if ( $p->isa($want) ) {
			push @filtered, $p;
		}
	}

	return @filtered;
}

sub _provides {
	my $class = shift;

	# If the class has a @PROVIDES array, we'll use that directly.
	no strict 'refs';
	if ( defined @{"${class}::PROVIDES"} ) {
		return @{"${class}::PROVIDES"};
	}

	# Scan the class for __as_Foo_Bar methods
	my $methods = Class::Inspector->methods($class)
		or die "Error while looking for providor method in $class";

	# Filter to just provider methods and convert to classes
	return map  { s/^__as_//; s/_/::/g; $_ }
	       grep { /^__as(?:_[^\W\d]\w*)+$/ } @$methods;
}

=pod

=head2 get [ $class ]

The C<get> method does whatever is necesary to access and load the data
product, and returns it as an object.

If the data package is capable of providing the data in more than one
format, you can optionally provide an object of the class that you want
it in.

Returns an object (possibly of a class you specify) or C<undef> if it
is unable to load the data, or it cannot provide the data in the format
that you have requested.

=cut

sub get {
	my $class = ref $_[0] ? ref shift : shift;

	# Given that they our subclass did not write it's own version
	# of the ->get method, they must be using coercion provider
	# methods.

	# So lets find what we need to deliver, and then call it.
	my @classes = $class->provides(@_) or return undef;
	my $want    = shift @classes;

	# Leverage coerce to do the actual loading
	Params::Coerce::_coerce( $want, $class->new );
}

1;

=pod

=head1 SUPPORT

Bugs should always be submitted via the CPAN bug tracker

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Data-Package>

For other issues, contact the maintainer

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2005-2007 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
