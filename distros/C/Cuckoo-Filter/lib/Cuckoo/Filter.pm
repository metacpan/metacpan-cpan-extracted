package Cuckoo::Filter;

use warnings;
use strict;

our $VERSION = "0.0.3";

use Digest;

sub new {
    my ($class, %params) = @_;
    my $self = {
        bucket_size => 2 ** 18,
        max_retry => 500,
        fingerprint_size => 3,
        %params,
        item_count => 0,
    };
    $self->{digest} //= Digest->new("SHA-1");
    # init fixed array
    $self->{buckets} = do {
        my @buckets = ();
        $#buckets = $self->{bucket_size};
        \@buckets
    };

    return bless $self, $class;
}

sub _fingerprint {
    my ($self, $item) = @_;
    my $digest = do {
        my $d= $self->{digest};
        $d->add($item);
        $d->digest;
    };

    return substr($digest, 0, $self->{fingerprint_size}-1);
}

# djb hash
sub _hash {
    my $str = shift;
    my @bytes = unpack 'C*', $str;
    my $h = 5381;
    for my $i (@bytes) {
        $h = (($h << 5) + $h) + $i;
    }
    $h;
}

sub lookup {
    my ($self, $item) = @_;
    my $fp = $self->_fingerprint($item);
    my $idx1 = _hash($item) % $self->{bucket_size};
    my $idx2 = ($idx1 ^ _hash($fp)) % $self->{bucket_size};

    return defined $self->{buckets}[$idx1] || $self->{buckets}[$idx2];
}

sub insert {
    my ($self, $item) = @_;
    return 0 if $self->lookup($item);
    my $fp = $self->_fingerprint($item);
    my $idx1 = _hash($item) % $self->{bucket_size};
    my $idx2 = ($idx1 ^ _hash($fp)) % $self->{bucket_size};
    for my $index ($idx1, $idx2) {
        if (! defined $self->{buckets}[$index]) {
            $self->{buckets}[$index] = $item;
            $self->{item_count}++;
            return 1;
        }
    }

    my $index = +($idx1, $idx2)[int(rand(2))];
    for (my $i = 0; $i < $self->{max_retry}; $i++) {
        $fp = do {
            my $f = $self->{buckets}[$index];
            $self->{buckets}[$index] = $fp;
            $f;
        };
        $index = ($idx1 ^ _hash($fp)) % $self->{bucket_size};

        if (! defined $self->{buckets}[$index]) {
            $self->{buckets}[$index] = $fp;
            $self->{item_count}++;
            return 1;
        }
    }

    return 0;
}

sub delete {
    my ($self, $item) = @_;
    my $fp = $self->_fingerprint($item);
    my $idx1 = _hash($item) % $self->{bucket_size};
    my $idx2 = ($idx1 ^ _hash($fp)) % $self->{bucket_size};
    for my $index ($idx1, $idx2) {
        if (defined $self->{buckets}[$index]) {
            delete $self->{buckets}[$index];
            $self->{item_count}--;
            return 1;
        }
    }
    return 0;
}

sub count {
    my $self = shift;
    return $self->{item_count};
}

1;
__END__

=head1 NAME

Cuckoo::Filter - Cuckoo Filter implementation in perl

=head1 SYNOPSIS

    use Cuckoo::Filter;

    my $filter = Cuckoo::Filter->new();
    $filter->insert(1);
    $filter->lookup(1);
    $filter->delete(1);


=head1 DESCRIPTION

    Cuckoo Filter implementation in Perl, Practically Better Than Bloom.
    For more detail, please refer to the original paperL<https://www.cs.cmu.edu/~dga/papers/cuckoo-conext2014.pdf>

=head1 METHODS

=head2 C<< $filter = Cuckoo::Filter->new() >>

Constructor.
Bellows are optional arguments.

=over 4

=item bucket_size

bucket size.

=item max_retry

insert returns false if insert fails max_retry times.

=item fingerprint_size

fingerprint size(Bytes)

=item digest

you can inject another hash function here. e.x. fnv-1. L<Digest::base|http://search.cpan.org/~gaas/Digest-1.17/Digest/base.pm> interface required.

=back

=head2 C<< my $bool = $filter->insert($item); >>

=head2 C<< my $bool = $filter->lookup($item); >>

=head2 C<< my $bool = $filter->delete($item); >>

=head2 C<< my $count = $filter->count(); >>

=head1 AUTHOR

Kenji Doi  C<< <kend@cpan.org> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2017, Kenji Doi C<< <kend@cpan.orgr >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
