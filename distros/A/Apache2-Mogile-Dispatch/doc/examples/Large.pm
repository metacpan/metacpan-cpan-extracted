package Large;

use strict;
use warnings;

use base 'Apache2::Mogile::Dispatch';

use Cache::Memcached;

sub memcache_key {
    my ($r) = @_;
    return $r->uri;
}

# Because our mogile farm handles multiple hosts, we prepend the canonical
# domain (set in the host_info) to the request uri to use as the mogile key.
sub mogile_key {
    my ($r, $config, $host_info) = @_;
    my $file = ($host_info->{'canonical_domain'} ? '/' . $host_info->{'canonical_domain'} : '') . $r->uri;
    if ($file !~ m#^/#) { $file = '/' . $file; }
    return $file;
}

# Take advantage of memcache to cache request configuration info when
# possible.
sub get_direction {
    my ($r, $cf) = @_;
    my $host_info;
    if (my $memd = Cache::Memcached->new({ 'servers' => [ '192.168.100.1:11211', '192.168.100.2:11211' ] }) ) {
        my $memkey = memcache_key($r, $cf);
        $host_info = $memd->get($memkey);
    }
    if (! $host_info) {
            $host_info = { 'mogile' => 1 }; # Replace this with something else
            $memd->set($memkey, $host_info);
        }
    }
    return $host_info;
}

sub get_config {
    return {
        'MogTrackers' => [ 'localhost:11211', 'localhost:11212'],
        'MogStaticServers' => ['localhost:80'],
        'MogDomain' => 'localhost',
    };
}

sub reproxy_request {
    return 1;
}

1;
__END__

=pod

=head1 NAME

Large - A dispatcher that uses memcache

=head1 DESCRIPTION

This example module shows how to cache some of the per-request config for
sites with heavy load.

=head1 AUTHOR

Nick Gerakines, C<< <nick at socklabs.com> >>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

  perldoc Apache2::Mogile::Dispatch

=head1 COPYRIGHT & LICENSE

Copyright 2006 Nick Gerakines, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
