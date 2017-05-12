#! perl

package Data::Struct;

use strict;
use warnings;
use base qw(Exporter);
our @EXPORT = qw( &struct );
use Carp;

$Carp::Internal{ (__PACKAGE__) }++;

our $VERSION = "1.701";

# use Data::Struct;
#
# Definition (void context):
# struct Foo => qw(foo bar);
#
# Contructing (scalar context):
# my $s2 = struct "Foo";
# my $s3 = struct Foo => { foo => 1, bar => 2 };

sub struct {
    my @args = @_;
    croak("'struct' needs at least a struct name") unless @args;
    my $struct = shift(@args);

    if ( !defined wantarray ) {	# void context -> definition
	# struct Foo => [ attr1, attr2, ... ]
	if ( @args == 1 && ref($args[0]) eq 'ARRAY' ) {
	    return _define( $struct, $args[0] );
	}

	# struct Foo => qw( attr1 attr2 ...)
	return _define( $struct, \@args ) if @args;
    }

    if ( !wantarray ) {		# scalar context -> construction
	# $s = struct Foo => { attr1 => val1, attr2 = val2, ... }
	if ( @args == 1 && ref($args[0]) eq 'HASH' ) {
	    my @ival = values %{ $args[0] };
	    @args = keys %{ $args[0] };
	    return _build( $struct, \@args, \@ival );
	}

	# $s = struct foo;
	return _build( $struct, [], [] ) unless @args;
    }

    croak("Ambiguous use of \"struct '$struct'\"");
}

sub _define {
    my ( $struct, $attrs ) = @_;

    no strict 'refs';
    ${$struct.':: type'} = __PACKAGE__;

    # Undefined accessor catcher.
    our $AUTOLOAD;
    *{$struct.'::AUTOLOAD'} = sub {
	my ( $s, $a ) = $AUTOLOAD =~ /^(.*)::([^:]+)$/;
	croak("Unknown accessor '$a' for struct '$s'")
	  unless $a eq 'DESTROY';
    };

    # Accessors.
    foreach ( @$attrs ) {
	croak("Invalid accessor name '$_' for struct '$struct'")
	  unless defined and !ref and /^[^\W\d]\w*$/s;

	my $attr = $_;		# lexical for closure

	*{$struct.'::'.$_} = sub () :lvalue {
	    croak("Accessor '$attr' for struct '$struct' takes no arguments")
	      if @_ > 1;
	    $_[0]->{$attr};
	};
    };
}

sub _build {
    my ( $struct, $attrs, $values ) = @_;

    no strict 'refs';

    croak("Undefined struct '$struct'")
      unless (${$struct . ":: type"}||'') eq __PACKAGE__;
    Carp::confess("uneven") unless @$attrs == @$values;

    # Construct empty struct.
    my $s = bless {}, $struct;

    # Assign initial attributes, if any.
    foreach ( @$attrs ) {
	croak("Unknown accessor '$_' for struct '$struct'")
	  unless $s->can($_);
	$s->$_ = shift( @$values );
    }

    return $s;
}


1;

=pod

=head1 NAME

Data::Struct - Simple struct building

=head1 SYNOPSIS

  use Data::Struct;		# exports 'struct'

  # Define the struct and its accessors.
  struct Foo => [ qw(foo bar) ];
  struct Foo => qw(foo bar);	# alternative

  # Construct the struct.
  my $object = struct "Foo";	# empty struct
  my $object = struct Foo => { bar => 1 };
  my $object = struct Foo => { foo => "yes", bar => 1 };

  # Use it.
  print "bar is " . $object->bar . "\n";       # 1
  $object->bar = 2;
  print "bar is now " . $object->bar . "\n";   # 2

=head1 DESCRIPTION

A I<struct> is a data structure that can contain values (attributes).
The values of the attributes can be set at creation time, and read and
modified at run time. This module implements a very basic and easy to
use I<struct> builder.

Attributes can be anything that Perl can handle. There's no checking
on types. If you need I<struct>s with type checking and inheritance
and other fancy stuff, use one of the many CPAN modules that implement
data structures using classes and objects. Data::Struct deals with
data structures and not objects, so I placed this module under the
Data:: hierarchy.

To use Data::Struct, just use it. This will export the struct()
function that does all the work.

To define a structure, call struct() with the name of the structure and
a list of accessors to be created:

  struct( "Foo", "foo", "bar");

which can be nicely written as:

  struct Foo => qw( foo bar );

To prevent ambiguities, defining a struct requires struct() to be
called in void context.

To create an empty structure:

  my $s = struct "Foo";

To create a structure with one or more pre-initialised attributes:

  my $s = struct Foo => { foo => 3, bar => "Hi" };

To prevent ambiguities, creating a struct requires struct() to be
called in scalar context.

When the structure has been created, you can use accessor functions to
set and get the attributes:

  print "bar is " . $s->bar . "\n";       # "Hi"
  $s->bar = 2;
  print "bar is now " . $s->bar . "\n";   # 2

=head1 PECULIARITIES

Redefining a structure adds new attributes but leaves existing
attibutes untouched.

  struct "Foo" => qw(bar);
  my $s = struct "Foo" => { bar => 2 };
  struct Foo => qw(blech);
  $s->blech = 4;
  say $s->bar;		# prints 2
  say $s->blech;	# prints 4

This may change in a future version.

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Data::Struct>

For other issues, contact the author.

=head1 AUTHOR

Johan Vromans E<lt>jv@cpan.orgE<gt>.

=head1 SEE ALSO

L<Object::Tiny>, L<Object::Tiny::Lvalue>, L<Object::Tiny::RW>,
L<Class::Struct>.

=head1 COPYRIGHT

Copyright 2011 Johan Vromans

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

=cut
