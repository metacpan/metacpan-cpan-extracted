package AnyEvent::InMemoryCache;
use 5.008005;
use strict;
use warnings;

our $VERSION = "0.01";

use AnyEvent;
use Time::Duration::Parse;

sub new {
    my $class = shift;
    my %args = @_;
    if ( exists $args{expires_in} ) {
        $args{expires_in} = parse_duration($args{expires_in});
    } else {
        $args{expires_in} = -1;  # endless
    }
    $args{_datastore} = {};
    bless \%args, $class;
}

sub set {
    my ($self, $key, $val, $expires_in) = @_;
    if ( @_ < 4) {
        $expires_in = $self->{expires_in};
    } else {
        $expires_in = parse_duration($expires_in);
    }
    $self->{_datastore}{$key} = [
        $val,
        ($expires_in < 0 ? undef : AE::timer $expires_in, 0, sub{ delete $self->{_datastore}{$key} })
    ];
    $val;
}

sub get {
    my ($self, $key) = @_;
    ($self->{_datastore}{$key} || [])->[0];
}

sub exists {
    my ($self, $key) = @_;
    exists $self->{_datastore}{$key};
}

sub delete {
    my ($self, $key) = @_;
    (delete $self->{_datastore}{$key} || [])->[0];
}


# Tie-hash subroutines

*TIEHASH = \&new;
*FETCH   = \&get;
*STORE   = \&set;
*DELETE  = \&delete;
*EXISTS  = \&exists;

sub CLEAR {
    %{$_[0]->{_datastore}} = ();
};

sub FIRSTKEY {
    my $self = shift;
    keys %{$self->{_datastore}};  # rest iterator
    scalar each %{$self->{_datastore}};
}

sub NEXTKEY {
    scalar each %{$_[0]->{_datastore}};
}

sub SCALAR {
    scalar %{$_[0]->{_datastore}};
}


1;
__END__

=encoding utf-8

=head1 NAME

AnyEvent::InMemoryCache - Simple in-memory cache for AnyEvent applications

=head1 SYNOPSIS

    use AnyEvent;
    use AnyEvent::InMemoryCache;
    
    my $cache = AnyEvent::InMemoryCache->new;
    
    $cache->set(immortal => "Don't expire!");  # It lasts forever by default
    say $cache->get("immortal");  # "Don't expire!"
    
    $cache->set(a_second => "Expire soon", "1s");  # Expires in one-second.
    say $cache->get('a_second');  # "Expires soon"
    AE::timer 2, 0, sub{  # 2 seconds later
        $cache->exists('a_second');  # false
    };
    
    # You can overwrite key, and it's mortal now.
    $cache->set(immortal => 'will die...', "10min");
    
    # If you want a key not to be expired, pass negative integer for the third parameter.
    $cache->set(immortal => 'Immortal again!', -1);
    
    # You can specify default lifetime of keys.
    my $cache = AnyEvent::InMemoryCache->new(expires_in => "1 hour");
    
    # You can also tie hash.
    tie my %hash, 'AnyEvent::InMomeryCache', expired_in => '30min';
    $hash{'key'} = "value";  # Automatically deleted 30 minutes later.

=head1 DESCRIPTION

AnyEvent::InMemoryCache provides a really simple in-memory cache mechanism for AnyEvent applications.

=head1 RATIONALE

There are already many cache modules, but many of those are checking whether cached values are still
valid or already expired when fetching the values. That is, every time a value is fetched from the cache,
it takes extra time to check the validity. It is not effective. Even worth, those modules cannot expires
values until they are fetched or explicitly purged by hand. In other words, they cannot free allocated
memory even when the values are already expired.

Thus, I wrote this module.

=head2 ADVANTAGE

This module is completely event-driven. That is, it only checks and expires values when the expiration
time comes. That gives us performance advantage because it need not to check validity of values every
time it fetches values. Also, this can free allocated memory as soon as each value is expired.

=head2 DISADVANTAGE

This module simply does not work unless you use AnyEvent framework correctly.

=head1 METHODS

=head2 C<$class-E<gt>new( expires_in =E<gt> $duration )>

Creates new AnyEvent::InMemoryCache object.

=over

=item C<expires_in> (optional)

Specify default lifetime of cached values.
You can specify any value that L<Time::Duration::Parse> can recognize.
If this parameter is omitted or negative value, it means unlimited lifetime.

=back

=head2 C<$cache-E<gt>set( $key, $value, $duration )>

Store C<$value> as a value of C<$key>.
C<$duration> specifies lifetime of this key & value. It accepts any value
that L<Time::Duration::Parse> can recognize as C<new> does. If C<$duration>
is omitted, it uses default value, which is specified by C<new>. You can also
specify negative integer (e.g. -1) for unlimited lifetime.

=head2 C<$cache-E<gt>get( $key )>

Fetches the value bound to C<$key>.

=head2 C<$cache-E<gt>exists( $key )>

Returns true if C<$key> exists, otherwise returns false.

=head2 C<$cache-E<gt>delete( $key )>

Explicitly expires (deletes) key and value indexed by C<$key>.

=head1 TIE INTERFACE

In addition to OOP interface, you can tie a hash to this module:

    tie my %hash, 'AnyEvent::InMemoryCache', expires_in => '30min';
    $hash{'foo'} = 'bar';  # expires in 30 minutes

Through the tie interface, you cannot specify lifetime for each value. Though, you can always access
backend AnyEvent::InMemoryCache object:

    (tied %hash)->set(foo => 'bar', -1);

=head1 SEE ALSO

=over

=item L<AnyEvent>

=item L<Time::Duration::Parse>

=back

=head1 LICENSE

Copyright (C) Daisuke (yet another) Maki.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Daisuke (yet another) Maki E<lt>maki.daisuke@gmail.comE<gt>

=cut

