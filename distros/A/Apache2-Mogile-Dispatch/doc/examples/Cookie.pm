package Cookie;

use strict;
use warnings;

use base 'Apache2::Mogile::Dispatch';

use Apache2::Cookie;
use Apache2::Cookie::Jar;

sub mogile_key {
    my ($r) = @_;
    return $r->uri;
}

sub get_direction {
    my ($r, $cf) = @_;
    my $j = Apache2::Cookie::Jar->new($r);
    my $cookie = $j->cookies('mogile');
    if (! $cookie) { return { 'mogile' => 0 }; }
    if ($cookie->value eq 'true') { return { 'mogile' => 1 }; }
    return { 'mogile' => 0 };
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

Cookie - A cookie based dispatcher

=head1 DESCRIPTION

This example module shows how to use cookies to determine if mogile is to be
used or not. It takes advantage of the apache request object being passed to
make its deciscion.

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
