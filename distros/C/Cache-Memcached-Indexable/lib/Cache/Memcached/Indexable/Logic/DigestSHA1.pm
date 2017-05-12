package Cache::Memcached::Indexable::Logic::DigestSHA1;

use strict;
use warnings;
use Carp;
use Digest::SHA1 qw(sha1_hex);
use base qw(Cache::Memcached::Indexable::Logic);

our $VERSION = '0.02';

sub set_max_power {
    my($self, $power) = @_;
    unless (sprintf('%x', $power) =~ /^f+$/) {
        carp "max_power must be a 16's power minus 1 (like 0xFFFF)";
    }
    $self->{_max_power} = $power;
}

sub max_power {
    my $self = shift;
    unless (exists $self->{_max_power}) {
        $self->{_max_power} = 0xFF; # XXX default
    }
    return $self->{_max_power},
}

sub max_power_length {
    my $self = shift;
    unless ($self->{_max_power_length}) {
        $self->{_max_power_length} = length(sprintf('%x', $self->max_power));
    }
    return $self->{_max_power_length};
}

sub all_keys {
    my $self = shift;
    my $format = sprintf('%%0%dx', $self->max_power_length);
    map { sprintf($format, $_) } (0 .. $self->max_power);
}

sub find_branch_key {
    my($self, $key) = @_;
    return substr(sha1_hex($key), 0, $self->max_power_length);
}

1;

__END__

=head1 NAME

Cache::Memcached::Indexable::Logic::DigestSHA1 - a fine logic for Cache::Memcached::Indexable

=head1 SYNOPSIS

 use Cache::Memcached::Indexable::Logic::DigestSHA1;
 use Cache::Memcached::Indexable;
 
 my $logic = Cache::Memcached::Indexable::Logic::DigestSHA1->new;
 $logic->set_max_power(0xff);
 
 my $memd = Cache::Memcached::Indexable->new({
     'servers' => [ "10.0.0.15:11211", "10.0.0.15:11212",
                    "10.0.0.17:11211", [ "10.0.0.17:11211", 3 ] ],
     'debug' => 0,
     'compress_threshold' => 10_000,
 });
 
 $memd->set_logic($logic);

or

 my $memd = Cache::Memcache::Indexable->new({
     'logic' => 'Cache::Memcached::Indexable::Logic::DigestSHA1',
     'logic_args' => { set_max_power => 0xff },
     'servers' => [ "10.0.0.15:11211", "10.0.0.15:11212",
                    "10.0.0.17:11211", [ "10.0.0.17:11211", 3 ] ],
     'debug' => 0,
     'compress_threshold' => 10_000,
 });

=head1 DESCRIPTION

This module is a kind of logic class for L<Cache::Memcached::Indexable>.
It uses to get an original key through C<Digest::SHA1::sha1_hex()> function
with your key.

=head1 METHOD

=head2 $logic->set_max_power($power)

You can set how many patterns do you want to use for the original key.
The C<$power> must be a 16's power minus 1 (0xF, 0xFF, 0xFFF, 0xFFFF, 0xFFFFF ...).

Note that the C<$memd->keys()> will be taken too long time to return all your keys
if you set a huge number to this method.

=head1 AUTHOR

Koichi Taniguchi E<lt>taniguchi@livedoor.jpE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Cache::Memcache::Indexable>, L<Cache::Memcached::Indexable::Logic>

=cut
