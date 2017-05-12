package Constant::FromGlobal;
$Constant::FromGlobal::VERSION = '0.09';
# ABSTRACT: declare constant(s) with value from global or environment variable

use strict;
use warnings;
use 5.8.0;
use Carp;
use Data::OptList;
use constant ();

sub import {
    my ( $class, @args ) = @_;

    my $opt = ref($args[0]) eq 'HASH' ? shift @args : {};

    @_ = (
		"constant",
		$class->process_constants(
			package => scalar(caller),
			%$opt,
			constants => \@args
		)
	);

    goto &constant::import;
}

sub process_constants {
    my ( $class, %args ) = @_;

    my $options = Data::OptList::mkopt(delete $args{constants}, "constant", 1, [qw(HASH ARRAY)]);

    my $constants = {};

    my $caller = $args{package};

    foreach my $constant ( @$options ) {
        my ( $name, $opt ) = @$constant;

        $constants->{$name} = $class->get_value(
            %args,
            name => $name,
            %$opt,
        );
    }

    return $constants;
}

sub get_value {
    my ( $class, %args ) = @_;

    my $value = $class->get_var(%args);

    if ( not defined $value and $args{env} ) {
        $value = $class->get_env_var(%args);
    }

	if ( not defined $value and defined $args{default} ) {
		$value = $args{default};
	}

    if ( $args{bool} ) {
        return not not $value;
    } elsif ( defined $value ) {
        if ( $args{num} ) {
            require Scalar::Util;
            croak "'$value' does not look like a number" unless Scalar::Util::looks_like_number($value);
            return 0+$value;
        } elsif ( $args{int} ) {
            croak "'$value' does not look like an integer" unless $value =~ /^\s* -? \d+ \s*$/x;
            return int 0+$value;
        }
	}

	return $value;
}

sub var_name {
    my ( $class, %args ) = @_;

    join "::", @args{qw(package name)};
}

sub get_var {
    my ( $class, %args ) = @_;

    no strict 'refs';
    return ${ $class->var_name(%args) }
}

sub get_env_var {
    my ( $class, %args ) = @_;

    my $name = uc $class->var_name(%args);
    $name =~ s/^MAIN:://;
    $name =~ s/::/_/g;

    $ENV{$name};
}

# ex: set sw=4 et:

__PACKAGE__

__END__

=pod

=head1 NAME

Constant::FromGlobal - declare constant(s) with value from global or environment variable

=head1 SYNOPSIS

  package Foo;

  use Constant::FromGlobal qw(DEBUG);

  sub foo {
      # to enable debug, set $Foo::DEBUG=1 before loading Foo
      warn "lalala" if DEBUG:
  }

=head1 DESCRIPTION

This module lets you define constants that either take their values from
global variables, or from environment variables. The constants are
function-style constants, like those created using the L<constant> pragma.

Here's a minimal example showing how to set a constant from a global
variable:

 our $DEBUG;
 BEGIN {
     $DEBUG = 1;
 }
 use Constant::FromGlobal qw/ DEBUG /;

You might wonder why you might want to do that?
A better example is where a module sets a constant from a global
variable in its package, but you can set that variable before
using the module.
First, here's the module:

 package Foobar;
 use Constant::FromGlobal LOGLEVEL => { default => 0 };

Then elsewhere you can write something like this:

 BEGIN {
   $Foobar::LOGLEVEL = 3;
 }
 use Foobar;

=head2 Environment variables

By default C<Constant::FromGlobal> will only look at the relevant
global variable. If you pass the B<env> option, then it will also
look for an appropriately named environment variable:

 use Constant::FromGlobal DEBUG => { env => 1, default => 0 };

Note that you can also set a default value, which will be used
if neither a global variable nor environment variable was found.

=head1 METHODS

=head2 import

This routine takes an optional hash of options for all constants, followed by
an option list (see L<Data::OptList>) of constant names.

For example:

  use Constant::FromGlobal { env => 1 }, "DSN", MAX_FOO => { int => 1, default => 3 };

is the same as

  use Constant::FromGlobal DSN => { env => 1 }, MAX_FOO => { int => 1, default => 3, env => 1 };

which will define two constants, C<DSN> and C<MAX_FOO>. C<DSN> is a string and
C<MAX_FOO> is an integer. Both will take their values from C<$Foo::DSN> if
defined or C<$ENV{FOO_DSN}> as a fallback.

Note: if you define constants in the B<main> namespace, version 0.01 of this module
looked for environment variables prefixed with C<MAIN_>. From version 0.02 onwards,
you don't need the C<MAIN_> prefix.

There are three types you can specify for constants:

=over 4

=item * B<int> - constains the constant to take an integer value.
Will croak if a non-integer value is found.

=item * B<num> - constains the constant to take a numeric value.
Will croak if a non-numeric value is found.

=item * B<bool> - coerces the constant to take a boolean value.
Whatever value is found will be converted to a boolean value.

=back

=head1 SEE ALSO

L<constant> -
core module for defining constants, and used by C<Constant::FromGlobal>.

L<constant::lexical> -
very similar to the C<constant> pragma, but defines lexically-scoped constants.

L<Const::Fast> -
CPAN module for defining immutable variables (scalars, hashes, and arrays).

L<Adam Kennedy's original post|http://use.perl.org/use.perl.org/_Alias/journal/39845.html>
that inspired this module.

L<constant modules|http://neilb.org/reviews/constants.html> -
A review of all perl modules for defining constants, by Neil Bowers.


=head1 REPOSITORY

L<https://github.com/neilb/Constant-FromGlobal>

=head1 AUTHOR

This module was originally written by Yuval Kogman,
inspired by a blog post by Adam Kennedy,
describing the "Constant Global" pattern.

The module is now being maintained by Neil Bowers E<lt>neilb@cpan.orgE<gt>.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

