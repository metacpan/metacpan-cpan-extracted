package Class::MakeMethods::Template::Static;

use Class::MakeMethods::Template::Global '-isasubclass';

$VERSION = 1.008;

1;

__END__

=head1 NAME

Class::MakeMethods::Template::Static - Deprecated name for Global

=head1 SYNOPSIS

  package MyObject;
  use Class::MakeMethods::Template::Global (
    scalar          => [ 'foo' ]
  );
  
  package main;

  MyObject->foo('bar')
  print MyObject->foo();
  ...
  print $my_instance->foo(); # same thing

=head1 DESCRIPTION

Earlier versions of this package included a package named Class::MakeMethods::Template::Static.

However, in hindsight, this name was poorly chosen, as it suggests a constant, unchanging value, whereas the actual functionality is akin to traditional "global" variables.

This functionality is now provided by Class::MakeMethods::Template::Global, of which this is an empty subclass retained to provide backwards compatibility.

=head1 SEE ALSO

L<Class::MakeMethods::Template::Global>.

=cut