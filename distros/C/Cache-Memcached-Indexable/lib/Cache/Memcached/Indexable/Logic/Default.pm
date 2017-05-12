package Cache::Memcached::Indexable::Logic::Default;

use strict;
use warnings;
use base qw(Cache::Memcached::Indexable::Logic);

our $VERSION = '0.01';

sub all_keys {
    my $self = shift;
    map { sprintf('%02X', $_) } (0 .. 255);
}

sub find_branch_key {
    my($self, $key) = @_;
    if (defined $key && length $key) {
        $key = pack('C0A*', $key); # strip the UTF-8 flag
        return uc(unpack('H2', substr($key, 0, 1)));
    }
    else {
        return '00';
    }
}

1;

__END__

=head1 NAME

Cache::Memcached::Indexable::Logic::Default - The default logic for Cache::Memcached::Indexable

=head1 SYNOPSIS

 use Cache::Memcached::Indexable::Logic::Default;
 use Cache::Memcached::Indexable;
 
 my $logic = Cache::Memcached::Indexable::Logic::Default->new;
 
 my $memd = Cache::Memcached::Indexable->new({
     'servers' => [ "10.0.0.15:11211", "10.0.0.15:11212",
                    "10.0.0.17:11211", [ "10.0.0.17:11211", 3 ] ],
     'debug' => 0,
     'compress_threshold' => 10_000,
 });
 
 $memd->set_logic($logic);

or

 my $memd = Cache::Memcached::Indexable->new({
     'logic' => 'Cache::Memcached::Indexable::Logic::Default',
     'debug' => 0,
     'compress_threshold' => 10_000,
 });

=head1 DESCRIPTION

This module is a logic class for L<Cache::Memcache::Indexable>.
You don't need to specify this class for logic.
It will be use for logic by default.

This module uses 256 patterns of route key. It simply uses hex string
of top character of your specified key.

It may be place a disproportionate emphasis on the original key.

=head1 AUTHOR

Koichi Taniguchi E<lt>taniguchi@livedoor.jpE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Cache::Memcache::Indexable>, L<Cache::Memcached::Indexable::Logic>

=cut
