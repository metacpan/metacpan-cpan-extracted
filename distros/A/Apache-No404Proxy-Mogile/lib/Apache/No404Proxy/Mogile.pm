package Apache::No404Proxy::Mogile;

use strict;
use warnings;

use vars qw($VERSION);

$VERSION = '0.1';

use base 'Apache::No404Proxy';

use MogileFS;
use LWP::UserAgent;

sub get_mogile_object {
    my ($hosts, $domain) = @_;
    my $mog = MogileFS->new(
        hosts => $hosts,
        domain => $domain,
    );
    return $mog;
}

sub get_working_path {
    my (@uris) = @_;
    my $ua = LWP::UserAgent->new;
    for my $uri (@uris) {
        my $response = $ua->head($uri);
        if ($response->is_success) { return $uri; }
    }
    return 0;
}

sub fetch {
    my($class, $r) = @_;
    my $mog_tracker = $r->dir_config('MogileTracker') or die 'You need to set a Mogile tracker to use this module';
    my $mog_domain = $r->dir_config('MogileDomain') or die 'You need to set a Mogile domain to use this module';
    my $mogfs = get_mogile_object([ $mog_tracker ], $mog_domain);
    my @paths;
    eval { @paths = $mogfs->get_paths($r->uri, 1); };
    if (my $working_path = get_working_path(@paths)) {
        my $ua = LWP::UserAgent->new;
        if (my $response = $ua->get($working_path)) {
            if ($response->is_success){
                return $response->content;
            }
        }
    }
    return undef;
}

1;
__END__

=head1 NAME

Apache::No404Proxy::Mogile - Implementation of Apache::No404Proxy

=head1 SYNOPSIS

    # in httpd.conf
    PerlTransHandler Apache::No404Proxy::Mogile
    PerlSetVar MogileTracker 192.168.100.1:4100
    PerlSetVar MogileDomain webservice_name

=head1 EXPORT

Apache::No404Proxy::Mogile is one of the implementations of
Apache::No404Proxy. This module uses MogileFS and LWP::UserAgent to fetch
content from mogile.

=head1 AUTHOR

Nick Gerakines, C<< <nick at gerakines.net> >>

=head1 SEE ALSO

L<Apache::No404Proxy>, L<Apache::No404Proxy::Google>, L<MogileFS>

=head1 COPYRIGHT & LICENSE

Copyright 2006 Nick Gerakines, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
