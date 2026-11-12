package Data::Shared::Adapter;
use strict;
use warnings;
use Carp ();

our $VERSION = '0.01';

our @CARP_NOT = qw(Data::Shared);

# The facade calls every maker unconditionally; undef means take the slow path.
sub make_verb       { return undef }
sub make_bound      { return undef }
sub make_push       { return undef }
sub make_pop        { return undef }
sub make_bound_push { return undef }
sub make_bound_pop  { return undef }
sub fast_verb       { return undef }

# Called whenever the matching maker returned undef; adapters override the wording.
sub perform_push { Carp::croak("Data::Shared: push is not supported for this mount (use shared_call)") }
sub perform_pop  { Carp::croak("Data::Shared: pop is not supported for this mount (use shared_call)") }

sub perform {
    my ($class, $verb, $handle, $entry, $rest, @args) = @_;
    my $code = $class->make_verb($verb, $handle, $entry);
    Carp::croak($class->_unsupported_verb($verb, $entry)) unless $code;
    return $code->($rest, @args);
}

sub _unsupported_verb {
    my ($class, $verb, $entry) = @_;
    return "Data::Shared: operation '$verb' is not supported for $entry->{key} (use shared_call)";
}

sub _spec {
    my ($entry, $verb) = @_;
    my $verbs = $entry->{verbs} or return undef;
    return $verbs->{$verb};
}

sub _unsupported {
    my ($entry, $handle, $spec) = @_;
    return "Data::Shared: $entry->{key}: " . ref($handle) . " does not support '$spec'"
        . " (use shared_call for operations outside the generic verbs)";
}

1;

__END__

=head1 NAME

Data::Shared::Adapter - Internal base for the per-family adapters (Data::Shared)

=head1 DESCRIPTION

Internal to L<Data::Shared>; not a public API. Holds the adapter interface's
defaults, so each adapter states only what its family supports, and the verb
lookup and unsupported-verb message they share.

=cut
