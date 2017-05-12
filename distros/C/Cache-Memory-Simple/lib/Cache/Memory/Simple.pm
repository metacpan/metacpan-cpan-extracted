package Cache::Memory::Simple;
use strict;
use warnings;
use Time::HiRes;
use 5.008001;
our $VERSION = '1.03';

sub new {
    my ($class) = @_;
    bless {}, $class;
}

sub get {
    my ($self, $key) = @_;
    my $val = $self->{$key};
    if (defined $val->[0]) {
        if ($val->[0] > Time::HiRes::time() ) {
            return $val->[1];
        } else {
            delete $self->{$key}; # remove expired data
            return undef;
        }
    } else {
        return $val->[1];
    }
}

sub get_or_set {
    my ($self, $key, $code, $expiration) = @_;

    if (my $val = $self->get($key)) {
        return $val;
    } else {
        my $val = $code->();
        $self->set($key, $val, $expiration);
        return $val;
    }
}

sub set {
    my ($self, $key, $val, $expiration) = @_;
    $self->{$key} = [defined($expiration) 
                         ? $expiration + Time::HiRes::time()
                         : undef,
                     $val];
    return $val;
}

sub delete :method {
    my ($self, $key) = @_;
    delete $self->{$key};
}
sub remove { shift->delete(@_) } # alias

sub delete_all {
    my $self = shift;
    delete $self->{$_} for keys %$self;
    return;
}

sub purge {
    my $self = shift;
    for my $key (keys %{$self}) {
        my $entry = $self->{$key}->[0];
        if (defined($entry) && $entry < Time::HiRes::time() ) {
            delete $self->{$key};
        }
    }
}

sub count {
    my $self = shift;
    return 0+keys %{$self};
}

1;
__END__

=encoding utf8

=head1 NAME

Cache::Memory::Simple - Yet another on memory cache

=head1 SYNOPSIS

    use Cache::Memory::Simple;
    use feature qw/state/;

    sub get_stuff {
        my ($class, $key) = @_;

        state $cache = Cache::Memory::Simple->new();
        $cache->get_or_set(
            $key, sub {
                Storage->get($key) # slow operation
            }, 10 # cache in 10 seconds
        );
    }

=head1 DESCRIPTION

Cache::Memory::Simple is yet another on memory cache implementation.

=head1 METHODS

=over 4

=item C<< my $obj = Cache::Memory::Simple->new() >>

Create a new instance.

=item C<< my $stuff = $obj->get($key); >>

Get a stuff from cache storage by C<< $key >>

=item C<< $obj->set($key, $val, $expiration) >>

Set a stuff for cache.

=item C<< $obj->get_or_set($key, $code, $expiration) >>

Get a cache value for I<$key> if it's already cached. If it's not cached then, run I<$code> and cache I<$expiration> seconds
and return the value.

=item C<< $obj->delete($key) >>

Delete key from cache.

=item C<< $obj->remove($key) >>

Alias for 'delete' method(Net::DNS::Lite require this method name).

=item C<< $obj->purge() >>

Purge expired data.

This module does not purge expired data automatically. You need to call this method if you need.

=item C<< $obj->delete_all() >>

Remove all data from cache.

=back

=head1 AUTHOR

Tokuhiro Matsuno E<lt>tokuhirom AAJKLFJEF@ GMAIL COME<gt>

=head1 SEE ALSO

=head1 LICENSE

Copyright (C) Tokuhiro Matsuno

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

