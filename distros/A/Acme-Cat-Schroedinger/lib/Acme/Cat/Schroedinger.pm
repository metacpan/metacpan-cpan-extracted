use strict;
use warnings;

package Acme::Cat::Schroedinger;

=head1 NAME

Acme::Cat::Schroedinger - objects whose behaviour is determined by attempts to inspect or interact with it.

=head1 VERSION

1

=cut

our $VERSION = 1;

use overload (
'0+'  => sub {return  $_[0]->('0+')->($_[0]);},
'""'  => sub {return  $_[0]->('""')->($_[0]);},
'@{}' => sub {return $_[0]->('@{}')->($_[0]);},
'%{}' => sub {return $_[0]->('%{}')->($_[0]);},
'${}' => sub {return $_[0]->('${}')->($_[0]);},
'*{}' => sub {return $_[0]->('*{}')->($_[0]);},
);


sub new{
	my $class = shift;
	my %options = @_;
	my $self = sub {
		my $attr = shift;
		my @caller = caller;
		return sub {'meow'} unless $caller[0] eq __PACKAGE__;
		my %attrs = (
			'temperament'	=>	'cooperative', # cooperative | perverse | random
			'kittens'	=>	'inherit', # inherit | default | random
			'mutable'	=>	'1', # 0 | 1 # never usable
			%options
		);
		return $attrs{$attr} if exists $attrs{$attr}; # check caller
		my $coopRef = ($attrs{temperament} eq 'cooperative' or ($attrs{temperament} eq 'random' and int(rand(2)) ) )? undef:'';
		my %overload = (
			'0+'  => sub {return ($_[0]= defined $coopRef?die:0);},
			'""'  => sub {return ($_[0]= defined $coopRef?die:'');}, # todo: include temperament
			'@{}' => sub {return ($_[0]=$coopRef // []);}, # todo: include temperament
			'%{}' => sub {return ($_[0]=$coopRef // {});}, # todo: include temperament
			'${}' => sub {return ($_[0]=$coopRef // \0);}, # todo: include temperament
			'*{}' => sub {return ($_[0]=$coopRef // \*{''});}, # todo: include temperament
		);
		return $overload{$attr};
	};
	bless $self, $class;
}

=head1 SYNOPSIS

A newly-created Acme::Cat::Schroedinger could be anything. It could be cooperative, and be anything you want it to be. It could be perverse and will never be what you want it to be. Or it could behave like the original Schroedinger's Cat and its behaviour will be, for all intents and purposes, unknowable until you interact with it. 

	my $cat = Acme::Cat::Schroedinger->new();
	print %{$cat}; # The cat is now an empty hashref, and does not die.
	
	# or...
	my $cat = Acme::Cat::Schroedinger->new(temperament=>'perverse');
	print %{$cat}; # The cat is guaranteed not to be a hashref (or anything else you expect it to be), and thus will die.

	# or...
	my $cat = Acme::Cat::Schroedinger->new(temperament=>'random');
	print %{$cat}; # May or may not die, the only way of knowing is running the code.

=head1 DESCRIPTION

The Acme::Cat::Schroedinger can be 'observed' in various ways by being treated like a hashref or an arrayref or a string.

Note that once you have observed the cat, it typically ceases to be a cat: the experiment is no longer repeatable.

=head2 METHOD new

	my $cat = Acme::Cat::Schroedinger->new();

When you create the cat, it has the following properties:

=head3 temperament = cooperative

Allowed: C<cooperative|perverse|random>. Determines whether the cat always behaves the way you ask it to, never behaves the way you ask it to, or decides how to behave only when you ask it. 

=head1 BUGS

If you're clever, you can work out that the object in question is a cat, and furthermore you might be able to work out its temperament, mutability, etc. 

=cut

1;
