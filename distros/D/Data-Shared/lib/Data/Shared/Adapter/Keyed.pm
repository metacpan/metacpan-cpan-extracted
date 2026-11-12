package Data::Shared::Adapter::Keyed;
use strict;
use warnings;
use Carp ();
use parent 'Data::Shared::Adapter';
use Data::Shared::Registry ();

our $VERSION = '0.01';

our @CARP_NOT = qw(Data::Shared);

sub _noun { 'key' }

sub _key {
    my ($entry, $rest, $verb, $noun) = @_;
    Carp::croak("Data::Shared: path too short: mount has no $noun") unless @$rest;
    return join('/', @$rest) if $entry->{key_join};
    Carp::croak("Data::Shared: path too long: $entry->{key} takes one $noun component")
        if @$rest > 1;
    # A non-integer key would numify to element 0; exists answers 0 instead (see _absent).
    Data::Shared::Registry::_assert_index($entry->{key}, $rest->[0])
        if $entry->{key_int} && $verb ne 'exists';
    return $rest->[0];
}

# key_int_from: the key type comes from the built file, asked once per binding.
sub _entry_for {
    my ($entry, $handle) = @_;
    my $ask = $entry->{key_int_from} or return $entry;
    return { %$entry, key_int => $ask->($handle) ? 1 : 0 };
}

# exists on an integer mount: a non-integer key would numify to 0 and probe that.
sub _absent {
    my ($entry, $verb, $key) = @_;
    return $verb eq 'exists' && $entry->{key_int}
        && !Data::Shared::Registry::_index_shape_ok($key);
}

# {code, by, absent} or {missing}: code->($handle, $key, @args), by is incr_by for a delta.
# The closures and fast_verb both build on this, so they cannot disagree.
sub _native {
    my ($verb, $handle, $entry) = @_;
    my $spec = Data::Shared::Adapter::_spec($entry, $verb);
    return undef unless defined $spec;
    return { code => $spec } if ref $spec eq 'CODE';
    my $method = $handle->can($spec)
        or return { missing => Data::Shared::Adapter::_unsupported($entry, $handle, $spec) };
    return { code => $method, by => $verb eq 'incr' ? $handle->can('incr_by') : undef,
             absent => $verb eq 'exists' && $entry->{key_int} };
}

sub make_verb {
    my ($class, $verb, $handle, $entry) = @_;
    $entry = _entry_for($entry, $handle);
    my $n = _native($verb, $handle, $entry) or return undef;
    my $missing = $n->{missing};
    return sub { Carp::croak($missing) } if $missing;
    my ($code, $by, $absent) = @$n{qw(code by absent)};
    my $noun = $class->_noun;
    return sub {
        my ($rest, @a) = @_;
        Data::Shared::Registry::_assert_delta($entry->{key}, @a) if $verb eq 'incr';
        my $key = _key($entry, $rest, $verb, $noun);
        return 0 if $absent && !Data::Shared::Registry::_index_shape_ok($key);
        return $by->($handle, $key, $a[0]) if @a && $by;
        return $code->($handle, $key, @a);
    };
}

sub make_bound {
    my ($class, $verb, $handle, $entry, $rest) = @_;
    $entry = _entry_for($entry, $handle);
    my $n = _native($verb, $handle, $entry) or return undef;
    my $key = _key($entry, $rest, $verb, $class->_noun);
    my $missing = $n->{missing};
    return sub { Carp::croak($missing) } if $missing;
    return sub { 0 } if $n->{absent} && !Data::Shared::Registry::_index_shape_ok($key);
    my ($code, $by) = @$n{qw(code by)};
    return sub {
        my @a = @_;
        Data::Shared::Registry::_assert_delta($entry->{key}, @a) if $verb eq 'incr';
        return $by->($handle, $key, $a[0]) if @a && $by;
        return $code->($handle, $key, @a);
    };
}

# The flags Shared.xs reads from a fast_verb descriptor.
use constant { FAST_KEY_INT => 1, FAST_ABSENT => 2, FAST_INCR => 4 };

# [handle, code, by, flags] for the XS dispatch, or undef where only the closure is exact.
sub fast_verb {
    my ($class, $verb, $handle, $entry) = @_;
    $entry = _entry_for($entry, $handle);
    return undef if $entry->{key_join};
    my $n = _native($verb, $handle, $entry) or return undef;
    return undef if $n->{missing};
    return [$handle, $n->{code}, $n->{by},
        ($entry->{key_int} ? FAST_KEY_INT : 0) | ($n->{absent} ? FAST_ABSENT : 0)
        | ($verb eq 'incr' ? FAST_INCR : 0)];
}

1;

__END__

=head1 NAME

Data::Shared::Adapter::Keyed - Internal base for one-component mounts (Data::Shared)

=head1 DESCRIPTION

Internal to L<Data::Shared>; not a public API. Translates generic verbs for
mounts addressed by a single path component into native method calls, and
builds the cached per-verb coderefs used on the dispatch fast path.
L<Data::Shared::Adapter::Map> and L<Data::Shared::Adapter::Set> differ only in
the word they use for that component.

=cut
