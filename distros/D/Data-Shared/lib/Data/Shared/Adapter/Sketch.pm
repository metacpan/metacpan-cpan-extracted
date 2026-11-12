package Data::Shared::Adapter::Sketch;
use strict;
use warnings;
use Carp ();
use parent 'Data::Shared::Adapter';

our $VERSION = '0.01';

our @CARP_NOT = qw(Data::Shared);

sub _key {
    my ($entry, $rest) = @_;
    Carp::croak("Data::Shared: path too short: mount has no key") unless @$rest;
    Carp::croak("Data::Shared: path too long: $entry->{key} takes one key component")
        if @$rest > 1;
    return $rest->[0];
}

sub make_verb {
    my ($class, $verb, $handle, $entry) = @_;
    my $spec = Data::Shared::Adapter::_spec($entry, $verb);
    return undef unless defined $spec;
    if (ref $spec eq 'CODE') {
        return sub {
            my ($rest, @a) = @_;
            my $key = _key($entry, $rest);
            return $spec->($handle, $key, @a);
        };
    }
    my $method = $handle->can($spec);
    if (!$method) {
        my $msg = Data::Shared::Adapter::_unsupported($entry, $handle, $spec);
        return sub { Carp::croak($msg) };
    }
    return sub {
        my ($rest, @a) = @_;
        my $key = _key($entry, $rest);
        return $handle->$method($key, @a);
    };
}

sub make_bound {
    my ($class, $verb, $handle, $entry, $rest) = @_;
    my $spec = Data::Shared::Adapter::_spec($entry, $verb);
    return undef unless defined $spec;
    my $key = _key($entry, $rest);
    if (ref $spec eq 'CODE') {
        return sub { my @a = @_; return $spec->($handle, $key, @a) };
    }
    my $method = $handle->can($spec);
    if (!$method) {
        my $msg = Data::Shared::Adapter::_unsupported($entry, $handle, $spec);
        return sub { Carp::croak($msg) };
    }
    return sub { my @a = @_; return $handle->$method($key, @a) };
}

sub perform_push { Carp::croak("Data::Shared: push is not supported for sketch mounts (use shared_call)") }
sub perform_pop  { Carp::croak("Data::Shared: pop is not supported for sketch mounts (use shared_call)") }

1;

__END__

=head1 NAME

Data::Shared::Adapter::Sketch - Internal adapter for sketch mounts (Data::Shared)

=head1 DESCRIPTION

Internal to L<Data::Shared>; not a public API. Serves the keyed
generic verbs of CountMinSketch and TopK; all other sketches are
mount-only and reject generic verbs toward C<shared_call>.

=cut
