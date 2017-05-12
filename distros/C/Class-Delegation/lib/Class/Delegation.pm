package Class::Delegation;

our $VERSION = '1.9.0';

use strict;
use Carp;

sub ::DEBUG { 0 };

my %mappings;

sub import {
	my $class = shift;
	my $caller = caller();
	while (@_) {
		push @{$mappings{$caller}}, Class::Delegation::->_new(\@_);
	}
}

INIT {
	foreach my $class (keys %mappings) {
		_install_delegation_for($class);
	}
}

sub _install_delegation_for {
	use vars '$AUTOLOAD';
	no strict 'refs';
	my ($class) = @_;
	my $symbol = "${class}::AUTOLOAD";
	print STDERR "Installing $symbol\n" if ::DEBUG;
	my $real_AUTOLOAD = *{$symbol}{CODE}
			 || sub {croak "Could not delegate $AUTOLOAD"};
		
	local $SIG{__WARN__} = sub {};
	*$symbol = sub {
		$$symbol = $AUTOLOAD;
		my ($class, $method) = $AUTOLOAD =~ m/(.*::)(.*)/;
		my ($invocant, @args) = @_;
		print STDERR "Delegating: $AUTOLOAD...\n" if ::DEBUG;
		use Data::Dumper 'Dumper';
		print STDERR "...on: ", Dumper $invocant if ::DEBUG;
		my @context = ($invocant, $method, @args);
		$invocant = "${class}${invocant}" unless ref $invocant;
		my $wantarray = wantarray;
		my @delegators = _delegators_for(@context);
		goto &{$real_AUTOLOAD} unless @delegators;
		my (@results, $delegated);
		DELEGATOR: foreach my $delegator ( @delegators ) {
			next if $delegator->{other} && keys %$delegated;
			my @to = @{$delegator->{to}};
			my @as = @{$delegator->{as}}; 
			if (@to==1) {
				print STDERR "[$to[0]]\n" if ::DEBUG;
				next DELEGATOR if exists $delegated->{$to[0]};
				foreach my $as (@as) {
					push @results, delegate($delegated,$wantarray,$invocant,$to[0],$as,\@args);
				}
			}
			elsif (@as==1) {
				print STDERR "[$to[0]]\n" if ::DEBUG;
				foreach my $to (@to) {
					next if exists $delegated->{$to};
					push @results, delegate($delegated,$wantarray,$invocant,$to,$as[0],\@args);
				}
			}
			else {
				while (1) {
					last unless @to && @as;
					my $to = shift @to;
					my $as = shift @as;
					next if exists $delegated->{$to};
					push @results, delegate($delegated,$wantarray,$invocant,$to,$as,\@args);
				}
			}
		}
		goto &{$real_AUTOLOAD} unless keys %$delegated;
		return $wantarray
			? ( @results>1 ? @results : @{$results[0]} )
			: ( @results>1 ? \@results : $results[0] );
	};

	unless (*{"${class}::DESTROY"}{CODE} ||
		_delegators_for($class,'DESTROY')) {
		*{"${class}::DESTROY"} = sub {};
	}
}

sub delegate {
	my ($delegated,$wantarray,$invocant,$to,$as,$args) = @_;
	no strict 'refs';
	my $target = ref $to            ? $to
		   : $to =~ /^->(\w+)$/ ? $invocant->$+()
		   : $to eq -SELF       ? $invocant
		   :                      $invocant->{$to};
	return unless eval {
		$target->can($as)  || $target->can('AUTOLOAD')
	};
	my $result = $wantarray
			? [$target->$as(@$args)]
			: $target->$as(@$args);
	return if $@;
	$_[0]->{$to}++;
	return $result
}

sub _delegators_for {
	my ($self, $method, @args) = @_;

	my @attrs;
	my $class = ref($self)||$self;
	foreach my $candidate ( @{$mappings{$class}} ) {
		push @attrs, $candidate->{send}->can_send(scalar(@attrs),
							  $candidate->{to},
							  $candidate->{as},
							  @_);
	}
	return @attrs if @attrs;
        no strict 'refs';
	my @ancestors = @{$class.'::ISA'};
	my $parent;
	while ($parent = shift @ancestors) {
	    next unless exists $mappings{$parent};
	    foreach my $candidate ( @{$mappings{$parent}} ) {
		push @attrs, $candidate->{send}->can_send(scalar(@attrs),
							  $candidate->{to},
							  $candidate->{as},
							  @_);
	    }
	    return @attrs if @attrs;
	    unshift @ancestors, @{$parent.'::ISA'};
	}
	return @attrs;
}

sub _new {
	my ($class, $args) = @_;
	my ($send, $send_val) = splice @$args, 0, 2;
	croak "Expected 'send => <method spec>' but found '$send => $send_val'"
		unless $send eq 'send';
	croak "The expected 'to => <attribute spec>' is missing at end of list"
		unless @$args >= 2;
	my ($to, $to_val) = splice @$args, 0, 2;
	croak "Expected 'to => <attribute spec>' but found '$to => $to_val'"
		unless $to eq 'to';

	$send_val  = _class_for(Send => $send_val)->_new($send_val);
	my $to_obj = _class_for(To => $to_val)->_new($to_val);
	my $self = bless { send=>$send_val, to=>$to_obj }, $class;
	if (($args->[0]||"") eq 'as') {
		my ($as, $as_val) = splice @$args, 0, 2;
		croak "Arrays specified for 'to' and 'as' must be same length"
			unless ref($to_val) ne 'ARRAY'
			    || ref($as_val) ne 'ARRAY'
			    || @$to_val == @$as_val;
		$self->{as} = _class_for(As => $as_val)->_new($as_val);
	}
	else {
		croak "'to => -SELF' is meaningless without 'as => <new_name>'"
			if $to_val eq -SELF;
		$self->{as} = Class::Delegation::As::Sent->_new();
	}
	return $self;
}

my %allowed;
@{$allowed{Send}}{qw(ARRAY Regexp CODE)} = ();
@{$allowed{To}}{qw(ARRAY Regexp CODE)} = ();
@{$allowed{As}}{qw(ARRAY CODE)} = ();

sub _class_for {
	my ($subclass, $value) = @_;
	my $type = ref($value);
	return "Class::Delegation::${subclass}::SCALAR" unless $type;
	croak "'\l$subclass' value cannot be $type reference"
		unless exists $allowed{$subclass}{$type};
	return "Class::Delegation::${subclass}::${type}";
}

package # Hide from CPAN indexer
SELF;

sub DESTROY {}
sub AUTOLOAD {
	my ($name) = $SELF::AUTOLOAD =~ m/.*::(.+)/;
	bless \$name, 'SELF'
}
use overload 'neg' => sub { "->${$_[0]}" };


package Class::Delegation::Send::SCALAR;

sub _new {
	return bless {}, "Class::Delegation::Send::ALL" if $_[1] eq '-ALL';
	return bless {}, "Class::Delegation::Send::OTHER" if $_[-1] eq '-OTHER';
	my $val = pop;
	return bless \$val, $_[0]
}

sub can_send {
	my ($self, $sent, $to, $as, @context) = @_;
	return { to => [$to->attr_for(@context)],
		 as => [$as->name_for(@context)],
	       }
		if $$self eq $context[1];
	return;
}


package Class::Delegation::Send::ARRAY;

sub _new {
	my @delegators =
	    map { Class::Delegation::_class_for(Send => $_)->_new($_) } @{$_[1]};
	bless \@delegators, $_[0];
}

sub can_send {
	my ($self, @context) = @_;
	return map { $_->can_send(@context) } @$self;
}


package Class::Delegation::Send::Regexp;

sub _new {
	my ($class, $regex) = @_;
	my $self = bless \$regex, $class;
	return $self;
}


sub can_send {
	my ($self, $sent, $to, $as, @context) = @_;
	return { to => [$to->attr_for(@context)],
		 as => [$as->name_for(@context)],
	       }
		if $context[1] =~ $$self;
	return;
}


package Class::Delegation::Send::CODE;

sub _new { bless $_[1], $_[0] }

sub can_send {
	my ($self, $sent, $to, $as, @context) = @_;
	return { to => [$to->attr_for(@context)],
		 as => [$as->name_for(@context)],
	       }
		if $self->(@context);
	return;
}

package Class::Delegation::Send::ALL;

sub can_send {
	my ($self, $sent, $to, $as, @context) = @_;
	return { to => [$to->attr_for(@context)],
		 as => [$as->name_for(@context)],
	       }
		if $context[1] ne 'DESTROY';
	return;
}

package Class::Delegation::Send::OTHER;

sub can_send { 
	my ($self, $sent, $to, $as, @context) = @_;
	return { to => [$to->attr_for(@context)],
		 as => [$as->name_for(@context)],
		 other => 1,
	       }
		if $context[1] ne 'DESTROY';
	return;
}

   
package Class::Delegation::To::SCALAR;

sub _new {
	my ($class, $value) = @_;
	return bless {}, "Class::Delegation::To::ALL" if $value eq '-ALL';
	return bless \$value, $class
}

sub attr_for { return ${$_[0]} }


package Class::Delegation::To::ARRAY;

sub _new {
	my ($class, $array) = @_;
	bless [ map {("Class::Delegation::To::".(ref||"SCALAR"))->_new($_)} @$array ], $class;
}

sub attr_for {
	my ($self, @context) = @_;
	return map { $_->attr_for(@context) } @$self;
}

package Class::Delegation::To::Regexp;

sub _new {
	my ($class, $regex) = @_;
	my $self = bless \$regex, $class;
	return $self;
}

sub attr_for {
	my ($self, $invocant, @context) = @_;
	print STDERR "[[$$self]]\n" if ::DEBUG;
	return grep {  $_ =~ $$self } keys %$invocant;
}


package Class::Delegation::To::CODE;

sub _new { bless $_[1], $_[0] }

sub attr_for {
	my ($self, @context) = @_;
	return $self->(@context)
}


package Class::Delegation::To::ALL;

sub attr_for {
	my ($self, $invocant, @context) = @_;
	return keys %$invocant;
}



package Class::Delegation::As::SCALAR;

sub _new {
	my ($class, $value) = @_;
	bless \$value, $class;
}

sub name_for { ${$_[0]} }

package Class::Delegation::As::ARRAY;

sub _new {
	my ($class, $value) = @_;
	bless $value, $class;
}

sub name_for { @{$_[0]} }


package Class::Delegation::As::Sent;

sub _new { bless {}, $_[0] }

sub name_for {
	my ($self, $invocant, $method) = @_;
	return $method;
}

package Class::Delegation::As::CODE;

sub _new { bless $_[1], $_[0] }

sub name_for {
	my ($self, @context) = @_;
	return $self->(@context)
}

1;

__END__

=head1 NAME

Class::Delegation - Object-oriented delegation 

=head1 VERSION

This document describes version 1.9.0 of Class::Delegation
released April 23, 2002.

=head1 SYNOPSIS

        package Car;

        use Class::Delegation
                send => 'steer',
                  to => ["left_front_wheel", "right_front_wheel"],

                send => 'drive',
                  to => ["right_rear_wheel", "left_rear_wheel"],
		  as => ["rotate_clockwise", "rotate_anticlockwise"]

                send => 'power',
                  to => 'flywheel',
                  as => 'brake',

                send => 'brake',
                  to => qr/.*_wheel$/,

		send => 'halt'
		  to => -SELF,
		  as => 'brake',

                send => qr/^MP_(.+)/,
                  to => 'mp3',
                  as => sub { $1 },

                send => -OTHER,
                  to => 'mp3',

                send => 'debug',
                  to => -ALL,
                  as => 'dump',

                send => -ALL,
                  to => 'logger',
                ;


=head1 BACKGROUND

[Skip to L<"DESCRIPTION"> if you don't care why this module exists]

Inheritance is one of the foundations of object-oriented programming. But
inheritance has a fundamental limitation: a class can only directly inherit
once from a given parent class. This limitation occasionally
leads to awkward work-arounds like this:

	package Left_Front_Wheel;   use base qw( Wheel );
	package Left_Rear_Wheel;    use base qw( Wheel );
	package Right_Front_Wheel;  use base qw( Wheel );
	package Right_Rear_Wheel;   use base qw( Wheel );

	package Car;                use base qw(Left_Front_Wheel
						Left_Rear_Wheel 
						Right_Front_Wheel
						Right_Rear_Wheel);

Worse still, the method dispatch semantics of most languages (including Perl)
require that only a single inherited method (in Perl, the one that is
left-most-depth-first in the inheritance tree) can handle a particular
method invocation. So if the Wheel class provides methods to steer a
wheel, drive a wheel, or stop a wheel, then calls such as:

        $car->steer('left');
        $car->drive(+55);
        $car->brake('hard');

will only be processed by the left front wheel.  This will probably not 
produce desirable road behaviour.

It is often argued that it is simply a synecdochic mistake to treat a
car as a specialized form of four wheels, but this argument is
I<far> from conclusive. And, regardless of its philosophical merits, programmers often do conceptualize
composite systems in exactly this way.

The alternative is, of course, to make the four wheels I<attributes> of the
class, rather than I<ancestors>:

        package Car;

        sub new {
                bless { left_front_wheel  => Wheel->new('steer', 'brake'),
                        left_rear_wheel   => Wheel->new('drive', 'brake'),
                        right_front_wheel => Wheel->new('steer', 'brake'),
                        right_rear_wheel  => Wheel->new('drive', 'brake'),
                      }, $_[0];
        }

Indeed some object-oriented languages (e.g. Self) do away with
inheritance entirely and rely exclusively on the use of attributes to
implement class hierarchies.


=head2 The problem(s) with attribute-based hierarchies

Using attributes instead of inheritance does solve the problem:
it allows a Car to directly have four wheels. However, this solution
creates a new problem: it requires that the class manually redispatch (or
I<delegate>) every method call:

        sub steer {
                my $self = shift;
                return ( $self->{left_front_wheel}->steer(@_),
                         $self->{right_front_wheel}->steer(@_), );
        }

        sub drive {
                my $self = shift;
                return ( $self->{left_rear_wheel}->drive(@_),
                         $self->{right_rear_wheel}->drive(@_),  );
        }

        sub brake {
                my $self = shift;
                return ( $self->{left_front_wheel}->brake(@_),
                         $self->{left_rear_wheel}->brake(@_),
                         $self->{right_front_wheel}->brake(@_),
                         $self->{right_rear_wheel}->brake(@_),  );
        }


C<AUTOLOAD> methods can help in this regard, but usually at the cost of
readability and maintainability:

        sub AUTOLOAD {
                my $self = shift;
                $AUTOLOAD =~ s/.*:://;
                my @results;
                return map { $self->{$_}->$AUTOLOAD(@_) },
                        grep { $self->{$_}->can($AUTOLOAD) },
                         keys %$self;
        }

Often, the simple auto-delegation mechanism shown above cannot
be used at all, and the various cases must be hand-coded into the C<AUTOLOAD>
or into separate named methods (as shown earlier).

For example, an electric car might also have a flywheel and an MP3 player:

        sub new {
                bless { left_front_wheel  => Wheel->new('steer', 'brake'),
                        left_rear_wheel   => Wheel->new('drive', 'brake'),
                        right_front_wheel => Wheel->new('steer', 'brake'),
                        right_rear_wheel  => Wheel->new('drive', 'brake'),
                        flywheel          => Flywheel->new(),
                        mp3               => MP3::Player->new(),
                      }, $_[0];
        }

The Flywheel class would probably have its own C<brake> method (to
harvest motive energy from the flywheel) and MP3::Player might have its
own C<drive> method (to switch between storage devices). 

An C<AUTOLOAD> redispatch such as that shown above would then fail very
badly. Whilst it would prove merely annoying to have one's music skip
tracks (C<$self-E<gt>{mp3}-E<gt>drive(+10)>) every time one accelerated
(C<$self-E<gt>{right_rear_wheel}-E<gt>drive(+10)>), it might be disastrous to
attempt to suck energy out of the flywheel
(C<$self-E<gt>{flywheel}-E<gt>brake()>) whilst the brakes are trying to feed it
back in (C<$self-E<gt>{right_rear_wheel}-E<gt>brake()>).

Class-action lawyers I<love> this kind of programming.


=head1 DESCRIPTION

The Class::Delegation module simplifies the creation of 
delegation-based class hierarchies, allowing
a method to be redispatched:

=over 4

=item *

to a single nominated attribute,

=item *

to a collection of nominated attributes in parallel, or

=item *

to any attribute that can handle the message.

=item *

the object itself

=back

These three delegation mechanisms can be specified for:

=over 4

=item *

a single method

=item *

a set of nominated methods collectively

=item * 

any as-yet-undelegated methods

=item *

all methods, delegated or not.

=back

=head2 The syntax and semantics of delegation

To cause a hash-based class to delegate method invocations to its
attributes, the Class::Delegation module is imported into the class, and
passed a list of method/handler mappings that specify the delegation
required. Each mapping consists of between one and three key/value
pairs. For example:

        package Car;
        
        use Class::Delegation
                send => 'steer',
                  to => ["left_front_wheel", "right_front_wheel"],
                
                send => 'drive',
                  to => ["right_rear_wheel", "left_rear_wheel"],
		  as => ["rotate_clockwise", "rotate_anticlockwise"]
                  
                send => 'power',
                  to => 'flywheel',
                  as => 'brake',
                
                send => 'brake',
                  to => qr/.*_wheel$/,
                  
                send => qr/^MP_(.+)/,
                  to => 'mp3',
                  as => sub { $1 },
                  
                send => -OTHER,
                  to => 'mp3',
                  
                send => 'debug',
                  to => -ALL,
                  as => 'dump',
                  
                send => -ALL,
                  to => 'logger',
                ;

=head2 Specifying methods to be delegated

The names of methods to be redispatched can be
specified using the C<'send'> key. They may be specified as single strings, arrays of strings, regular
expressions, subroutines, or as one of the two special names: C<-ALL> and C<-OTHER>.
A single string specifies a single method to be delegated in some way.
The other alternatives specify sets of methods
that are to share the associated delegation semantics. That set
of methods may be specified:

=over 4

=item * 

explicitly, by an array (the set consists of those method calls whose names 
appear in the array),

=item *

implicitly, by a regex (the set consists of those method calls whose names match the pattern),

=item *

procedurally, by a subroutine (the set consists of any method calls for which the subroutine
returns a true value, when passed the method invocant, the method name, and the
arguments with which the method was invoked),

=item *

generically, by C<-ALL> (the set consists of every method call -- excluding calls
to C<DESTROY> --  that is not handled by an
explicit method of the class),

=item *

exclusively, by C<-OTHER> (the set consists of every method call -- excluding calls
to C<DESTROY> -- that is not successfully
delegated by any earlier mapping in the C<use Class::Delegation> list).

=back

The exclusion of calls to C<DESTROY> in the last two cases ensures that automatically
invoked destructor calls are not erroneously delegated. C<DESTROY> calls I<can> be
delegated through any of the other specification mechanisms.

=head2 Specifying attributes to be delegated to

The actual delegation behaviour is determined by the attributes to which these
methods are to be delegated. This information can be specified via the C<'to'>
key, using a string, an array, a regex, a subroutine, or the special flag
C<-ALL>. Normally the delegated method that is invoked on the specified attribute (or attributes)
has the same name as the original call, and is invoked in the same calling
context (void, scalar, or list).

If the attribute is specified via a single string, that string is taken
as the name of the attribute to which the associated method (or methods)
should be delegated. For 
example, to delegate invocations of C<$self-E<gt>power(...)> to
C<$self-E<gt>{flywheel}-E<gt>power(...)>:

        use Class::Delegation
            send => 'power',
              to => 'flywheel';

If the attribute is specified via a single string that starts with C<"->...">
then that string is taken as specifying the name of a I<method> of the
current object. That method is called and is expected to return an 
object. The original method that was being delegated is then delegated to that
object. For example, to delegate invocations of C<$self-E<gt>power(...)> to
C<$self-E<gt>flywheel()-E<gt>power(...)>:

        use Class::Delegation
            send => 'power',
              to => '->flywheel';

Since this syntax is a little obscure (and not a little ugly),
the same effect can also be obtained like so:

        use Class::Delegation
            send => 'power',
              to => -SELF->flywheel;


An array reference can be used in the attribute position to specify the
a list of attributes, I<all of which> are delegated to -- in sequence
they appear in the list. Note that each element of the array is
processed recursively, so it may contain any of the other attribute
specifiers described in this section (or, indeed, a nested array of
attribute specifiers)

For example, to distribute invocations of C<$self-E<gt>drive(...)> to both
C<$self-E<gt>{left_rear_wheel}-E<gt>drive(...)> and
 C<$self-E<gt>{right_rear_wheel}-E<gt>drive(...)>:

        use Class::Delegation
            send => 'drive',
              to => ["left_rear_wheel", "right_rear_wheel"];

Note that using an array to specify parallel delegation has an effect on the return
value of the original method. In a scalar context, the original call returns a reference to
an array containing the (scalar context) return values of each of the calls. In
a list context, the original call returns a list of array references
containing references to the individual (list context) return lists of the calls. So, for example, if a
class's C<cost> method were delegated like so:

        use Class::Delegation
                send => 'cost',
                  to => ['supplier', 'manufacturer', 'distributor'];

then the total cost could be calculated like this:

        use List::Util 'sum';
        $total = sum @{$obj->cost()};

Specifying the attribute as a regular expression causes the associated
method to be delegated to any attribute whose name matches the pattern.
Attributes are tested for such a match -- and delegated to -- in the
internal order of their hash (i.e. in the sequence returned by C<keys>).  For 
example, to redispatch C<brake> calls to every attribute whose name ends in C<"_wheel">:

        send => 'brake',
          to => qr/.*_wheel$/,

If a subroutine reference is used as the C<'to'> attribute specifier, it is passed the
invocant, the name of the method, and the argument list. It is expected to
return either a value specifying the correct attribute name (or names). As with an
array, the value returned may be any valid attribute specifier (including
another subroutine reference) and is iteratively processed to determine the
correct target(s) for delegation.

A subroutine may also return a reference to an object, in which case the
subroutine is delegated to that object (rather than to an attribute of
the current object). This can be useful when the actual delegation target
is more complex than just a direct attribute. For example:

	send => 'start',
	  to => sub { $_[0]{ignition}{security}[$_[0]->next_key] },


If the C<-ALL> flag is used as the name of the attribute, the method
is delegated to all attributes of the object (in their C<keys> order). For 
example, to forward debugging requests to every attribute in turn:

        send => 'debug',
          to => -ALL,
                  

=head2 Specifying the name of a delegated method

Sometimes it is necessary to invoke an attribute's method through a
different name than that of the original delegated method. The C<'as'>
key facilitates this type of method name translation in any delegation.
The value associated with an C<'as'> key specifies the name of the
method to be invoked, and may be a string, an array, or a subroutine.

If a string is provided, it is used as the new name of the delegated method.
For example, to cause calls to C<$self-E<gt>power(...)>
to be delegated to C<$self-E<gt>{flywheel}-E<gt>brake(...)>:

        send => 'power',
          to => 'flywheel',
          as => 'brake',

If an array is given, it specifies a list of delegated method names.
If the C<'to'> key specifies a single attribute, each method in the list is
invoked on that one attribute. For example:

        send => 'boost',
          to => 'flywheel',
          as => ['override', 'engage', 'discharge'],

would sequentially call:

        $self->{flywheel}->override(...);
        $self->{flywheel}->engage(...);
        $self->{flywheel}->discharge(...);

If both the C<'to'> key and the C<'as'> key specify multiple values, then
each attribute and method name form a pair, which is invoked. For example:

        send => 'escape',
          to => ['flywheel', 'smokescreen'],
          as => ['engage',   'release'],

would sequentially call:

        $self->{flywheel}->engage(...);
        $self->{smokescreen}->release(...);

If a subroutine reference is used as the C<'as'> specifier, it is passed the
invocant, the name of the method, and the argument list, and is expected to
return a string that will be used as the method name. For example, to 
strip method calls of a C<"driver_..."> prefix and delegate them to the 
C<'driver'> attribute:

        send => sub { substr($_[1],0,7) eq "driver_" },
          to => 'driver', 
          as => sub { substr($_[1],7) }
          
or:

        send => qr/driver_(.*)/,
          to => 'driver', 
          as => sub { $1 }


=head2 Delegation to self

Class::Delegation can also be used to delegate methods back to the original
object, using the C<-SELF> option with the C<'to'> key. For example, to
redirect any call to C<overdrive> so to invoke the C<boost> method instead:

       send => 'overdrive',
         to => -SELF,
         as => 'boost',

Note that this only works if the object I<does not> already have an
C<overdrive> method.

As with other delegations, a single call can be redelegated-to-self as
multiple calls.  For example:

       send => 'emergency',
         to => -SELF,
         as => ['overdrive', 'launch_rockets'],


=head2 Handling failure to delegate

If a method cannot be successfully delegated through any of its mappings,
Class::Delegation will ignore the call and the built-in 
C<AUTOLOAD> mechanism will attempt to handle it instead. 


=head1 EXAMPLES

Delegation is a useful replacement for inheritance in a number of contexts.
This section outlines five of the most common uses.

=head2 Simulating single inheritance

Unlike most other OO languages, inheritance in Perl only works well when
the base class has been I<designed> to be inherited from. If the attributes
of a prospective base class are inaccessible, or the implementation is
not extensible (e.g. a blessed scalar or regular expression), or the
base class's constructor does not use the two-argument form C<bless>, it
will probably be impractical to inherit from the class.

Moreover, in many cases, it is not possible to tell -- without a detailed
inspection of a base class's implementation -- whether such a class can easily be
inherited. This inability to reliably treat classes as encapsulated and
implementation-independent components seriously undermines the usability
of object-oriented Perl.

But since inheritance in Perl merely specifies where a class is to look next
if a suitable method is not found in its own package [3], it is often possible
to replace derivation with aggregation and use a delegated attribute instead.

For example, it is possible to simulate the inheritance of the class Base
via a delegated attribute:

        package Derived;
        use Class::Delegation send => -ALL, to => 'base';
        
        sub new {
                my ($class, $new_attr1, $new_attr2, @base_args) = @_;
                bless { attr1 => $new_attr1,
                        attr2 => $new_attr2,
                        base  => Base->new(@base_args),
                      }, $class;
        }

Now any method that is not present in Derived is delegated to the Base object
referred to by the C<base> attribute, just as it would have been if 
Derived actually inherited from Base.

This technique works in situations where the functionality of the Base methods
is non-polymorphic with respect to their invocant. That is, if an inherited
method in class Base were to interrogate the class of the object on which it was called, 
it would find a Derived object. But a delegated method in class Base will find a Base object.
This is not the usual behaviour in OO Perl, but is correct and appropriate under the earlier 
assumption that Base has not been designed to be inherited from -- and must therefore
always expect a Base class object as its invocant.


=head2 Replacing method dispatch semantics

Another situation in which delegation is preferable to inheritance is
where inheritance I<is> feasible, but Perl's standard dispatch semantics
-- left-most, depth-first priority of method dispatch -- are
inappropriate.

For example, if various base classes in a class hierarchy provide a C<dump_info> method
for debugging purposes, then a derived class than multiply inherits from two or more
of those classes will only dispatch calls to C<dump_info> to the left-most ancestor's
method. This is unlikely to be the desired behaviour.

Using delegation it is possible to cause calls to C<dump_info> to invoke the corresponding
methods of I<all> the base classes, whilst all other method calls are dispatched left-most and
depth-first, as normal:

        package Derived;
        use Class::Delegation
                send => 'dump_info',
                  to => -ALL,
                  
                send => -OTHER,
                  to => 'base1',
        
                send => -OTHER,
                  to => 'base2',
                ;
        
        sub new {
                my ($class, %named_args) = @_;
                bless { base1 => Base1->new(%named_args),
                        base2 => Base2->new(%named_args),
                      }, $class;
        }

Note that the semantics of C<send =E<gt> -OTHER> ensure that only one of the
two base classes is delegated a method. If C<base1> is able to handle
a particular method delegation, then it will have been dispatched when
the C<-OTHER> governing C<base2> is reached, so the second C<-OTHER> will
ignore it.
        

=head2 Simulating multiple inheritance of pseudohashs

Another situation in which multiple inheritance can cause trouble is
where a class needs to inherit from two base classes that are both
implemented via pseudohashes. Because each pseudohash base class will
assume that I<its> attributes start from index C<1> of the pseudohash
array, the methods of the two classes would contend for the same
attribute slots in the derived class. Hence the C<use base> pragma
detects cases where two ancestral classes are pseudohash-based and
rejects them (terminally).

Delegation provides a convenient way to provide the effects of 
pseudohash multiple inheritance, without the attendant problems. For example:

        package Derived;
        use Class::Delegation
                send => -ALL,
                  to => 'pseudobase1',
        
                send => -OTHER,
                  to => 'pseudobase2',
                ;
        
        sub new {
                my ($class, %named_args) = @_;
                bless { pseudobase1 => Pseudo::Base1->new(%named_args),
                        pseudobase2 => Pseudo::Base2->new(%named_args),
                      }, $class;
        }

As in the previous example, only one of the two base classes
is delegated a method. The C<-ALL> associated with C<pseudobase1>
attempts to delegate every method to that attribute, then the C<-OTHER>
associated with C<pseudobase2> catches any methods that cannot be
handled by C<pseudobase1>.



=head2 Adapting legacy code

Because the C<'as'> key can take a subroutine, it is also possible to
use a delegating class to adapt the interface of an existing class. For example,
a class with separate "get" and "set" accessors:

        class DogTag;
        
        sub get_name   { return $_[0]->{name} }
        sub set_name   { $_[0]->{name} = $_[1] }

        sub get_rank   { return $_[0]->{rank} }
        sub set_rank   { $_[0]->{rank} = $_[1] }

        sub get_serial { return $_[0]->{serial} }
        sub set_serial { $_[0]->{serial} = $_[1] }
        
        # etc.
        
could be trivially adapted to provide combined get/set accessors like so:

        class DogTag::SingleAccess;
        
        use Class::Delegation
                send => -ALL
                  to => 'dogtag',
                  as => sub {
                             my ($invocant, $method, @args) = @_;
                             return @args ? "set_$method" : "get_$method"
                         },
                ;
                
        sub new { bless { dogtag => DogTag->new(@_[1..$#_) }, $_[0] }

Here, the C<'as'> subroutine determines whether an "new value" argument
was passed to the original method, delegating to the C<set_...> method if so,
and to the C<get_...> method otherwise.


=head2 Multiplexing a facade

The ability to use regular expressions to specify method names, and
subroutines to indicate the attributes and attribute methods to which
they are delegated, opens the possibility of creating a class that
acts as a collective front-end for several others. For example:

        package Bilateral;
        
        %Bilateral = ( left  => 'Levorotatory',
                       right => 'Dextrorotatory',
                     );
                     
        use Class::Delegation
                send => qr/(left|right)_(.*)/,
                  to => sub { $1 },
                  as => sub { $2 },
                ;
        
        sub AUTOLOAD  { 
                carp "$AUTOLOAD does not begin with 'left_...' or 'right_...'"
        },
                  

The Bilateral class now forwards all I<class> method calls that are prefixed
with C<"left_..."> to the Laevorotatory class, and all those prefixed with
C<"right_..."> to the Dextrorotatory class. Any calls that cannot be dispatched
are caught and ignored (with a warning) by the C<AUTOLOAD>.

The mechanism by which the class method dispatch is achieved is perhaps a little obscure.
Consider the invocation of a class method:

        Bilateral->left_rotate(45);
        
Here, the invocant is the string C<"Bilateral">, rather than a blessed object. Thus,
when Class::Delegation forwards the call to:

        $self->{$1}->$2(45);
        
the effect is the same as calling:

        "Bilateral"->{left}->rotate(45);
        
This invokes a little-known feature of the C<-E<gt>> operator [4]. If a hash access is
performed on a string, that string is taken as a symbolic
reference to a package hash variable in the current package. Thus the above call is internally translated to:

        ${"Bilateral"}{left}->rotate(45);
        
which is equivalent to the class method call:

        Levorotatory->rotate(45);

=head1 AUTHOR

Damian Conway (damian@conway.org)

=head1 BUGS

There are undoubtedly serious bugs lurking somewhere in this code.
Bug reports and other feedback are most welcome.

=head1 COPYRIGHT

       Copyright (c) 2001, Damian Conway. All Rights Reserved.
    This module is free software. It may be used, redistributed
        and/or modified under the same terms as Perl itself.
