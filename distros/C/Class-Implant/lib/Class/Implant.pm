package Class::Implant;
# ABSTRACT: Manipulating mixin and inheritance out of packages

use 5.008008;
use strict;
no  strict "refs";
use warnings;
use Class::Inspector;

our $VERSION = '0.01';

sub import {
  *{(caller)[0] . "::implant"} = \&implant;
}

sub implant (@) {
  my $option = ( ref($_[-1]) eq "HASH" ? pop(@_) : undef );
  my @class = @_;

  my $target = caller;

  if (defined($option)) {
      $target = $option->{into} if defined($option->{into});
      eval qq{ package $target; use base qw(@class); } if $option->{inherit};
  }

  for my $class (reverse @class) {
    for my $function (@{ _get_methods($class) }) {
      *{ $target . "::" . $function } = \&{ $class . "::" . $function };
    }
  }

}

sub _get_methods { Class::Inspector->functions(shift) }

1;


__END__
=head1 NAME

Class::Implant - Manipulating mixin and inheritance out of packages

=head1 VERSION

version 0.01

=head1 SYNOPSIS

There are two ways to use Class::Implant.

procedural way as follow.

  package main;
  use Class::Implant;

  implant qw(Foo::Bar Less::More) { into => "Cat" }   # import all methods in Foo::Bar and Less::More into Cat

or in classical way. just using caller as default target for implanting.

  package Cat;
  use Class::Implant;

  implant qw(Less::More);                 # mixing all methods from Less::More, 
                                          # like ruby 'include'

  implant qw(Foo::Bar), { inherit => 1 }; # import all methods from Foo::Bar and inherit it
                                          # it just do one more step: unshift Foo::Bar into @ISA
                                          # this step is trivial in Perl
                                          # but present a verisimilitude simulation of inheritance in Ruby

=head1 DESCRIPTION

Class::Implant allow you manipulating mixin and inheritance outside of packages.

syntax is like

  use Class::Implant;

  implant @classes_for_injection, { options => value }

available options show as following.

=head2 into

target package for injection.

=head2 inherit

give 1 or any value to mark the inheritance

=head2 include

this option is not available in 0.01

=head2 exclude

this option is not available in 0.01

=head2 EXPORT

implant()

=head1 AUTHOR

  shelling <shelling@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2009 by shelling <shelling@cpan.org>.

This is free software, licensed under:

  The MIT (X11) License

