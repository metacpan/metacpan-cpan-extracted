package Class::MakeMethods::Template::Flyweight;

use Class::MakeMethods::Template::InsideOut '-isasubclass';

$VERSION = 1.008;

sub new { { '-import' => { 'Template::Scalar:new' => '*' } } }

1;

__END__

=head1 NAME

Class::MakeMethods::Template::Flyweight - Deprecated name for InsideOut

=head1 SYNOPSIS

  package MyObject;
  use Class::MakeMethods::Template::InsideOut (
    new             => [ 'new' ]
    scalar          => [ 'foo', 'bar' ]
  );
  
  package main;

  my $obj = MyObject->new( foo => "Foozle", bar => "Bozzle" );
  print $obj->foo();		# Prints Foozle
  $obj->bar("Bamboozle"); 	# Sets $obj->{bar}

=head1 DESCRIPTION

Earlier versions of this package included a package named Class::MakeMethods::Template::Flyweight.

However, in hindsight, this name was poorly chosen, as it suggests that the Flyweight object design pattern is being used, when the functionality is more akin to what's sometimes known as "inside-out objects."

This functionality is now provided by Class::MakeMethods::Template::InsideOut, of which this is an almost-empty subclass retained to provide backwards compatibility.

=head1 SEE ALSO

L<Class::MakeMethods::Template::InsideOut>.

=cut