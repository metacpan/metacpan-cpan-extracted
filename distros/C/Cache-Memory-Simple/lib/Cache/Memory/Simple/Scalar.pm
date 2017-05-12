package Cache::Memory::Simple::Scalar;
use strict;
use warnings;
use utf8;

use Time::HiRes;
use 5.008001;

use constant {
    TIME  => 0,
    VALUE => 1,
};

sub new {
    my ($class) = @_;
    bless [undef, undef], $class;
}

sub get {
    my ($self) = @_;
    if (defined $self->[TIME]) { # data with expiration
        if ($self->[TIME] > Time::HiRes::time()) {
            return $self->[VALUE];
        } else {
            undef $self->[VALUE]; # remove expired data
            return undef;
        }
    } else {
        return $self->[VALUE];
    }
}

sub get_or_set {
    my ($self, $code, $expiration) = @_;

    if (my $val = $self->get()) {
        return $val;
    } else {
        my $val = $code->();
        $self->set($val, $expiration);
        return $val;
    }
}

sub set {
    my ($self, $val, $expiration) = @_;
    $self->[TIME] = defined($expiration)
                    ? $expiration + Time::HiRes::time()
                    : undef;
    $self->[VALUE] = $val;
    return $val;
}

sub delete :method {
    my ($self) = @_;
    undef $self->[VALUE];
    return undef;
}

1;
__END__

=encoding utf8

=head1 NAME

Cache::Memory::Simple::Scalar - Cache one scalar value

=head1 SYNOPSIS

    use Cache::Memory::Simple::Scalar;
    use feature qw/state/;

    sub get_stuff {
        my ($class, $key) = @_;

        state $cache = Cache::Memory::Simple::Scalar->new();
        $cache->get_or_set(
            sub {
                Storage->get($key) # slow operation
            }, 10 # cache in 10 seconds
        );
    }

=head1 DESCRIPTION

Cache::Memory::Simple::Scalar is cache storage for one scalar value with expiration.

=head1 METHODS

=over 4

=item C<< my $obj = Cache::Memory::Simple::Scalar->new() >>

Create a new instance.

=item C<< my $stuff = $obj->get(); >>

Get a stuff from cache storage.

=item C<< $obj->set($val, $expiration) >>

Set a stuff to cache.

I<$expiration> is in seconds.

=item C<< $obj->get_or_set($code, $expiration) >>

Get a cache value if it's already cached. If it's not cached then, run I<$code> and cache I<$expiration> seconds
and return the value.

=item C<< $obj->delete() >>

Delete cache from cache.

=back

=head1 AUTHOR

Tokuhiro Matsuno E<lt>tokuhirom AAJKLFJEF@ GMAIL COME<gt>

=head1 SEE ALSO

=head1 LICENSE

Copyright (C) Tokuhiro Matsuno

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

