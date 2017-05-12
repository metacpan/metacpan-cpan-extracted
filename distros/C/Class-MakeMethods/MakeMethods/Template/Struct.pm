package Class::MakeMethods::Template::Struct;

use Class::MakeMethods::Template::Array '-isasubclass';

$VERSION = 1.008;

1;

__END__

=head1 NAME

Class::MakeMethods::Template::Struct - Deprecated name for Array

=head1 SYNOPSIS

  package MyObject;
  use Class::MakeMethods::Template::Array (
    new             => [ 'new' ]
    scalar          => [ 'foo', 'bar' ]
  );
  
  package main;

  my $obj = MyObject->new( foo => "Foozle", bar => "Bozzle" );
  print $obj->foo();		# Prints Foozle
  $obj->bar("Bamboozle"); 	# Sets $obj->[1]

=head1 DESCRIPTION

Earlier versions of this package included a package named Class::MakeMethods::Template::Struct.

However, in hindsight, this name was poorly chosen, as it suggests some connection to C-style structs, where the behavior implemented more simply parallels the functionality of Template::Hash and the other Generic subclasses.

This functionality is now provided by Class::MakeMethods::Template::Array, of which this is an empty subclass retained to provide backwards compatibility.

=head1 SEE ALSO

L<Class::MakeMethods::Template::Array>.

=cut