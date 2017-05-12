package Class::Agreement;

use warnings;
use strict;

our $VERSION = '0.02';

use Carp;
use Class::Inspector;
use Scalar::Util qw(blessed);

=head1 NAME

Class::Agreement - add contracts to your Perl classes easily

=head1 SYNOPSIS

    package SomeClass;
    
    use Class::Agreement;
    
    # use base 'Class::Accessor' or 'Class::MethodMaker',
    # or roll your own:
    sub new { ... }

    invariant {
        my ($self) = @_;
        $self->count > 0;
    };
    
    precondition add_a_positive => sub {
        my ( $self, $value ) = @_;
        return ( $value >= 0 );
    };
    sub add_a_positive {
        my ( $self, $value ) = @_;
        ...
    }
    
    sub choose_word {
        my ( $self, $value ) = @_;
        ...
    }
    postcondition choose_word => sub {
        return ( result >= 0 );
    };
    
    dependent increase_foo => sub {
        my ( $self, $amount ) = @_;
        my $old_foo = $self->foo;
        return sub {
          my ( $self, $amount ) = @_;
          return ( $old_foo < $self->get_foo );
        }
    };
    sub increase_foo {
        my ( $self, $amount ) = @_;
        $self->set_foo( $self->get_foo + $amount );
    }

=head1 DESCRIPTION

Class::Agreement is an implementation of behavioral contracts for Perl5. This
module allows you to easily add pre- and postconditions to new or existing Perl
classes.

This module provides contracts such as dependent contracts, contracts for
higher-order functions, and informative messages when things fail. At the time
of this writing, Class::Agreement is one of only two contract implementations
that blames contract-breaking components correctly.  (See: "Object-oriented
Programming Languages Need Well-founded Contracts" at
L<http://citeseer.ist.psu.edu/findler01objectoriented.html>.)

Using Class::Agreement lets you specify proper input and output of your
functions or methods, thus strengthening your code and allowing you to spot
bugs earlier.

=head2 Comparison with Class::Contract

L<Class::Contract> requires you to use its own object and accessor system, which
makes the addition of contracts to existing code difficult. In contrast, it
should be easy to implement contracts with L<Class::Agreement> no matter what
object system (C<Class::Accessor>, L<Class::MethodMaker>, L<Spiffy>, etc.) you
use.

L<Class::Contract> also clones objects every time you add a postcondition, which
can get pretty expensive. L<Class::Agreement> doesn't clone -- alternatively, it
provides you with dependent contracts so that you can use closure to keep track
of only the values you care about. (See L</"Testing old values">.)

=head2 Comparison with Eiffel

You could say that L<Class::Agreement> gives you Perl equivalents of Eiffel's
C<require>, C<ensures>, C<invariant> and (indirectly) C<old> keywords. For
example, the following Eiffel method:

    decrement is
        require
            item > 0
        do
            item := item - 1
        ensure
            item = old item - 1
        end 

...could be written in Perl as:

    use Class::Contract;
    ...
    
    precondition decrement => sub { shift()->item > 0 }

    sub decrement {
        my ( $self ) = @_;
        $self->item( $self->item - 1 );
    }

    dependent decrement => sub {
        my ( $self ) = @_;
        my $old_item = $self->item;
        return sub { $self->item == $old_item - 1 };
    };

=head1 EXPORT

The following functions are exported by default:

=over 4

=item * C<precondition>, C<postcondition>, and C<dependent>, each of which have two distinct calling syntaxes: one for functional programming and one for object-oriented.

=item * C<result>, which should only be used within postconditions or functions returned by dependent contracts.

=item * C<invariant> and C<specify_constructors>, both of which are used only in object-oriented programming.

=back

All exported functions are described in the following section, L</"FUNCTIONS">.

=cut

use base 'Exporter';

our @EXPORT = qw(
    result
    precondition postcondition dependent invariant
    specify_constructors
);

my $contracts = {};

my $constructors = {};

#
# a separate subroutine is necessary to keep the exported function prototype
#
sub _real_result {
    croak "function Class::Agreement::result() used outside of postcondition";
}

sub result () {
    goto &_real_result;
}

sub _parent_class_of_method {

    # based off find_parent from SUPER.pm by Simon Cozens/chromatic
    my ( $class, $method, $prune ) = @_;
    $prune ||= '';
    {
        no strict 'refs';
        for my $parent ( @{ $class . '::ISA' }, 'UNIVERSAL' ) {
            return _parent_class_of_method( $parent, $method )
                if $parent eq $prune;
            return $parent if $parent->can($method);
        }
    }
}

sub _subroutine_exists {
    my ($symbol) = @_;
    no strict 'refs';
    *{$symbol}{CODE};
}

sub _check_arguments {
    my ( $glob, $block ) = @_;
    my $caller_name = [ caller(1) ]->[3];
    croak "first argument to $caller_name() was undefined"
        unless defined $glob;
    croak "second argument to $caller_name() was not a subroutine reference"
        unless ref $block eq 'CODE';
}

sub _add_contract_for_hierarchy {
    my ( $package, $glob, $type, $inforef ) = @_;

    # if they're trying to add a contract to a method that isn't overridden,
    # create a stub to attach the contract to
    my $this_symbol = _package_and_method_to_symbol( $package, $glob );
    if ( not _subroutine_exists($this_symbol) ) {
        no strict 'refs';
        if ( my $parent = _parent_class_of_method( $package, $glob ) ) {
            *{$this_symbol} = $parent->can($glob);
        }
        else {
            croak
                "can't add $type contract to undefined subroutine $this_symbol";
        }
    }

    my @classes
        = ( $package, @{ Class::Inspector->subclasses($package) || [] } );
    foreach my $source_class (@classes) {
        my $symbol = _package_and_method_to_symbol( $source_class, $glob );
        _add_contract( $symbol, $type, $inforef, $package )
            if _subroutine_exists($symbol);
    }
}

sub _add_contract {
    my ( $symbol, $type, $inforef, $source_class ) = @_;

    # if we already have a contract of this type...
    if ( my @contracts = _get_contracts( $symbol, $type ) ) {

        # if this contract wasn't defined by our source class..
        if ( $contracts[0]->[3] ne $source_class ) {

            # erase any existing contracts
            _erase_contracts( $symbol, $type );
        }
    }

    # add our new contract
    push @{ $contracts->{$symbol}{$type} }, [ @$inforef, $source_class ];

    # if the symbol doesn't have a wrapper, add one
    if ( not _has_a_contract($symbol) ) {
        _set_implementation( $symbol, \&$symbol );
        no strict 'refs';
        no warnings 'redefine';
        *{$symbol} = _make_method_wrapper($symbol);
    }
}

sub _set_implementation {
    my ( $symbol, $block ) = @_;
    $contracts->{$symbol}{impl} = $block;
}

sub _get_implementation {
    my ($symbol) = @_;
    return $contracts->{$symbol}{impl};
}

sub _has_a_contract {
    my ($symbol) = @_;
    return exists $contracts->{$symbol}{impl};
}

sub _get_contracts {
    my ( $symbol, $type ) = @_;
    @{ $contracts->{$symbol}{$type} || [] };
}

sub _erase_contracts {
    my ( $symbol, $type ) = @_;
    delete $contracts->{$symbol}{$type};
}

sub _copy_of {
    return @{ \@_ };
}

sub _symbol_to_package_and_method {
    shift =~ /^(.+)::(.+)$/;
}

sub _package_and_method_to_symbol {
    ( $_[1] =~ /::/ ) ? $_[1] : "$_[0]\::$_[1]";
}

sub _is_constructor {
    my ( $package, $name ) = @_;
    return
        exists $constructors->{$package}
        ? exists $constructors->{$package}{$name}
        : $name eq 'new';
}

sub _set_constructors {
    my ( $package, @constructors ) = @_;
    my %lookup = ( map { ; $_ => 1 } @constructors );
    $constructors->{$_} = \%lookup
        for $package, Class::Inspector->subclasses($package);
}

sub _get_constructors {
    my ($package) = @_;
    return $constructors->{$package} || [];
}

sub _make_method_wrapper {
    my ($symbol) = @_;
    my ( $package, $method ) = _symbol_to_package_and_method($symbol);
    my $parent = _parent_class_of_method( $package, $method );
    my $parent_symbol =
        defined $parent
        ? _package_and_method_to_symbol( $parent, $method )
        : undef;

    return sub {
        my @arguments = @_;

        #
        # do invariants, blame outside sources
        #
        if ( blessed( $_[0] ) ) {
            foreach ( _get_contracts( $symbol, 'invar' ) ) {
                my ( $block, $file, $line ) = @$_;
                my $success = eval { $block->( _copy_of( $arguments[0] ) ) };
                if ($@) {
                    croak "invariant for $symbol died: $@ "
                        . "from $file line $line";
                }
                elsif ( not $success ) {
                    croak "invariant for $symbol failed due to "
                        . "an outside source tampering with the object "
                        . "from $file line $line";
                }
            }
        }

        #
        # do dependent contracts
        #
        _erase_contracts( $symbol, 'temp-post' );
        foreach ( _get_contracts( $symbol, 'dep' ) ) {
            my ( $block, $file, $line ) = @$_;
            my $postcondition = eval { $block->( _copy_of(@arguments) ) };
            if ($@) {
                croak "dependent contract for $symbol died: $@ "
                    . "from $file line $line";
            }
            elsif ( not defined $postcondition ) {
                return;
            }
            elsif ( ref $postcondition ne 'CODE' ) {
                croak
                    "dependent contract for $symbol did not return either a "
                    . "subroutine reference or undefine at $file line $line";
            }
            else {
                _add_contract( $symbol, 'temp-post',
                    [ $postcondition, $file, $line ], $package );
            }
        }

        #
        # do preconditions
        #
        foreach ( _get_contracts( $symbol, 'pre' ) ) {
            my ( $block, $file, $line ) = @$_;
            my $success = eval { $block->( _copy_of(@arguments) ) };
            if ($@) {
                croak "precondition for $symbol died: $@ "
                    . "from $file line $line";
            }
            elsif ( not $success ) {
                if (defined $parent
                    and my @parent_contracts = _get_contracts(
                        _package_and_method_to_symbol( $parent, $method ),
                        'pre'
                    )
                    )
                {
                    foreach (@parent_contracts) {
                        my ( $parent_block, $parent_file, $parent_line )
                            = @$_;
                        if ( eval { $parent_block->( _copy_of(@arguments) ) }
                            )
                        {
                            croak "precondition for $symbol failed "
                                . "from $parent_file line $parent_line (the parent) "
                                . "and file $file line $line (the child) -- "
                                . "check hierarchy between $parent and $package";
                        }
                        else {
                            croak "precondition for $symbol failed "
                                . "due to client input "
                                . "from file $file line $line";
                        }
                    }
                }
                else {
                    croak "precondition for $symbol failed "
                        . "from $file line $line";
                }
            }
        }

        #
        # we need to call the method/function in the same context in which the
        # contract was called
        #
        my $implementation = _get_implementation($symbol);
        my @result         = ( not defined wantarray )
            ? do { $implementation->( _copy_of(@arguments) ) }
            : wantarray ? ( $implementation->( _copy_of(@arguments) ) )
            : ( scalar $implementation->( _copy_of(@arguments) ) );

        #
        # do postconditions
        #
        {
            no strict 'refs';
            no warnings 'redefine';
            local *_real_result = sub { wantarray ? @result : $result[0] };

            foreach (
                _get_contracts( $symbol, 'post' ),
                _get_contracts( $symbol, 'temp-post' )
                )
            {
                my ( $child_block, $child_file, $child_line ) = @$_;

                my $child_success
                    = eval { $child_block->( _copy_of(@arguments) ) };
                if ($@) {
                    croak "postcondition for $symbol died: $@ "
                        . "from $child_file line $child_line";
                }
                elsif (
                    defined $parent
                    and my @parent_contracts = (
                        _get_contracts( $parent_symbol, 'post' ),
                        _get_contracts( $parent_symbol, 'temp-post' )
                    )
                    )
                {
                    foreach (@parent_contracts) {
                        my ( $parent_block, $parent_file, $parent_line )
                            = @$_;
                        my $parent_success
                            = eval { $parent_block->( _copy_of(@arguments) ) };
                        if ($@) {
                            croak "postcondition for $symbol died: $@ "
                                . "from $child_file line $child_line";
                        }
                        elsif ( $child_success and not $parent_success ) {
                            croak "postcondition for $symbol failed "
                                . "at $parent_file line $parent_line (the parent) "
                                . "and file $child_file line $child_line (the child) -- "
                                . "check hierarchy between $parent and $package";
                        }
                        elsif ( not $child_success ) {
                            croak
                                "postcondition for $symbol failed since its "
                                . "implementation didn't adhere to the contract "
                                . "from file $child_file line $child_line";
                        }
                    }
                }
                elsif ( not $child_success ) {
                    croak "postcondition for $symbol failed "
                        . "from $child_file line $child_line";
                }
            }
        }

        #
        # do invariants, blame method
        #
        my $is_constructor = _is_constructor( $package, $method );
        if ( blessed( $_[0] ) or $is_constructor ) {
            foreach ( _get_contracts( $symbol, 'invar' ) ) {
                my ( $block, $file, $line ) = @$_;
                my $success = eval {
                    $block->(
                        _copy_of(
                            $is_constructor ? $result[0] : $arguments[0]
                        )
                    );
                };
                if ($@) {
                    croak "invariant for $symbol died: $@ "
                        . "from $file line $line";
                }
                elsif ( not $success ) {
                    croak "invariant for $symbol failed due to "
                        . "the method's implementation being broken "
                        . "from $file line $line";
                }
            }
        }

        wantarray ? @result : $result[0];
    };
}

=head1 FUNCTIONS

=head2 precondition NAME, BLOCK

Specify that the method NAME must meet the precondition as specified in BLOCK.

In BLOCK, the variable C<@_> will be the argument list of the method.  (The
first item of C<@_> will be the class name or object, as usual.)

For example, to specify a precondition on a method to ensure that the first
argument given is greater than zero:

    precondition foo => sub {
        my ( $self, $value ) = @_;
        return ( $value >= 0 );
    };
    sub foo {
        my ( $self, $value ) = @_;
        ...
    }

With methods, if the precondition fails (returns false), preconditions for the
parent class will be checked. If the preconditions for both the child's method
and the parent's method fail, the input to the method must have been invalid. If
the precondition for the parent passes, the hierarchy between the class and the
parent class is incorrect because, to fulfill the Liskov-Wing principal of
substitutability, the subclass' method should accept that the superclass' does,
and optionally more. Note that only the relationships between child and parent
classes are checked -- this module won't traverse the complete ancestry of
a class.

You can use this keyword multiple times to declare multiple preconditions on
the given method.

=cut

=head2 precondition VARIABLE, BLOCK

Specify that, when called, the subroutine reference pointed to by the lvalue
VARIABLE must meet the precondition as specified in BLOCK.

In BLOCK, the variable C<@_> will be the argument list of the subroutine.

There are times when you will have a function or method that accepts another
function as an argument. Say that you have a function C<g()> that accepts
another function, C<f()>, as its argument. However, the argument given to C<f()>
must be greater than zero: 

    sub g {
        my ($f) = @_;
        precondition $f => sub { 
            my ($value) = @_;
            return ( $value >= 0 );
        };
        $f->(15); # will pass
        $f->(-3); # will fail
    }

If called in void context this function will modify VARIABLE to point to a new
subroutine reference with the precondition. If called in scalar 
context, this function will return a new function with the attached
precondition. 

You can use this keyword multiple times to declare multiple preconditions on
the given function.

=cut

sub precondition {
    my ( $glob, $block ) = @_;
    my ( $package, $file, $line ) = caller();
    _check_arguments(@_);

    if ( not ref $glob ) {
        _add_contract_for_hierarchy( $package, $glob,
            pre => [ $block, $file, $line ] );
    }

    elsif ( defined ref $glob and ref $glob eq 'CODE' ) {
        my $original = $glob;
        my $wrapped = sub {
            my @arguments = @_;
            my $success = eval { $block->( _copy_of(@arguments) ) };
            if ($@) {
                croak "precondition for function died: $@";
            }
            elsif ( not $success ) {
                croak
                    "precondition for function failed at $file line $line\n";
            }
            $original->( &_copy_of(@arguments) );
        };
        if ( defined wantarray ) {
            return $wrapped;
        }
        else {
            $_[0] = $wrapped;
        }
    }
    else {
        croak "first argument to precondition() "
            . "was not a method name or code reference";
    }
}

=head2 postcondition NAME, BLOCK

Specify that the method NAME must meet the postcondition as specified in BLOCK.

In BLOCK, the variable C<@_> will be the argument list of the method.  The
function C<result> may be used to retrieve the return values of the method. If
the method returns a list, calling C<result> in array context will return all
of return values, and calling C<result> in scalar context will return only the
first item of that list. If the method returns a scalar, C<result> called in
scalar context will be that scalar, and C<result> in array context will return
a list with one element. 

For example, to specify a postcondition on a method to ensure that the method
returns a number less than zero, BLOCK would check the 

    sub foo {
        my ( $self, $value ) = @_;
        ...
    }
    postcondition foo => sub {
        return ( result >= 0 );
    };

With methods, postconditions for the parent class will be checked if they
exist. If the postcondition for the child's method fails, the blame lies with
the child method's implementation since it is not adhering to its contract. If
the postcondition for the child method passes, but the postcondition for the
parent's fails, the problem lies with the hierarchy betweeen the classes. Note
again that only the relationships between child and parent classes are checked
-- this module won't traverse the complete ancestry of a class. 

You can use this keyword multiple times to declare multiple postconditions on
the given method.

=head2 postcondition VARIABLE, BLOCK

Specify that, when called, the subroutine reference pointed to by the lvalue
VARIABLE must meet the postcondition as specified in BLOCK.

In BLOCK, the varable C<@_> and function C<result> are available and may be
used in the same ways as described in the previous usage of C<postcondition>.

Say that you have a function C<g()> that accepts another function, C<f()> as its
argument. C<f()>, however, must return a number that is divisible by two. This
can be expressed as:

    sub g {
        my ($f) = @_;
        postcondition $f => sub {
            return ! ( result % 2 );
        };
        ...
    }

If called in void context this function will modify VARIABLE to point to a new
subroutine reference with the postcondition. If called in scalar 
context, this function will return a new function with the attached
postcondition. 

You can use this keyword multiple times to declare multiple postconditions on
the given function.

=cut

sub postcondition {
    my ( $glob, $block ) = @_;
    my ( $package, $file, $line ) = caller();
    _check_arguments(@_);

    if ( not ref $glob ) {
        _add_contract_for_hierarchy( $package, $glob,
            post => [ $block, $file, $line ] );
    }

    elsif ( defined ref $glob and ref $glob eq 'CODE' ) {
        my $implementation = $glob;
        my $wrapped = sub {
            my @arguments = @_;

            my @result = ( not defined wantarray )
                ? do { $implementation->( _copy_of(@arguments) ) }
                : wantarray ? ( $implementation->( _copy_of(@arguments) ) )
                : ( scalar $implementation->( _copy_of(@arguments) ) );

            my $success;
            {
                no strict 'refs';
                no warnings 'redefine';
                local *_real_result
                    = sub { wantarray ? @result : $result[0] };

                $success = eval { $block->( _copy_of(@arguments) ) };

                if ($@) {
                    croak "postcondition for function died: $@";
                }
                elsif ( not $success ) {
                    croak
                        "postcondition for function failed at $file line $line";
                }
                else {
                    goto &_real_result;
                }
            }
        };
        if ( defined wantarray ) {
            return $wrapped;
        }
        else {
            $_[0] = $wrapped;
        }
    }
    else {
        croak "first argument to precondition() "
            . "was not a method name or code reference";
    }
}

=head2 dependent NAME, BLOCK

Specify that the method NAME will use the subroutine reference returned by BLOCK
as a postcondition. If BLOCK returns undefined, no postcondition will be added.
In some cases, the postcondition returned will I<depend> on the input provided,
hence these are referred to as I<dependent contracts>. However, since the
arguments to the method are given in the postcondition, dependent contracts will
be used typically to compare old and new values.

BLOCK is run at the same time as preconditions, thus the C<@_> variable works
in the same manner as in preconditions. However, the subroutine reference that
BLOCK returns will be invoked as a postcondition, thus it may the C<result>
function in addition to C<@_>.

You'll probably use these, along with closure, to check the old copies of
values. See the example in L</Testing old values>. 

You can use this keyword multiple times to declare multiple dependent contracts
on the given method.

=head2 dependent VARIABLE, BLOCK

Specify that the subroutine reference pointed to by the lvalue VARIABLE will use
the subroutine reference returned by BLOCK as a postcondition. If BLOCK returns
undefined, no postcondition will be added.

Identical to the previous usage, BLOCK is run at the same time as
preconditions, thus the C<@_> variable works in the same manner as in
preconditions. However, the subroutine reference that BLOCK returns will be
invoked as a postcondition, thus it may the C<result> function in addition to
C<@_>.

Say that you have a function C<g()> that accepts another function, C<f()> as its
argument. You want to make sure that C<f()>, as a side effect, adds to the
global variable C<$count>:

    my $count = 0;
    ...

    sub g {
        my ($f) = @_;
        dependent $f => sub {
            my $old_count = $count;
            return sub { $count > $old_count };
        };
        ...
    }

You can use this keyword multiple times to declare multiple dependent contracts
on the given function.

=cut

sub dependent {
    my ( $glob, $block ) = @_;
    my ( $package, $file, $line ) = caller();
    _check_arguments(@_);

    if ( not ref $glob ) {
        _add_contract_for_hierarchy( $package, $glob,
            dep => [ $block, $file, $line ] );
    }

    elsif ( defined ref $glob and ref $glob eq 'CODE' ) {
        my $implementation = $glob;
        my $wrapped = sub {
            my @arguments = @_;

            my $postcondition = eval { $block->( _copy_of(@arguments) ) };
            if ($@) {
                croak "dependent contract died: $@ " . "at $file line $line";
            }
            elsif ( not defined $postcondition ) {
                return;
            }
            elsif ( ref $postcondition ne 'CODE' ) {
                croak "dependent contract did not return either a "
                    . "subroutine reference or undefine from $file line $line";
            }

            my @result = ( not defined wantarray )
                ? do { $implementation->( _copy_of(@arguments) ) }
                : wantarray ? ( $implementation->( _copy_of(@arguments) ) )
                : ( scalar $implementation->( _copy_of(@arguments) ) );

            my $success;
            {
                no strict 'refs';
                no warnings 'redefine';
                local *_real_result
                    = sub { wantarray ? @result : $result[0] };
                $success = eval { $postcondition->( _copy_of(@arguments) ) };

                if ($@) {
                    croak "postcondition for function died: $@";
                }
                elsif ( not $success ) {
                    croak
                        "postcondition for function failed from $file line $line";
                }
                else {
                    goto &_real_result;
                }
            }
        };
        if ( defined wantarray ) {
            return $wrapped;
        }
        else {
            $_[0] = $wrapped;
        }
    }
    else {
        croak "first argument to precondition() "
            . "was not a method name or code reference";
    }
}

=head2 invariant BLOCK

BLOCK will be evaluated before and after every public method in the current
class. A I<public method> is described as any subroutine in the package whose
name begins with a letter and is not composed entirely of uppercase letters.

Invariants will not be evaluated for class methods. More specifically,
invariants will only be evaluated when the first argument to a subroutine is
a blessed reference. This would mean that invariants would not be checked for
constructors, but C<Class::Agreement> provides another function,
L<"specify_constructors">, which is used for this purpose. (See the following
section for details.)

Invariant BLOCKS are provided with only one argument: the current object. An
exception is if the method is a constructor, the only argument to the BLOCK is
the first return value of the method. (If your constructors return an object as
the first or only return value -- as they normally do -- this means you're
fine.)

Invariants are not checked when destructors are invoked. For an explanation as
to why, see L<"WHITEPAPER">.

You can use this keyword multiple times to declare multiple invariant contracts
for the class.

=head3 Blame

Blaming violators of invariants is easy. If an invariant contract fails
following a method invocation, we assume that the check prior to the
invocation must have succeeded, so the implementation of the method is at
fault. If an invariant fails before the method runs, invariants must have
succeeded after the last method was called, so the object must have been
tampered with by an exogenous source. Eeek!

=head3 Example

For example, say that you have a class for Othello boards, which are typically
8x8 grids. Othello begins with four pieces already placed on the board and ends
when the board is full or there are no remaining moves. Thus, the board must
always have between four and sixty-four pieces, inclusive:

    invariant sub {
        my ( $self ) = @_;
        return ( $self->pieces >= 4 and $self->pieces <= 64 );
    };

If the invariant fails after a method is called, the method's implementation is
at fault. If the invariant fails before the method is run, an outside source has
tampered with the object.

=cut

sub invariant {
    my ($block) = @_;
    my ( $package, $file, $line ) = caller();
    croak "argument to invariant() was not a subroutine reference"
        unless ref $block eq 'CODE';

    my %seen;
    my @classes
        = ( $package, @{ Class::Inspector->subclasses($package) || [] } );
    foreach my $class (@classes) {
        my @methods =

            # ignore subs imported from Class::Agreement
            grep {
            0 + ( __PACKAGE__->can($_) || 0 )
                != 0 + ( $class->can($_) || 0 )
            }

            # skip methods we've already added contracts for
            grep { not $seen{$_}++ }

            # skip internal methods (DESTROY, etc.)
            grep {/[a-z]/}

            # retrieve all non _* methods from $package
            @{ Class::Inspector->methods( $class, 'public' ) || [] };

        foreach my $method (@methods) {
            _add_contract_for_hierarchy( $class, $method,
                invar => [ $block, $file, $line ] );
        }
    }
}

=head2 specify_constructors LIST

As described above, invariants are checked on public methods when the first
argument is an object. Since constructors are typically class methods (if not
also object methods), C<Class::Agreement> needs to know which methods are
constructors so that it can check invariants against the constructors' return
values instead of simply ignoring them.

By default, it is assumed that a method named C<new> is the constructor. You
don't have to bother with this keyword if you don't specify any invariants or if
your only constructor is C<new>.

If your class has more constructors, you should specify all of them (including
C<new>) with C<specify_constructors> so that invariants can be checked properly:

    package Othello::Board;
    use Class::Agreement;

    specify_constructors qw( new new_random );

    invariant sub {
        my ( $self ) = @_;
        return ( $self->pieces >= 4 and $self->pieces <= 64 );
    };

    sub new {
        ...
        return bless [], shift;
    }

    sub new_random {
        ...
        return bless [], shift;
    }

Any subclasses of C<Othello::Board> would also have the invariants of the
methods C<new()> and C<new_random()> checked as constructors. You can override
the specified constructors of any class -- all subclasses will use the settings
specified by their parents.

If, for some reason, your class has no constructors, you can pass
C<specify_constructors> an empty list:

    specify_constructors ();

=cut

sub specify_constructors {
    my (@constructors) = @_;
    my ( $package, $file, $line ) = caller();
    _set_constructors( $package, @constructors );
}

=head1 REAL-LIFE EXAMPLES

=head2 Checking a method's input

Say that you have a board game that uses a graph of tiles. Every turn, players
draw a tile and, if it's placable, plop it into the graph. The method
C<insert_tile()> of the C<Graph> class should take a placable tile as an
argument, which we can express as a contract:

    precondition insert_tile => sub {
        my ( $self, $tile ) = @_;
        return $self->verify_tile_fits( $tile );
    };

    sub insert_tile {
        my ( $self, $tile ) = @_;
        ...
    }

Before the implementation of C<insert_tile> is executed, the precondition
checks to ensure that C<$tile> is placable in the graph as determined by
C<verify_tile_fits()>.

=head2 Checking a method's output

Using the C<Graph> class from the previous example, say we have a method
C<get_neighbors()> which, given an C<x> and C<y>, will return all tiles
surrounding the tile at that position. If the tiles are square, any given tile
shouldn't have more than eight neighbors:

    sub get_neighbors {
        my ( $self, $x, $y ) = @_;
        ...
    }

    postcondition get_neighbors => sub {
        return ( (result) <= 8 );
    };

The postcondition ensures that C<get_neighbors()> returns no more than eight
items.

=head2 Testing old values

Dependent contracts occur when the postcondition I<depends> on the input given
to the method. You can use dependent contracts to save old copies of values
through the use of closure.

Given the C<Graph> class from previous examples, say that the tiles in the
graph are stored in a list. If insert tile has successfully added the tile to
the graph, the number of tiles in the graph should have increased by one. Using
the C<dependent()> function, we return a closure that will check exactly this:

    dependent insert_tile => sub {
        my ( $self, $tile ) = @_;
        my $old_count = $self->num_tiles;
        return sub {
            my ( $self, $tile ) = @_;
            return ( $self->num_tiles > $old_count );
        };
    };

    sub insert_tile {
        my ( $self, $tile ) = @_;
        ...
    }

Before the implementation of C<insert_tile()> is run, the block given to
C<dependent()> is run, which returns a closure. This closure is then run after
C<insert_tile()> as if it were a precondition. (Thus, the closure returned by
the block may make use the C<result> function as well as C<@_>.)

=head2 Contracts on coderefs

This is where contracts get interesting. Say that you have a function C<g()>
that takes a function C<f()> as an argument and returns a number greater than
zero. However, C<f()> has a contract, too: it must take a natural number as the
first argument and must return a single letter of the alphabet. This can be
represented as follows:

    precondition g => sub {
        # first argument of @_ is f()
        precondition $_[0] => sub {
            my ( $val ) = @_;
            return ( $val =~ /^\d+$/ );
        };
        postcondition $_[0] => sub {
            return ( result =~ /^[A-Z]$/i );
        };
    };

    sub g {
        my ($f) = @_;
        ... # call $f somehow
    }

    postcondition g => sub {
        return ( result > 0 );
    };

Thus, when the function C<f()> is used within C<g()>, the contracts set up for
C<f()> in the precondition apply to it.

=head1 FAQ

=head2 Aren't contracts just assertions I could write with something like C<die unless> ?

The answer to this has been nicely worded by Jim Weirich in "Design by Contract
and Unit Testing" located at
L<http://onestepback.org/index.cgi/Tech/Programming/DbcAndTesting.html>:

"Although Design by Contract and assertions are very closely related, DbC is
more than just slapping a few assertions into your code at strategic locations.
It is about identifying the contract under which your code will execute and you
expect all clients to adhere to. It is about clearly defining responsibilities
between client software and supplier software.

"In short, Design by Contract starts by specifying the conditions under which
it is legal to call a method. It is the responsibility of the client software
to ensure these conditions (called preconditions) are met.

"Given that the preconditions are met, the method in the supplier software
guarantees that certion other conditions will be true when the method returns.
These are called postcondition, and are the responsibility of the supplier code
in ensure."

=head2 Why not just use Carp::Assert?

Use L<Carp::Assert> and L<Carp::Assert> if you need to check I<values>. If you
want to assert I<behavior>, L<Class::Agreement> does everything that
L<Carp::Assert> can do for you B<and> it determines which components are faulty
when something fails.

If you're looking for the sexiness of L<Carp::Assert::More>, try using
L<Class::Agreement> with something like L<Data::Validate>:

    use Class::Agreement;
    use Data::Validate qw(:math :string);

    precondition foo => sub { is_integer( $_[1] ) };
    precondition bar => sub { is_greater_than( $_[1], 0 ) };
    precondition baz => sub { is_alphanumeric( $_[1] ) };

=head2 How do I save an old copy of the object?

Hopefully you don't need to. Just save the variable (or variables) you need to
check in the postcondition by creating closures. See L</"Testing old values">
for an example of how to do this.

=head2 How do I disable contracts?

Before you ask this, B<determine why you want to do this>. If your contracts
are slowing down your program, first try following these guidelines:

=over 4

=item * B<Don't clone.> 

Cloning in Perl is expensive. Hopefully you've read the above examples on
L</"Testing old values"> and have realized that cloning an object isn't
necessary. 

=item * B<Don't recreate the function in the contract.> 

If your contract is performing the exact same tasks or calculations that are in
the function itself, toss it. Only code the essentials into the contracts, such
as "this function returns a number greater than twelve" or "the object was
modified in this mannar."

=item * B<Don't do type-checking in the contracts.> 

You can if you want, but contracts are designed to be I<declarations of
behavior>, not to enforce the types of data structures you're passing around.

=back

If you really want to disable this module, replace C<use Class::Agreement> with
C<use Class::Agreement::Dummy>, which exports identically-named functions that
do nothing.

=head2 What do you mean, "There's a problem with the hierarchy?"

The Liskov-Wing principle states, "The objects of subtype ought to behave the
same as those of the supertype as far as anyone or any program using the
supertype objects can tell." (See: "Liskov Wing Subtyping" at
L<http://c2.com/cgi/wiki?LiskovWingSubtyping>.) Say that C<ClassA> is a parent
class of C<ClassB>, and both classes implement a method C<m()>, and both
implementations have pre- and postconditions. According to Liskov-Wing, the
valid input of C<ClassA::m()> should be a I<subset> of the valid input of
C<ClassB::m()>. Thus, if the precondition for C<ClassA::m()> fails but the
precondition for C<ClassB::m()> passes, the class heiarchy fails the principle.
Postconditions are the opposite: the output of C<ClassA::m()> should be
a I<superset> of the output of C<ClassB::m()>. If the postcondition for
C<ClassA::m()> passes but the postcondition for C<ClassB::m()> fails, this
violates the principle. 

=head2 Can I modify the argument list?

If the argument list C<@_> is made up of simple scalars, no. However, if the
method or function is passed a reference of some sort. This is a Bad Thing
because your code should

=head2 How can I type less?

...or more ugly? Use implicit returns and don't name your variables. For
example, the dependent contract in L</"Dependent Contracts"> could be written as
follows:

    dependent insert_tile => sub {
        my $o = shift()->num_tiles;
        sub { shift()->num_tiles > $o };
    };

Other examples:

    precondition sqrt => sub { shift() > 0 };

    postcondition digits => sub { result =~ /^\d+$/ };

    invariant sub { shift()->size > 4 };

Or, write your own generator to make things clean:

    sub argument_is_divisible_by {
        my $num = shift;
        return sub { not $_[1] % $num };
    }

    precondition foo => argument_is_divisible_by(2);
    precondition bar => argument_is_divisible_by(3);

=head2 What if I generate methods?

There's no problem as long as you build your subroutines before runtime,
probably by sticking the generation in a C<BEGIN> block.

Here's a snippet from one of the included tests, F<t/generate-methods.t>. Three
methods, C<foo>, C<bar> and C<baz>, are created and given an assertion that the
argument passed to them must be greater than zero:

    my $assertion = sub { $_[1] > 0 };
    precondition foo => $assertion;
    precondition bar => $assertion;
    precondition baz => $assertion;

    BEGIN {
        no strict 'refs';
        *{$_} = sub { }
            for qw( foo bar baz );
    }

=head1 CAVEATS

=over 4

=item * You can't add contracts for abstract methods. If you try to add a contract to a method that isn't implemented in the given class or any of its parents, L<Class::Agreement> will croak. One must declare an empty subroutine to get around this.

=item * The C<wantarray> keyword will not properly report void context to any methods with contracts. 

=item * The C<caller> keyword will return an extra stack frame.

=back

=head1 AUTHOR

Ian Langworth, C<< <ian@cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-class-agreement@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Class-Agreement>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 ACKNOWLEDGEMENTS

Thanks to Prof. Matthias Felleisen who granted me a directed study to pursue
this project and guided me during its development.

Thanks to a number of other people who contributed to this module in some way,
including: Damian Conway, Simon Cozens, Dan "Lamech" Friedman, Uri Guttman,
Christian Hansen, Adrian Howard, David Landgren, Curtis "Ovid" Poe, Ricardo
SIGNES, Richard Soderburg, Jesse Vincent.

=head1 SEE ALSO

L<Class::Contract>, L<Hook::LexWrap>, L<Carp::Assert>, L<Carp::Assert::More>,
L<Param::Util>

L<http://citeseer.ist.psu.edu/findler01objectoriented.html>,
L<http://c2.com/cgi/wiki?LiskovWingSubtyping>

=head1 COPYRIGHT & LICENSE

Copyright 2005 Ian Langworth, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;    # End of Class::Agreement

