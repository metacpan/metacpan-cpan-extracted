#!/usr/bin/perl -l

use v5.32;

sub UNIVERSAL::dir {
   my ( $s ) = @_;                  # class or object
   my $ref   = ref $s;
   my $class = $ref ? $ref : $s;    # myClass
   my $pkg   = $class . "::";       # MyClass::

   no strict 'refs';
   my @keys =
     grep { defined $pkg->{$_}->*{CODE} }
     sort keys %$pkg;

   return @keys if defined wantarray;

   local $" = ', ';                 # join separator
   print "$class: [@keys]";
}

package MyClass {    # Sample class
   sub new   { bless {}, shift }
   sub func1 { }
   sub func2 { }
}

sub test {
   MyClass->dir;    # MyClass: [func1, func2, new]

   my $obj = MyClass->new;
   $obj->dir;       # MyClass: [func1, func2, new]

   print for $obj->dir;    # [func1, func2, new]

   # (ref($obj) . "::")->{var}->*{SCALAR}->$* = 42;
   # (ref($obj) . "::")->{var}->$* = 42;
   # print $MyClass::var;
}

if ( @ARGV ) {
   my $class = shift;
   eval "require $class" or die $@;
   $class->dir;
}
