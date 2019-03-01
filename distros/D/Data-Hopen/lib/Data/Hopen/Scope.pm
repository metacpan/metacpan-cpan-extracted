# Data::Hopen::Scope - a nested key-value store
package Data::Hopen::Scope;
use Data::Hopen::Base;
use Exporter 'import';

our $VERSION = '0.000012';

# Class definition
use Class::Tiny {
    outer => undef,
    local => false,
    name => 'anonymous scope',

    # Internal
    _first_set => undef,    # name of the first set
};

# Static exports
our @EXPORT; BEGIN { @EXPORT=qw(FIRST_ONLY); }

my $_first_only = {};
sub FIRST_ONLY { $_first_only }

use constant _LOCAL => 'local';

# What we use
use Config;
use Data::Hopen qw(getparameters);
use Data::Hopen::Util::Data qw(clone forward_opts);
use POSIX ();
use Set::Scalar;
use Sub::ScopeFinalizer qw(scope_finalizer);

# Docs {{{1

=head1 NAME

Data::Hopen::Scope - a nested key-value store.

=head1 SYNOPSIS

A Scope represents a set of data available to operations.  It is a
key-value store that falls back to an outer C<Scope> if a requested key
isn't found.

This class is the abstract base of Scopes.  See L<Data::Hopen::Scope::Hash>
for an example of a concrete implementation using a hash under the
hood.  Different subclasses use different representations.
See L</"FUNCTIONS TO BE OVERRIDDEN IN SUBCLASSES"> for more on that topic.

=head1 STATIC EXPORTS

=head2 FIRST_ONLY

A flag used as a L</$set> (q.v.).

=head1 ATTRIBUTES

=head2 outer

The fallback C<Scope> for looking up names not found in this C<Scope>.
If non is provided, it is C<undef>, and no fallback will happen.

=head2 local

(Default falsy.)  If truthy, do not go past this scope when doing local
lookups (see L</$levels> below).

=head2 name

Not used, but provided so you can use L<Data::Hopen/hnew> to make Scopes.

=head1 PARAMETERS

The methods generally receive the same parameters.  They are as follows.

=head2 $name

The name of an item to be looked up.  Names must be truthy.  That means,
among other things, that C<'0'> is not a valid key.

=head2 $set

A Scope can have multiple sets of data.  C<$set> specifies which one to
look in.

=over

=item *

If specified as a number or a name, look only in that set.

=item *

If C<'*'>, look in every available set at this level, and return a
hashref of C<< { set_name => value } >>.
Note that this is not recursive --- it won't collect all instances
of the given name from all sets in all the levels. (TODO? change this?)

=item *

If L</FIRST_ONLY>, look in only the first set (usually named C<0>).

=item *

If unspecified or undefined, look in every available set at this level, and
return the first one found, regardless of which set it comes from.

=back

=head2 $levels

How many levels up (L</outer>) to go when performing an operation.  Note:
chains more than C<POSIX::INT_MAX> (L<POSIX/LIMITS>) Scopes long may fail in
unexpected ways, depending on your platform!  For 32- or 64-bit platforms,
that number is at least 2,000,000,000, so you're probably OK :) .

=over

=item *

If numeric and non-negative, go up that many more levels
(i.e., C<$levels==0> means only return this scope's local names).

=item *

If C<'local'>, go up until reaching a scope with L</local> set.
If the current scope has L</local> set, don't go up at all.

=item *

If not provided or not defined, go all the way to the outermost Scope.

=back

=head1 METHODS

See also L</add>, below, which is part of the public API.

=cut

# }}}1

# Handle $levels and invoke a function on the outer scope if appropriate.
# Usage:
#   $self->_invoke('method_name', $levels, [other args to be passed, starting
#                                           with invocant, if any]
# A new levels value will be added to the end of the args as -levels=>$val.
# Returns undef if there's no more traversing to be done.

sub _invoke {
    my $self = shift or croak 'Need an instance';
    my $method_name = shift or croak 'Need a method name';
    my $levels = shift;

    # Handle 'local'-scoped searches by terminating when $self->local is set.
    $levels = 0 if ( ($levels//'') eq _LOCAL) && $self->local;

    # Search the outer scopes
    if($self->outer &&              # Search the outer scopes
        (!defined($levels) || ($levels eq _LOCAL) || ($levels>0) )
    ) {
        my $newlevels =
            !defined($levels) ? undef :
                ( ($levels eq _LOCAL) ? _LOCAL : ($levels-1) );

        unshift @_, $self->outer;
        push @_, -levels => $newlevels;
        my $coderef = $self->outer->can($method_name);
        return $coderef->(@_) if $coderef;
    }
    return undef;
} #_invoke()

=head2 find

Find a named data item in the scope and return it.  Looks up the scope chain
to the outermost scope if necessary.  Returns undef on
failure.  Usage:

    $scope->find($name[, $set[, $levels]]);
    $scope->find($name[, -set => $set][, -levels => $levels]);
        # Alternative using named arguments

Dies if given a falsy name, notably, C<'0'>.

=cut

sub find {
    my ($self, %args) = getparameters('self', [qw(name ; set levels)], @_);
    croak 'Need a name' unless $args{name};
        # Therefore, '0' is not a valid name
    my $levels = $args{levels};

    my $here = $self->_find_here($args{name}, $args{set});
    return $here if defined $here;

    return $self->_invoke('find', $args{levels},
        forward_opts(\%args, {'-'=>1}, qw(name set))
    );
} #find()

=head2 names

Returns a L<Set::Scalar> of the names of the items available through this
Scope, optionally including all its parent Scopes (if any).  Usage
and example:

    my $set = $scope->names([$levels]);
    say "Name $_ is available" foreach @$set;   # Set::Scalar supports @$set

If no names are available in the given C<$levels>, returns an empty
C<Set::Scalar>.

TODO?  Support a C<$set> parameter?

=cut

sub names {
    my ($self, %args) = getparameters('self', [qw(; levels)], @_);
    my $retval = Set::Scalar->new;
    $self->_fill_names($retval, $args{levels});
    return $retval;
} #names()

# Implementation of names()
sub _fill_names {
    #say Dumper(\@_);
    my ($self, %args) = getparameters('self', [qw(retval levels)], @_);

    $self->_names_here($args{retval});    # Insert this scope's names

    return $self->_invoke('_fill_names', $args{levels}, -retval=>$args{retval});
} #_fill_names()

=head2 as_hashref

Returns a hash of the items available through this Scope, optionally
including all its parent Scopes (if any).  Usage:

    my $hashref = $scope->as_hashref([-levels => $levels][, -deep => $deep])

If C<$levels> is provided and nonzero, go up that many more levels
(i.e., C<$levels==0> means only return this scope's local names).
If C<$levels> is not provided, go all the way to the outermost Scope.

If C<$deep> is provided and truthy, make a deep copy of each value (using
L<Data::Hopen/clone>.  Otherwise, just copy.

TODO?  Support a C<$set> parameter?

=cut

sub as_hashref {
    my ($self, %args) = getparameters('self', [qw(; levels deep)], @_);
    my $hrRetval = {};
    $self->_fill_hashref($hrRetval, $args{deep}, $args{levels});
    return $hrRetval;
} #as_hashref()

# Implementation of as_hashref.  Mutates the provided $hrRetval.
sub _fill_hashref {
    my ($self, %args) = getparameters('self', [qw(retval levels deep)], @_);
    my $hrRetval = $args{retval};

    # Innermost wins, so copy ours first.
    my $names = Set::Scalar->new;
    $self->_names_here($names);

    foreach my $k (@$names) {
        unless(exists($hrRetval->{$k})) {   # An inner scope might have set it
            my $val = $self->find($k, -levels => 0);
            $hrRetval->{$k} =
                ($args{deep} ? clone($val) : $val);
        }
    }

    return $self->_invoke('_fill_hashref', $args{levels},
        forward_opts(\%args, {'-'=>1}, qw(retval deep)));
} #_fill_hashref()

=head2 outerize

Set L</outer>, and return a scalar that will restore L</outer> when it
goes out of scope.  Usage:

    my $saver = $scope->outerize($new_outer);

C<$new_outer> may be C<undef> or a valid C<Scope>.

=cut

sub outerize {
    my ($self, %args) = getparameters('self', [qw(outer)], @_);

    croak 'Need a Scope' unless
        (!defined($args{outer})) or
        (ref $args{outer} && eval { $args{outer}->DOES('Data::Hopen::Scope') });

    # Protect the author of this function from himself
    croak 'Sorry, but I must insist that you save my return value'
        unless defined wantarray;

    my $old_outer = $self->outer;
    my $saver = scope_finalizer { $self->outer($old_outer) };
    $self->outer($args{outer});
    return $saver;
} #outerize()

=head1 FUNCTIONS TO BE OVERRIDDEN IN SUBCLASSES

To implement a Scope with a different data-storage model than the hash
this class uses, subclass Scope and override these functions.  Only L</add>
is part of the public API.

=head2 add

Add key-value pairs to this scope.  Returns the scope so you can
chain.  Example usage:

    my $scope = Data::Hopen::Scope->new()->add(foo => 1);

C<add> is responsible for handling any conflicts that may occur.  In this
particular implementation, the last-added value for a particular key wins.

TODO add C<$set> option.  TODO? add -deep option?

=cut

sub add {
    ...
} #add()

=head2 _names_here

Populates a L<Set::Scalar> with the names of the items stored in this Scope,
but B<not> any outer Scope.  Called as:

    $scope->_names_here($retval[, $set])

C<$retval> is the C<Set::Scalar> instance.  C<$set> is as
defined L<above|/$set>.

No return value.

=cut

sub _names_here {
    ...
} #_names_here()

=head2 _find_here

Looks for a given item in this scope, but B<not> any outer scope.  Called as:

    $scope->_find_here($name[, $set])

Returns the value, or C<undef> if not found.

=cut

sub _find_here {
    ...
} #_find_here()

1;
__END__
# vi: set fdm=marker: #
