# Data::Hopen::Scope::Environment - a hopen Scope for %ENV
# TODO handle $set == FIRST_ONLY
package Data::Hopen::Scope::Environment;
use strict;
use Data::Hopen::Base;

our $VERSION = '0.000015';

use parent 'Data::Hopen::Scope';

use Data::Hopen qw(hlog getparameters);
use Set::Scalar;

# Docs {{{1

=head1 NAME

Data::Hopen::Scope::Environment - a Data::Hopen::Scope of %ENV

=head1 SYNOPSIS

This is a thin wrapper around C<%ENV>, implemented as a
L<Data::Hopen::Scope>.  It only supports one set of data
(L<Data::Hopen::Scope/$set>), which is named C<0> for consistency
with L<Data::Hopen::Scope::Hash>.

=head1 METHODS

Note: L<Data::Hopen::Scope/merge> is unsupported.

=cut

# }}}1

### Protected functions ###

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

=head2 _find_here

Find a named data item in C<%ENV> and return it.  Returns undef on
failure.

=cut

sub _find_here {
    my ($self, %args) = getparameters('self', [qw(name ; set)], @_);
    _set0 $args{set} or croak 'I only support set 0';
    my $val = $ENV{$args{name}};
    return undef unless defined $val;
    return ($args{set} eq '*') ? { 0 => $val } : $val;
} #_find_here()

=head2 put

Updates the corresponding environment variables, in order, by setting C<$ENV{}>.
Returns the instance.

=cut

sub put {
    my $self = shift;
    croak "Got an odd number of parameters" if @_%2;
    while(@_) {
        my $k = shift;
        $ENV{$k} = shift;
    }
    return $self;
} #add()

=head2 _names_here

Add the names in C<%ENV> to the given L<Set::Scalar>.

=cut

sub _names_here {
    my ($self, %args) = getparameters('self', [qw(retval ; set)], @_);
    _set0 $args{set} or croak 'I only support set 0';
    $args{retval}->insert(keys %ENV);
    hlog { __PACKAGE__ . '::_names_here', Dumper $args{retval} } 9;
        # Don't usually log, since the environment is often fairly hefty!
} #_names_here()

1;
__END__
# vi: set fdm=marker: #
