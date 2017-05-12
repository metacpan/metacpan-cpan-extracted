package Cache::LRU::WithExpires;

use strict;
use warnings;
use 5.008_001;
our $VERSION = '0.03';

use parent 'Cache::LRU';
use Time::HiRes ();

use constant NO_EXPIRES => 0;

sub set {
    my ($self, $key, $value, $expires) = @_;
    $expires = $expires ? Time::HiRes::time() + $expires : NO_EXPIRES;
    $value   = [$value, $expires];
    $self->SUPER::set($key, $value);
}

sub get {
    my ($self, $key) = @_;
    my $value = $self->SUPER::get($key);
    return undef unless defined $value; ## no critic

    ($value, my $expires) = @$value;
    return $value if $expires == NO_EXPIRES;
    if ($expires - Time::HiRes::time() < 0) {
        $self->remove($key);
        return undef; ## no critic
    }

    return $value;
}

1;
__END__

=encoding utf-8

=for stopwords

=head1 NAME

Cache::LRU::WithExpires - can set an expiration for the Cache::LRU

=head1 SYNOPSIS

  use Cache::LRU::WithExpires;

  my $cache = Cache::LRU::WithExpires->new;
  $cache->set('foo', 'bar', 1);
  sleep 2;
  $cache->get('foo'); # undef

=head1 DESCRIPTION

Cache::LRU::WithExpires is a can set an expiration for the L<< Cache::LRU >>.

=head1 AUTHOR

xaicron E<lt>xaicron {at} cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2012 - xaicron

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<< Cache::LRU >>

=cut
