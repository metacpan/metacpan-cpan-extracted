package Class::Delegator;

# $Id: Delegator.pm 3912 2008-05-15 03:33:00Z david $

use strict;

$Class::Delegator::VERSION = '0.09';

=begin comment

Fake-out Module::Build. Delete if it ever changes to support =head1 headers
other than all uppercase.

=head1 NAME

Class::Delegator - Simple and fast object-oriented delegation

=end comment

=head1 Name

Class::Delegator - Simple and fast object-oriented delegation

=head1 Synopsis

  package Car;

  use Class::Delegator
      send => 'start',
        to => '{engine}',

      send => 'power',
        to => 'flywheel',
        as => 'brake',

      send => [qw(play pause rewind fast_forward shuffle)],
        to => 'ipod',

      send => [qw(accelerate decelerate)],
        to => 'brakes',
        as => [qw(start stop)],

      send => 'drive',
        to => [qw(right_rear_wheel left_rear_wheel)],
        as => [qw(rotate_clockwise rotate_anticlockwise)]
  ;


=head1 Description

This module provides a subset of the functionality of Damian Conway's lovely
L<Class::Delegation|Class::Delegation> module. Why a subset? Well, I didn't
need all of the fancy matching semantics, just string string specifications to
map delegations. Furthermore, I wanted it to be fast (See
L<Benchmarks|"Benchmarks">). And finally, since Class::Delegation uses an
C<INIT> block to do its magic, it doesn't work in persistent environments that
don't execute C<INIT> blocks, such as in L<mod_perl|mod_perl>.

However the specification semantics of Class::Delegator differ slightly from
those of Class::Delegation, so this module isn't a drop-in replacement for
Class::Delegation. Read on for details.

=head2 Specifying methods to be delegated

The names of methods to be redispatched can be specified using the C<send>
parameter. This parameter may be specified as a single string or as an array
of strings. A single string specifies a single method to be delegated, while
an array reference is a list of methods to be delegated.

=head2 Specifying attributes to be delegated to

Use the C<to> parameter to specify the attribute(s) or accessor method(s) to
which the method(s) specified by the C<send> parameter are to be delegated.
The semantics of the C<to> parameter are a bit different from
Class::Delegation. In order to ensure the fastest performance possible, this
module simply installs methods into the calling class to handle the
delegation. There is no use of C<$AUTOLOAD> or other such trickery. But since
the new methods are installed by C<eval>ing a string, the C<to> parameter for
each delegation statement must be specified in the manner appropriate to
accessing the underlying attribute. For example, to delegate a method call to
an attribute stored in a hash key, simply wrap the key in braces:

  use Class::Delegator
      send => 'start',
        to => '{engine}',
  ;

To delegate to a method, simply name the method:

  use Class::Delegator
      send => 'power',
        to => 'flywheel',
  ;

If your objects are array-based, wrap the appropriate array index number in
brackets:

  use Class::Delegator
      send => 'idle',
        to => '[3]',
  ;

And so on.

=head2 Specifying the name of a delegated method

Sometimes it's necessary for the name of the method that's being delegated to
be different from the name of the method to which you're delegating execution.
For example, your class might already have a method with the same name as the
method to which you're delegating. The C<as> parameter allows you translate
the method name or names in a delegation statement. The value associated with
an C<as> parameter specifies the name of the method to be invoked, and may be
a string or an array (with the number of elements in the array matching the
number of elements in a corresponding C<send> array).

If the attribute is specified via a single string, that string is taken as the
name of the attribute to which the associated method (or methods) should be
delegated. For example, to delegate invocations of C<$self-E<gt>power(...)> to
C<$self-E<gt>{flywheel}-E<gt>brake(...)>:

  use Class::Delegator
      send => 'power',
        to => '{flywheel}',
        as => 'brake',
  ;

If both the C<send> and the C<as> parameters specify array references, each
local method name and deleted method name form a pair, which is invoked. For
example:

  use Class::Delegator
      send => [qw(accelerate decelerate)],
        to => 'brakes',
        as => [qw(start stop)],
  ;

In this example, the C<accelerate> method will be delegated to the C<start>
method of the C<brakes> attribute and the C<decelerate> method will be
delegated to the C<stop> method of the C<brakes> attribute.

=head2 Delegation to multiple attributes in parallel

An array reference can be used as the value of the C<to> parameter to specify
the a list of attributes, I<all of which> are delegated to--in the same order
as they appear in the array. In this case, the C<send> parameter B<must> be a
scalar value, not an array of methods to delegate.

For example, to distribute invocations of C<$self-E<gt>drive(...)> to both
C<$self-E<gt>{left_rear_wheel}-E<gt>drive(...)> and
C<$self-E<gt>{right_rear_wheel}-E<gt>drive(...)>:

  use Class::Delegator
      send => 'drive',
        to => ["{left_rear_wheel}", "{right_rear_wheel}"]
  ;

Note that using an array to specify parallel delegation has an effect on the
return value of the delegation method specified by the C<send> parameter. In a
scalar context, the original call returns a reference to an array containing
the (scalar context) return values of each of the calls. In a list context,
the original call returns a list of array references containing references to
the individual (list context) return lists of the calls. So, for example, if
the C<cost> method of a class were delegated like so:

  use Class::Delegator
      send => 'cost',
        to => ['supplier', 'manufacturer', 'distributor']
  ;

then the total cost could be calculated like this:

  use List::Util 'sum';
  my $total = sum @{$obj->cost()};

If both the C<"to"> key and the C<"as"> parameters specify multiple values,
then each attribute and method name form a pair, which is invoked. For
example:

  use Class::Delegator
      send => 'escape',
        to => ['{flywheel}', '{smokescreen}'],
        as => ['engage',   'release'],
  ;

would sequentially call, within the C<escape()> delegation method:

  $self->{flywheel}->engage(...);
  $self->{smokescreen}->release(...);

=cut

##############################################################################

sub import {
    my $class = shift;
    my ($caller, $filename, $line) = caller;
    while (@_) {
        my ($key, $send) = (shift, shift);
        _die(qq{Expected "send => <method spec>" but found "$key => $send"})
          unless $key eq 'send';

        ($key, my $to) = (shift, shift);
        _die(qq{Expected "to => <attribute spec>" but found "$key => $to"})
          unless $key eq 'to';

        _die('Cannot specify both "send" and "to" as arrays')
          if ref $send && ref $to;

        if (ref $to) {
            my $as = ($_[0] || '') eq 'as' ? (shift, shift) : undef;
            if (ref $as) {
                _die('Arrays specified for "to" and "as" must be the same length')
                  unless @$to == @$as;
            } elsif (defined $as) {
                _die('Cannot specify "as" as a scalar if "to" is an array')
            } else {
                $as = [];
            }

            my $meth = "$caller\::$send";
            my @lines =  (
                # Copy @_ to @args to ensure same args passed to all methods.
                "#line $line $filename",
                "sub { local \*__ANON__ = '$meth';",
                'my ($self, @args) = @_;',
                'my @ret;',
            );
            my @array = (
                'return (',
            );
            my @scalar = (
                ') if wantarray;',
                'return [',
            );

            while (@$to) {
                my $t = shift @$to;
                my $m = shift @$as || $send;
                push @scalar, "scalar \$self->$t->$m(\@args),";
                push @array,  "[\$self->$t->$m(\@args)],";
            }
            no strict 'refs';
            *{$meth} = eval join "\n", @lines, @array, @scalar, ']', '}';

        } else {
            my $as = ($_[0] || '') eq 'as'
              ? (shift, ref $_[0] ? shift : [shift])
              : [];
            $send = [$send] unless ref $send;

            while (@$send) {
                my $s    = shift @$send;
                my $m    = shift @$as || $s;
                my $meth = "$caller\::$s";
                no strict 'refs';
                *{$meth} = eval qq{#line $line $filename
                    sub {
                        local \*__ANON__ = '$meth';
                        shift->$to->$m(\@_);
                    };
                };
            }
        }
    }
}

sub _die {
    require Carp;
    Carp::croak(@_);
}

##############################################################################

=head1 Benchmarks

I whipped up a quick script to compare the performance of Class::Delegator to
Class::Delegation and a manually-installed delegation method (the control).
I'll let the numbers speak for themselves:

  Benchmark: timing 1000000 iterations of Class::Delegation, Class::Delegator, Manually...
  Class::Delegation: 106 wallclock secs (89.03 usr +  2.09 sys = 91.12 CPU) @ 10974.54/s  (n=1000000)
  Class::Delegator:    3 wallclock secs ( 3.44 usr +  0.02 sys =  3.46 CPU) @ 289017.34/s (n=1000000)
           Control:    3 wallclock secs ( 3.01 usr +  0.02 sys =  3.03 CPU) @ 330033.00/s (n=1000000)

=head1 Bugs

Please send bug reports to <bug-class-delegator@rt.cpan.org> or report them
via the CPAN Request Tracker at
L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Class-Delegator>.

=head1 Author

=begin comment

Fake-out Module::Build. Delete if it ever changes to support =head1 headers
other than all uppercase.

=head1 AUTHOR

=end comment

David Wheeler <david@kineticode.com>

=head1 See Also

=over

=item L<Class::Delegation|Class::Delegation>

Damian Conway's brilliant module does ten times what this one does--and does
it ten times slower.

=item L<Class::Delegate|Class::Delegate>

Kurt Starsinic's module uses inheritance to manage delegation, and has a
somewhat more complex interface.

=item L<Class::HasA|Class::HasA>

Simon Cozen's delegation module takes the same approach as this module, but
provides no method for resolving method name clashes the way this module's
C<as> parameter does.

=back

=head1 Copyright and License

Copyright (c) 2005-2008 David Wheeler. Some Rights Reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
