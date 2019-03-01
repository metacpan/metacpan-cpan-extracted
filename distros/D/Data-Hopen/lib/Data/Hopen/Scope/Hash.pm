# Data::Hopen::Scope::Hash - a hash-based nested key-value store based
package Data::Hopen::Scope::Hash;
use Data::Hopen::Base;

our $VERSION = '0.000012';

use parent 'Data::Hopen::Scope';
use Class::Tiny {
    _content => sub { +{} },    # Our storage
};

use Data::Hopen qw(getparameters);
#use Data::Hopen::Util::Data qw(clone);
use Set::Scalar;
#use Sub::ScopeFinalizer qw(scope_finalizer);


# Docs {{{1

=head1 NAME

Data::Hopen::Scope::Hash - a hash-based nested key-value store

=head1 SYNOPSIS

This class implements L<Data::Hopen::Scope> using a single hash table as the
storage.  It only supports one set of data (L<Data::Hopen::Scope/$set>),
which is named C<0>.

=head1 ATTRIBUTES

=head2 outer

The fallback C<Scope> for looking up names not found in this C<Scope>.
If non is provided, it is C<undef>, and no fallback will happen.

=head2 name

Not used, but provided so you can use L<Data::Hopen/hnew> to make Scopes.

=head1 METHODS

See also L</add>, below, which is part of the public API.

Several of the functions receive a C<$levels> parameter.  Its meaning is:

=over

=item *

If C<$levels> is provided and nonzero, go up that many more levels
(i.e., C<$levels==0> means only return this scope's local names).

=item *
If C<$levels> is not provided or not defined, go all the way to the
outermost Scope.

=back

=cut

# }}}1

# Don't support -set, but permit `-set=>0` for the sake of code calling
# through the Scope interface.  Call as `_set0($set)`.
# Returns truthy of OK, falsy if not.
# Better a readily-obvious crash than a subtle bug!
sub _set0 {
    $_[0] //= 0;    # Give the caller a default set
    my $set = shift;
    return false if defined($set) && $set ne '0' && $set ne '*';
    return true;
} #_set0()

=head1 FUNCTIONS TO BE OVERRIDDEN IN SUBCLASSES

To implement a Scope with a different data-storage model than the hash
this class uses, subclass Scope and override these functions.  Only L</add>
is part of the public API.

=head2 add

Add key-value pairs to this scope.  Returns the scope so you can
chain.  Example usage:

    my $scope = Data::Hopen::Scope::Hash->new()->add(foo => 1);

C<add> is responsible for handling any conflicts that may occur.  In this
particular implementation, the last-added value for a particular key wins.

TODO add $set option

=cut

sub add {
    my $self = shift or croak 'Need an instance';
    croak "Got an odd number of parameters" if @_%2;
    my %new = @_;
    @{$self->_content}{keys %new} = values %new;
    return $self;
} #add()

=head2 adopt_hash

Takes over the given hash to be the new contents of the Scope::Hash.
Usage example:

    $scope->adopt_hash({ foo => 42 });

The scope uses exactly the hash passed, not a clone of it.  If this is not
applicable to a subclass, that subclass should override it as C<...> or an
express C<die>.

=cut

sub adopt_hash {
    my $self = shift or croak 'Need an instance';
    my $hrNew = shift or croak 'Need a hash to adopt';
    croak 'Cannot adopt a non-hash' unless ref $hrNew eq 'HASH';
    $self->_content($hrNew);
    return $self;
} #adopt_hash()

=head2 _names_here

Populates a L<Set::Scalar> with the names of the items stored in this Scope,
but B<not> any outer Scope.  Called as:

    $scope->_names_here($retval[, $set]);

No return value.

=cut

sub _names_here {
    my ($self, %args) = getparameters('self', [qw(retval ; set)], @_);
    _set0 $args{set} or croak 'I only support set 0';
    $args{retval}->insert(keys %{$self->_content});
} #_names_here()

=head2 _find_here

Looks for a given item in this scope, but B<not> any outer scope.  Called as:

    $scope->_find_here($name[, $set])

Returns the value, or C<undef> if not found.

=cut

sub _find_here {
    my ($self, %args) = getparameters('self', [qw(name ; set)], @_);
    _set0 $args{set} or croak 'I only support set 0';

    my $val = $self->_content->{$args{name}};
    return undef unless defined $val;
    return ($args{set} eq '*') ? { 0 => $val } : $val;
} #_find_here()

1;
__END__
# vi: set fdm=marker: #
