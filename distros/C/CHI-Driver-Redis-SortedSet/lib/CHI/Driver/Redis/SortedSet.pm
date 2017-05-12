package CHI::Driver::Redis::SortedSet;

use Moo;
use URI::Escape qw(uri_escape uri_unescape);

extends 'CHI::Driver::Redis';

our $VERSION = '0.01';

sub get_keys {
    my ($self) = @_;

    my @keys = $self->redis->zrange($self->prefix . $self->namespace, 0, -1);

    my @unesckeys = ();

    foreach my $k (@keys) {
        # Getting an empty key here for some reason...
        next unless defined $k;
        push(@unesckeys, uri_unescape($k));
    }
    return @unesckeys;
}

sub remove {
    my ($self, $key) = @_;

    return unless defined($key);

    my $ns = $self->prefix . $self->namespace;

    my $skey = uri_escape($key);

    $self->redis->zrem($ns, $skey);
    $self->redis->del($ns . '||' . $skey);
}

sub store {
    my ($self, $key, $data, $expires_in) = @_;

    my $ns = $self->prefix . $self->namespace;

    my $skey = uri_escape($key);
    my $realkey = $ns . '||' . $skey;

    $self->redis->sadd($self->prefix . 'chinamespaces', $self->namespace);
    $self->redis->set($realkey, $data);

    if (defined($expires_in)) {
        $self->redis->expire($realkey, $expires_in);
        $self->redis->zadd($ns, time + $expires_in, $skey);
    } else {
        $self->redis->zadd($ns, '+inf', $skey);  # key will never expire
    }

    $self->redis->zremrangebyscore($ns, 0, time);  # cleanup expired keys
}

sub clear {
    my ($self) = @_;

    my $ns = $self->prefix . $self->namespace;
    my @keys = $self->redis->zrange($ns, 0, -1);

    foreach my $k (@keys) {
        $self->redis->zrem($ns, $k);
        $self->redis->del($ns . '||' . $k);
    }
}

no Moo;
1;
__END__

=encoding utf-8

=head1 NAME

CHI::Driver::Redis::SortedSet - Redis driver for CHI with proper expiration of namespace keys

=head1 SYNOPSIS

    use CHI;

    my $cache = CHI->new(
        driver    => 'Redis::SortedSet',
        namespace => 'products',
        server    => '127.0.0.1:6379',
        debug     => 0
    );

=head1 DESCRIPTION

Extends L<CHI::Driver::Redis> to address memory leak issues from an unbound
C<set> holding the namespace members. This module implements the fix as
suggested in a feature request by Pieter Noordhuis as outlined
L<here|https://github.com/antirez/redis/issues/135>.

The expiration mechanism is implemented as a lazy cleanup, transparently
invoked everytime C<store> is called via C<CHI::set()>.

Please note that this is B<not> backwards compatible with existing Redis
datasets that have already been populated with entries via the
L<CHI::Driver::Redis> module due to the underlying change in the data type
holding the list of all keys in the namespace as retrieved thru
C<CHI::get_keys()>.

=head1 FAQ

=head3 I'm starting fresh with a new Redis database. What should I do?

Nothing.

Congratulations! You're in the best position to use this module instead of
L<CHI::Driver::Redis> if memory usage can become an issue based on your setup
and use case.

=head3 I've been using L<CHI::Driver::Redis>. How do I migrate to this new module?

The L<FLUSHDB|http://redis.io/commands/FLUSHDB> command should first be
issued. Please note that this will drop all existing keys and cached data
and so is a destructive procedure.

=head3 Why not make the driver backwards compatible with L<CHI::Driver::Redis>?

Yes, that's very much possible. And should likewise not be too costly as
it will only have to involve a one-time transparently-invoked migration to
migrate all previously-defined namespace members from the original C<set>
to a C<sorted set>, with expiration values set from each key's
L<TTL|http://redis.io/commands/TTL>.

However, it would be prudent that the memory leak is an actual issue being
experienced by the developer before using this module. At this point, the
developer should first be aware of the subtle changes which will happen
under the hood.

As such, the author has made a judgment call to make this a conscious
decision on the developer's part.

=head3 Why not send a pull request and incorporate this into L<CHI::Driver::Redis>?

The author will first collaborate with the authors of L<CHI::Driver::Redis>
and if deemed acceptable, merge the modifications into the original code
base so we won't have to deal with the confusion of having multiple L<CHI>
drivers doing pretty much the same thing.

Otherwise, this module will continue to exist on a different namespace to
provide developers with this option.

=head1 BUGS

C<CHI::purge()> is B<not> implemented, just like L<CHI::Driver::Redis>.

=head1 AUTHOR

Arnold Tan Casis E<lt>atancasis@cpan.orgE<gt>

=head1 ACKNOWLEDGMENTS

This is based on the work by Cory G Watson E<lt>gphat at cpan.orgE<gt> and Ian
Burrell E<lt>iburrell@cpan.orgE<gt> so all attributions should go to them.

Likewise, the fix implemented in this module is inspired by the suggestion
of Pieter Noordhuis E<lt>pcnoordhuis@gmail.comE<gt>.

=head1 COPYRIGHT

Copyright 2016- Arnold Tan Casis

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<CHI::Driver::Redis>

=cut
