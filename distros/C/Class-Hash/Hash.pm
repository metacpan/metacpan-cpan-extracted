package Class::Hash;

use 5.008;
use strict;
use warnings;

use Carp;
use Tie::Hash;

our $VERSION = '1.01';

=head1 NAME

Class::Hash - Perl extension for hashes that look like classes

=head1 SYNOPSIS

  use Class::Hash ALL_METHODS => 1;

  $hash = Class::Hash->new(foo => 'bar');

  print "foo: ",$hash->foo,"\n"; # prints "foo: bar"

  $hash->hello = "World";
  print "Hello ",$hash->hello,"!\n"; # prints "Hello World!"

  # Other accessor methods
  $hash->store("foo", "something else");
  $foo = $hash->fetch("foo");

  # Or just use it like a plain hash ref!
  $stuff->{foo} = "whoa dude!";

=head1 ABSTRACT

  This component provides a method-based interface to a hash. Occasionally, it's
  more convenient to have named methods to access a hash than hash keys. This
  module generalizes this behavior.

=head1 DESCRIPTION

This component provides a method-based interface to a hash. Occasionally, it's
more convenient to have named methods to access a hash than hash keys. This
module generalizes this behavior. It tries to work the tied hash interface
inside-out.

This module tries to do as much or as little for you as you want and provides a
number of configuration options. The options allow you to determine what kind
of interface the object has. The interface may also be altered after-the-fact.
See L</OPTIONS> for details.

=head1 METHODS

=over

=item use Class::Hash [ %default_options ];

When telling Perl to C<use> C<Class::Hash>, you may specify any default options
that should be made available. By default, all options are I<off>--giving you
the simplest set of features. The default options can be modified per-instance
and options can be modified after instantiation via C<options>.

For more information on the options, see L</OPTIONS>.

=cut

our $AUTOLOAD;
my %meta_options = (
	METHOD_BASED	=> [ qw( no_named_accessors fetch store delete clear exists each keys values ) ],
	ALL_METHODS		=> [ qw( fetch store delete clear exists each keys values ) ],
);

# We don't want this to be exposed in the Class::Hash package
my $process_options = sub {
	my ($options) = @_;

	for my $key (keys %meta_options) {
		if (defined $$options{$key}) {
			$$options{$_} = $$options{$key} for (@{$meta_options{$key}});
			delete $$options{$key};
		}
	}

	$options;
};

my %defaults;
sub import : lvalue {
	if (ref $_[0]) {
		$AUTOLOAD = (ref $_[0]).'::import';
		return shift->AUTOLOAD(@_);
	}
	
	my $class = shift;
	my %options;
	if (ref $_[0] eq 'HASH') {
		%options = %{$_[0]};
	} else {
		%options = @_;
	}

	%defaults = %{ &$process_options(\%options) };
}

=item $hash = Class::Hash-E<gt>new( [ %hash ] [, \%options ] )

This initializes a particular "hash". The first list of arguments are the
initial key/value pairs to set in the hash. If none are given, the hash is
initially empty.

The second argument is also optional. It is a hash reference containing the
optiosn to set on this instance of the hash. If not options are given, then the
defaults set during import are used. FOr more information on the options, see
L</OPTIONS>.

I<NB>: It should be noted that:

  $hash = Class::Hash->new;

is not the same as:

  $hash2 = $hash->new;

The first will be treated as a constructor and the second as an accessor.

=cut

sub new : lvalue {
	if (ref $_[0]) {
		$AUTOLOAD = (ref $_[0]).'::new';
		return shift->AUTOLOAD(@_);
	}

	my ($class, @args) = @_;

	my $options = { %defaults };
	tie my %self, 'Tie::ExtraHash', $options;
	for (my $i = 0; $i < @args;) {
		if (ref $args[$i] eq 'HASH') {
			my $opts = &$process_options($args[$i]);
			while (my ($k, $v) = each %$opts) {
				$$options{$k} = $v;
			}

			++$i;
		} else {
			$self{$args[$i]} = $args[$i + 1];
			$i += 2;
		}
	}

	my $result = bless \%self, $class;
}	

=item $value = $hash-E<gt>I<accessor> [ ($new_value) ]

=item $value = Class::Hash-E<gt>I<accessor> [ ($hash, $new_value) ]

This method is the accessor for the hash-key named I<accessor>. This can be any
valid Perl symbol and is the simplest way of accessing values in the hash. The
current value is returned by the accessor--which is first set to C<$new_value>
if specified.

It is possible to disable the named accessor syntax by setting the
"no_named_accessors" option. See the L</OPTIONS> section for details.

=cut

sub AUTOLOAD : lvalue {
	my ($sub) = $AUTOLOAD =~ /([^:]+)$/;
	if (ref $_[0]) {
		croak "Undefined subroutine &$AUTOLOAD called"
			if (tied %{$_[0]})->[1]{no_named_accessors};

		my $self = shift;
		$self->{$sub} = pop if @_ > 0;
		return $self->{$sub};
	} else {
		my $class = shift;
		my $self = shift;
		$self->{$sub} = pop if @_ > 0;
		return $self->{$sub};
	}
}

sub DESTROY { }

=item $value = $hash-E<gt>fetch($name)

=item $value = Class::Hash-E<gt>fetch [ ($hash, $new_value) ]

This is the get accessor for the hash key named C<$name>. This fetches the
current value stored in C<$name>. This accessor is only available when the
"fetch" option is set. See the L</OPTIONS> section for details.

=cut

sub fetch : lvalue {
	if (ref $_[0]) {
		my $self = shift;
		if ((tied %$self)->[1]{fetch}) {
			my $name = shift;
			return $self->{$name};
		} else {
			$AUTOLOAD = (ref $self).'::get';
			return $self->AUTOLOAD(@_);
		}
	} else {
		my ($class, $self, $name) = @_;
		return $self->{$name};
	}
}

=item $hash-E<gt>store($name, $new_value)

=item $hash-E<gt>store($name) = $new_value

=item Class::Hash-E<gt>store($hash, $name, $new_value)

=item Class::Hash-E<gt>store($hash, $name) = $new_value

This is the set accessor for the hash key named C<$name>. This sets the current
value to be stored in C<$name>. This accessor is only available when the
"store" option is set. See the L</OPTIONS> section for details.

=cut

sub store : lvalue {
	if (ref $_[0]) {
		my $self = shift;
		if ((tied %$self)->[1]{store}) {
			my $name = shift;
			$self->{$name} = pop if @_ > 0;
			return $self->{$name};
		} else {
			$AUTOLOAD = (ref $self).'::store';
			return $self->AUTOLOAD(@_);
		}
	} else {
		my ($class, $self, $name, @values) = @_;
		$self->{$name} = pop if @_ > 0;
		return $self->{$name};
	}
}

=item $old_value = $hash-E<gt>delete($name)

=item $old_value = Class::Hash-E<gt>delete($hash, $name)

Deletes the value associated with the given key C<$name>. This method is only
available when the "delete" option is set. See the L</OPTIONS> section for
details.

=cut

sub delete : lvalue {
	if (ref $_[0]) {
		my $self = shift;
		if ((tied %$self)->[1]{'delete'}) {
			return my @deleted = delete @$self{@_};
		} else {
			$AUTOLOAD = (ref $self).'::delete';
			return $self->AUTOLOAD(@_);
		}
	} else {
		my $class = shift;
		my $self = shift;
		return my @deleted = delete @$self{@_};
	}
}

=item $hash-E<gt>clear

=item Class::Hash-E<gt>clear($hash)

Clears all values from the hash. This method is only available when the "clear"
option is set. See L</OPTIONS> for details.

=cut

sub clear : lvalue {
	if (ref $_[0]) {
		my $self = shift;
		if ((tied %$self)->[1]{clear}) {
			return %$self = ();
		} else {
			$AUTOLOAD = (ref $self).'::clear';
			return $self->AUTOLOAD(@_);
		}
	} else {
		my $class = shift;
		my $self = shift;
		return %$self = ();
	}
}

=item $hash-E<gt>exists($name)

=item Class::Hash-E<gt>exists($hash, $name)

Determines whether the given hash key has been set--even if it has been set to
C<undef>. This method is only available when the "exists" option is set. See
L</OPTIONS> for details.

=cut

sub exists : lvalue {
	if (ref $_[0]) {
		my $self = shift;
		if ((tied %$self)->[1]{'exists'}) {
			my $name = shift;
			return my $test = exists $self->{$name};
		} else {
			$AUTOLOAD = (ref $self).'::exists';
			return $self->AUTOLOAD(@_);
		}
	} else {
		my $class = shift;
		my $self = shift;
		my $name = shift;
		return my $test = exists $self->{$name};
	}
}

=item ($key, $value) = $hash-E<gt>each

=item ($key, $value) = Class::Hash-E<gt>each($hash)

Iterates through all pairs in the hash. This method is only available when the
"each" option is set. See L</OPTIONS> for details.

=cut

sub each : lvalue {
	if (ref $_[0]) {
		my $self = shift;
		if ((tied %$self)->[1]{'each'}) {
			return my @pair = each %$self;
		} else {
			$AUTOLOAD = (ref $self).'::nextkey';
			return $self->AUTOLOAD(@_);
		}
	} else {
		my $class = shift;
		my $self = shift;
		return my @pair = each %$self;
	}
}

=item @keys = $hash-E<gt>keys

=item @keys = $hash-E<gt>keys($hash)

Returns all keys for the hash. This method is only available when the "keys"
option is set. See L</OPTIONS> for details.

=cut

sub keys : lvalue {
	if (ref $_[0]) {
		my $self = shift;
		if ((tied %$self)->[1]{'keys'}) {
			return my @keys = keys %$self;
		} else {
			$AUTOLOAD = (ref $self).'::keys';
			return $self->AUTOLOAD(@_);
		}
	} else {
		my $class = shift;
		my $self = shift;
		return my @keys = keys %$self;
	}
}

=item @values = $hash-E<gt>values

=item @values = $hash-E<gt>values($hash)

Returns all values for the hash. This method is only available when the
"values" option is set. See L</OPTIONS> for details.

=cut

sub values : lvalue {
	if (ref $_[0]) {
		my $self = shift;
		if ((tied %$self)->[1]{'values'}) {
			return my @values = values %$self;
		} else {
			$AUTOLOAD = (ref $self).'::values';
			return $self->AUTOLOAD(@_);
		}
	} else {
		my $class = shift;
		my $self = shift;
		return my @values = values %$self;
	}
}

=item $options = Class::Hash-E<gt>options($hash)

=item Class::Hash-E<gt>options($hash)-E<gt>{option} = $option

This returns the options currently set on the hash. See L</OPTIONS> for
details.

=cut

sub options : lvalue {
	my $class = shift;
	my $self = shift;
	return (tied %$self)->[1];
}

=item $options = Class::Hash-E<gt>defaults

=item Class::Hash-E<gt>defaults-E<gt>{option} = $option

This returns the default options set on the hash. Making changes to the
returned value will effect all instances of Class::Hash constructed after
the change is made. Any existing instances are not modified.

=cut

sub defaults : lvalue {
	my $class = shift;
	return my $defaults = \%defaults;
}

=back

=head1 OPTIONS

There are two types of options that may be set on Class::Hash objects: method
options and aggregate options. The method options determine the presence or
absence of various methods that may be defined in the Class::Hash object--see
L</BUGS> because this isn't strictly correct. The aggregate options alter the
settings of more than one other options.

=head2 METHOD OPTIONS

It should be noted that there are two possible syntaxes for calling most of the
Class::Hash methods. The first is the typical object syntax and the other is a
class/object syntax. The object syntax is available for all methods but
C<options>. However, the object syntax is only available when it is turned on
by the matching option. The class/object syntax (always listed second when both
are possible) is always available regardless of option settings--but is far
less pretty.

=over

=item no_named_accessors

When set, this option eliminates the use of named accessors. This will result in
an exception being raiesed when access is attempted. For example:

  $bob = new Class::Hash(foo => 'bar');
  $foo = $bob->foo; # works!

  $fred = new Class::Hash(bar => 'foo', { no_named_accessors => 1 });
  $bar = $fred->bar; ### <--- ERROR! Undefined subroutine &Class::Hash::bar called

=item fetch

When set, this option adds the use of the C<fetch> accessor.

=item store

When set, this option adds the use of the C<store> accessor.

=item delete

When set, this option adds the use of the C<delete> method.

=item clear

When set, this option adds the use of the C<clear> method.

=item exists

When set, this option adds the use of the C<exists> method.

=item each

When set, this option adds the use of the C<each> method.

=item keys

When set, this option adds the use of the C<keys> method.

=item values

When set, this option adds the use of the C<values> method.

=back

=head2 AGGREGATE OPTIONS

All aggregate option names are in all caps to suggest that you're turning on or
off lots of stuff at once. Aggregate options always work one way, they do not
have the effect of turning some things on and some stuff off. This would be too
confusing.

=item METHOD_BASED

This option affects the following: C<no_named_accessors>, C<fetch>, C<store>, 
C<delete>, C<clear>, C<exists>, C<each>, C<keys>, and C<values>.

=item ALL_METHODS

This option affects the following: C<fetch>, C<store>, C<delete>, C<clear>,
C<exists>, C<each>, C<keys>, and C<values>.

=head1 BUGS

The nastiest part of this module is the way C<AUTOLOAD> and other methods are
made available. All the methods defined that aren't named accessors (such as
C<fetch>, C<store>, C<delete>, C<clear>, etc.) are defined as subroutines
whether they are "turned on" via options or not. This won't make a difference
99% of the time as the methods Do-The-Right-Thing(tm). However, when attempting
to use L<can|UNIVERSAL/can>, everything will be screwed up.

I would like to modify the system to have the methods only defined
per-instance, but that would require the ability to load and unload method
definitions on-the-fly per-instance. Something that might be possible, but
would require some very odd finagling to achieve it, so I've stuck with the
It-Works-For-Me(tm) method or
It-Works-If-You-Just-Use-It-And-Don't-Try-To-Be-Funny(tm) method. :-)

Another problem is that this is currently set to require Perl 5.8.0. I don't
know if this is really necessary, but I'm too lazy to find out right now.
Because of the lvalue attribute set on C<AUTOLOAD>, it does require 5.7.1,
which is almost the same as requiring 5.8.0.

There are probably some nasty documentation bugs. I didn't go back through
and carefully proofread the documentation after I changed the implementation
mid-way through.

=head1 AUTHOR

Andrew Sterling Hanenkamp, E<lt>hanenkamp@users.sourceforge.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by Andrew Sterling Hanenkamp

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

1
