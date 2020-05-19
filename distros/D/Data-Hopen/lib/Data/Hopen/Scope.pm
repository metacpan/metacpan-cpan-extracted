# Data::Hopen::Scope - a nested key-value store
package Data::Hopen::Scope;
use strict;
use Data::Hopen::Base;
use Exporter 'import';
use Scalar::Util qw(refaddr);

our $VERSION = '0.000018';

# Class definition
use Class::Tiny {
    outer => undef,
    local => false,
    name => 'anonymous scope',
    merge_strategy => undef,

    # Internal
    _first_set => undef,        # name of the first set
    _merger_instance => undef,  # A Hash::Merge instance
};

# Static exports
use vars::i '@EXPORT_OK_PUBLIC' => [qw(is_first_only)];
use vars::i {
    '@EXPORT' => [qw(FIRST_ONLY)],
    '@EXPORT_OK' => [@EXPORT_OK_PUBLIC, qw(_set0)],
};
use vars::i '%EXPORT_TAGS' => {
    'default' => [@EXPORT],
    'all' => [@EXPORT, @EXPORT_OK_PUBLIC],
    'internal' => [qw(_set0)],
};

my $_first_only = {};
sub FIRST_ONLY { $_first_only }

use constant _LOCAL => 'local';

# What we use
use Config;
use Data::Hopen qw(getparameters);
use Data::Hopen::Util::Data qw(clone forward_opts);
use Hash::Merge;
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

=head2 merge_strategy

How the inputs of L</merge> will be treated.  Case-insensitive.  Note that
changes after the first time you call L</merge> will be ignored!
(TODO change this - just need a custom setter)

Values are:

=over

=item C<undef> or C<'combine'> (default)

L<Hash::Merge/Retainment Precedence>.  Same-name keys
are merged, so no data is lost.

=item C<'keep'>

L<Hash::Merge/Left Precedence>.  Existing data will not be replaced by
new data.

=item C<'replace'>

L<Hash::Merge/Right Precedence>.  New data will replace existing data.
under a particular key will win.

=back

=head1 PARAMETERS

The methods generally receive the same parameters.  They are as follows.

=head2 $name

The name of an item to be looked up.  Names must be truthy.  That means,
among other things, that C<'0'> is not a valid name.

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

See also L</put>, below, which is part of the public API.

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

TODO support a C<$set> parameter

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

TODO support a C<$set> parameter

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

=head2 _merger (internal)

Creates a L<Hash::Merge> instance based on L</merge_strategy>, if one
doesn't exist.  Returns the instance.

Provided for the convenience of subclasses; not actually used by
any concrete functions in this package.

=cut

sub _merger {
    my $self = shift or croak 'Need an instance';
    return $self->_merger_instance if $self->_merger_instance;

    my $s = $self->merge_strategy;
    my $precedence =
        !defined $s ? 'RETAINMENT_PRECEDENT' :
            $s =~ /^combine$/i ? 'RETAINMENT_PRECEDENT' :
                $s =~ /^keep$/i ? 'LEFT_PRECEDENT' :
                    $s =~ /^replace$/i ? 'RIGHT_PRECEDENT' :
                        undef;
    die "Invalid merge strategy $s" unless defined $precedence;

    my $merger = Hash::Merge->new($precedence);
    $merger->set_clone_behavior(false);
        # TODO CHECKME --- I would rather clone everything except blessed
        # references, but doing so appears to be nontrivial.  For now,
        # I am trying not cloning.
    $self->_merger_instance($merger);

    return $merger;
} #_merger()

=head1 FUNCTIONS TO BE OVERRIDDEN IN SUBCLASSES

To implement a Scope with a different data-storage model than the hash
this class uses, subclass Scope and override these functions.  Of these,
only L</put> and L</merge> are part of the public API.

=head2 put

Add key-value pairs to this scope.  Returns the scope so you can
chain.  Example usage:

    my $scope = Data::Hopen::Scope->new()->put(foo => 1);

C<put> overwrites data in case of any conflicts.  See L</merge> if you
want more control.

C<put> may be called with no parameters, in which case it is a no-op.
This is so you can say C<< $s->put(%foo) >> without first having to
check whether C<%foo> is nonempty.

TODO add C<$set> option.  TODO? add -deep option?

=cut

sub put {
    ...
} #put()

=head2 merge

Merges key-value pairs into this scope.  Returns the scope so you can
chain.  Example usage:

    my $scope = Data::Hopen::Scope->new()->merge(foo => 1);

See L</merge_strategy> for options controlling the behaviour of C<merge()>.
=cut

sub merge { #blub blub
    my $self = shift or croak 'Need an instance';
    my $merger = $self->_merger;
    ...
} #merge()

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

=head1 HELPER FUNCTIONS

=head2 is_first_only

Test whether the given scalar is L</FIRST_ONLY>.  Usage: C<is_first_only($x)>.

=cut

sub is_first_only {
    ref $_[0] &&
    ref $_[0] eq ref $_first_only &&
    refaddr $_[0] == refaddr $_first_only
} #is_first_only()

=head2 _set0

For use only by subclasses.

Don't support C<-set>, but permit C<< -set=>0 >> and C<< -set=>FIRST_ONLY >>
for the sake of code calling through the Scope interface.  Call as
C<set0($set)>>.  Returns truthy if OK, falsy if not.  May modify its argument.
Better a readily-obvious crash than a subtle bug!

=cut

sub _set0 {
    $_[0] //= 0;    # Give the caller a default set
    $_[0] = 0 if Data::Hopen::Scope::is_first_only($_[0]);
    my $set = shift;
    return false if $set ne '0' && $set ne '*';
    return true;
} #_set0()

1;
__END__
# vi: set fdm=marker: #
