package SSI;

use strict;
use warnings;

use base 'Apache2::Mogile::Dispatch';

use Cache::Memcached;

sub mogile_key {
    my ($r) = @_;
    return $r->uri;
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

# Instead of automatically reproxying the request to mogile, we can choose
# to request the file and print its contents thus enabling mod_include.
# In some cases we don't want to filter through mod_include. Those cases
# are images, javascript includes, css, etc. We use this function to indicate
# that we want those requests to immediately reproxy.
sub reproxy_request {
    my ($r, $config, $host_info) = @_;
    if ($r->uri =~ m!^/css!xm) { return 1; }
    if ($r->uri =~ m!^/images!xm) { return 1; }
    if ($r->uri =~ m!^/javascript!xm) { return 1; }
    if ($r->uri =~ m!^/js!xm) { return 1; }
    return 0;
}

1;
__END__

=pod

=head1 NAME

SSI - A dispatcher that enables SSI through mogile

=head1 DESCRIPTION

This example module shows how to use cookies to determine if mogile is to be
used or not. It takes advantage of the apache request object being passed to
make its deciscion.

In your http.conf file set the content filter and let this module take care
of the rest.

    SetOutputFilter INCLUDES
    <LocationMatch "^/">
        SetHandler modperl
        PerlHandler SSI
    </LocationMatch>

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
