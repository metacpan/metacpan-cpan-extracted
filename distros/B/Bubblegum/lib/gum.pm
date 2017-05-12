# ABSTRACT: Convenient Shoehorn for Bubblegum
package gum;

use 5.10.0;
use Import::Into;

our $VERSION = '0.45'; # VERSION

sub import {
    my $target = caller;
    my $class  = shift;

    my @flags  = grep /^-\w+/, @_;
    my %flags  = map +($_, 1), map substr($_, 1), @flags;

    if ($flags{class}) {
        require 'Bubblegum/Class.pm';
        'Bubblegum::Class'->import::into($target);
    }
    elsif ($flags{role}) {
        require 'Bubblegum/Role.pm';
        'Bubblegum::Role'->import::into($target);
    }
    elsif ($flags{singleton}) {
        require 'Bubblegum/Singleton.pm';
        'Bubblegum::Singleton'->import::into($target);
    }
    else {
        require 'Bubblegum.pm';
        'Bubblegum'->import::into($target);
    }
    if ($flags{proto} or $flags{prototype}) {
        require 'Bubblegum/Prototype.pm';
        'Bubblegum::Prototype'->import::into($target);
    }

    my @exports = ();
    push @exports, '-types'   if $flags{types};
    push @exports, '-typesof' if $flags{types};
    push @exports, '-isas'    if $flags{isas};
    push @exports, '-nots'    if $flags{isas};

    if (@exports) {
        require 'Bubblegum/Constraints.pm';
        'Bubblegum::Constraints'->import::into($target, @exports);
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

gum - Convenient Shoehorn for Bubblegum

=head1 VERSION

version 0.45

=head1 SYNOPSIS

    use gum;

=head1 DESCRIPTION

This module is a I<shoehorn> for Bubblegum. It merely serves as convenient means
of loading and configuring L<Bubblegum>. B<Note: This is an early release
available for testing and feedback and as such is subject to change.>

    use gum;

or

    use gum -types, -isas;

is equivalent to

    use Bubblegum;
    use Bubblegum::Constraints -types, -isas;

bubblegum class usage

    use gum -class;

or

    use gum -class, -types, -isas;

is equivalent to

    use Bubblegum::Class;
    use Bubblegum::Constraints -types, -isas;

bubblegum prototype usage

    use gum -proto;

or

    use gum -proto, -types, -isas;

is equivalent to

    use Bubblegum::Prototype;
    use Bubblegum::Constraints -types, -isas;

bubblegum role usage

    use gum -role;

or

    use gum -role, -types, -isas;

is equivalent to

    use Bubblegum::Role;
    use Bubblegum::Constraints -types, -isas;

bubblegum singleton usage

    use gum -singleton;

or

    use gum -singleton, -types, -isas;

is equivalent to

    use Bubblegum::Singleton;
    use Bubblegum::Constraints -types, -isas;

all of which is automatically enables

    use 5.10.0;
    use strict;
    use warnings;
    use autobox;
    use autodie ':all';
    use feature ':5.10';
    use English -no_match_vars;
    use utf8::all;
    use mro 'c3';

with the exception that Bubblegum implements it's own autoboxing architecture.
The Bubblegum autobox classes are the foundation for this development framework.
The decision to re-implement many core and autobox functions was based on the
desire to build-in data validation and design a system using roles for a higher
level of abstraction. Bubblegum will also default to including L<Moo> as an
object system. For example:

    use Bubblegum::Class;                   # Bubblegum w/ Moo
    use Bubblegum::Prototype;               # Bubblegum w/ Moo (Prototype)
    use Bubblegum::Role;                    # Bubblegum w/ Moo (Role)
    use Bubblegum::Singleton;               # Bubblegum w/ Moo (Singleton)

Please review the L<Bubblegum> documentation for more information and usage
patterns.

=head1 AUTHOR

Al Newkirk <anewkirk@ana.io>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Al Newkirk.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
