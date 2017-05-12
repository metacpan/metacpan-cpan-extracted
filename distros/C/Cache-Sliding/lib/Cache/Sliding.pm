package Cache::Sliding;
use 5.010001;
use warnings;
use strict;
use utf8;
use Carp;

our $VERSION = 'v2.0.1';

use Scalar::Util qw( weaken );
use EV;


sub new {
    my ($class, $expire_after) = @_;
    my $self = {
        L1      => {},
        L2      => {},
        t       => undef,
    };
    weaken(my $this = $self);
    $self->{t} = EV::timer $expire_after, $expire_after, sub { if ($this) {
        $this->{L2} = $this->{L1};
        $this->{L1} = {};
    } };
    return bless $self, $class;
}

sub get {
    my ($self, $key) = @_;
    if (exists $self->{L1}{$key}) {
        return $self->{L1}{$key};
    }
    elsif (exists $self->{L2}{$key}) {
        return ($self->{L1}{$key} = delete $self->{L2}{$key});
    }
    return;
}

sub set {   ## no critic (ProhibitAmbiguousNames)
    my ($self, $key, $value) = @_;
    return ($self->{L1}{$key} = $value);
}

sub del {
    my ($self, $key) = @_;
    delete $self->{L2}{$key};
    delete $self->{L1}{$key};
    return;
}


1; # Magic true value required at end of module
__END__

=encoding utf8

=head1 NAME

Cache::Sliding - Cache using sliding time-based expiration strategy


=head1 VERSION

This document describes Cache::Sliding version v2.0.1


=head1 SYNOPSIS

    use Cache::Sliding;

    $cache = Cache::Sliding->new(10*60);

    $cache->set($key, $value);
    $value = $cache->get($key);
    $cache->del($key);


=head1 DESCRIPTION

Implement caching object using sliding time-based expiration strategy
(data in the cache is invalidated by specifying the amount of time the
item is allowed to be idle in the cache after last access time).

Use EV::timer, so this module only useful in EV-based applications,
because cache expiration will work only while you inside EV::loop.


=head1 INTERFACE 

=head2 new

    $cache = Cache::Sliding->new( $expire_after );

Create and return new cache object. Elements in this cache will expire
between $expire_after seconds and 2*$expire_after seconds.

=head2 set

    $cache->set( $key, $value );

Add new item into cache. Will replace existing item for that $key, if any.

=head2 get

    $value = $cache->get( $key );

Return value of cached item for $key. If there no cached item for that $key
return nothing.

For example, if you may keep undefined values in cache and still wanna be
able to check is item was found in cache:

 $cache->set( 'item 1', undef );
 $val = $cache->get( 'item 1' );  # $val is undef
 @val = $cache->get( 'item 1' );  # @val is (undef)
 $val = $cache->get( 'nosuch' );  # $val is undef
 @val = $cache->get( 'nosuch' );  # @val is ()

=head2 del

    $cache->del( $key );

Remove item for $key from cache, if any. Return nothing.


=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/powerman/perl-Cache-Sliding/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software. The code repository is available for
public review and contribution under the terms of the license.
Feel free to fork the repository and submit pull requests.

L<https://github.com/powerman/perl-Cache-Sliding>

    git clone https://github.com/powerman/perl-Cache-Sliding.git

=head2 Resources

=over

=item * MetaCPAN Search

L<https://metacpan.org/search?q=Cache-Sliding>

=item * CPAN Ratings

L<http://cpanratings.perl.org/dist/Cache-Sliding>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Cache-Sliding>

=item * CPAN Testers Matrix

L<http://matrix.cpantesters.org/?dist=Cache-Sliding>

=item * CPANTS: A CPAN Testing Service (Kwalitee)

L<http://cpants.cpanauthors.org/dist/Cache-Sliding>

=back


=head1 AUTHOR

Alex Efros E<lt>powerman@cpan.orgE<gt>


=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2009- by Alex Efros E<lt>powerman@cpan.orgE<gt>.

This is free software, licensed under:

  The MIT (X11) License


=cut
