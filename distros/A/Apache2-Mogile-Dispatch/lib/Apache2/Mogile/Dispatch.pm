# $Id: $

package Apache2::Mogile::Dispatch;

use strict;
use warnings;

use English;

use APR::Table ();
use APR::SockAddr ();
use Apache2::RequestRec ();
use Apache2::RequestUtil ();
use Apache2::Connection ();
use Apache2::Filter ();
use Apache2::RequestRec ();
use Apache2::Module;
use Apache2::CmdParms ();
use Apache2::Directive ();
use Apache2::Log ();
use Apache2::URI ();
use Apache2::Const -compile => qw(DECLINED OK DONE NOT_FOUND);

use MogileFS;

our $VERSION = '0.2';

sub handler {
    my ($r) = @_;
    my $cf = get_config($r);
    my $host_info = get_direction($r, $cf);
    if ($host_info && $host_info->{'reproxy'})  {
        $r->err_headers_out->add('X-REPROXY-URL', $host_info->{'reproxy'} );
        return Apache2::Const::DONE;
    }
    if (exists $host_info->{'mogile'} && $host_info->{'mogile'} eq '0') {
        if ($cf->{'MogReproxyToken'}) {
            $r->err_headers_out->add('X-REPROXY-SERVICE' => $cf->{'MogReproxyToken'});
        } else {
	        my $good_path = get_working_path(@{ $cf->{'MogStaticServers'} || '' });
	        if (! $good_path) {
	            return Apache2::Const::NOT_FOUND;
	        }
            $r->err_headers_out->add('X-REPROXY-URL', $good_path );
        }
        return Apache2::Const::DONE;
    }
    if ($host_info && $host_info->{'mogile'}) {
        my $filekey = uri2key($r, $cf, $host_info);
        my $mogfs = get_mogile_object([ @{$cf->{'MogTrackers'}} ], $cf->{'MogDomain'});
        my @paths;
        eval {
            @paths = $mogfs->get_paths($filekey, 1);
        };
        if ($EVAL_ERROR) {
            return Apache2::Const::NOT_FOUND;
        }
        my $working_path = get_working_path(@paths);
        if (! $working_path) {
            return Apache2::Const::NOT_FOUND;
        }
        if (usessi($r, $cf, $host_info)) {
            $r->err_headers_out->add('X-REPROXY-URL', $working_path );
            return Apache2::Const::DONE;
        }
        my $ua = LWP::UserAgent->new;
        my $response = $ua->get($working_path);
        if ($response->is_success) {
            $r->print($response->content);
        }
        return Apache2::Const::DONE;
    }
    return Apache2::Const::DONE;
}

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

# XXX To be subclassed
sub mogile_key {
    my ($r) = @_;
    return $r->uri;
}

# XXX To be subclassed
sub get_direction {
    return ( 'mogile' => 1 );
}

# XXX To be subclassed
sub get_config {
    return {
        'MogTrackers' => [ 'localhost:11211'],
        'MogStaticServers' => ['localhost:80'],
        'MogDomain' => 'localhost',
        'MogReproxyToken' => 'legacy_web',
    };
}

# XXX To be subclassed
sub reproxy_request {
    return 1;
}

1;
__END__

=pod

=head1 NAME

Apache2::Mogile::Dispatch - An Apache2 MogileFS Dispatcher

=head1 SYNOPSIS

Quickly and easily dispatch requests to mogile storage nodes using perlbal.

Quickly and easily use MogileFS + Perlbal instead of Apache for static ( or
semi-static SSI ) file serving

=head1 DESCRIPTION

Apache2::Mogile::Dispatch is an apache 2.x mod_perl module that makes it easy
to dispatch incoming requests between mogile storage nodes and regular web
servers. Consider it like a fancy pure perl mod_rewrite replacement that can
intelligently reproxy requests.

This is ideal for websites that server a sizable amount of static content and
would like to transition to mogileFS.

The goal of this module is to be as small and simple as possible but flexible
enough for large websites to run efficiently and effectively. This module is
meant to up sub-classed and the default configuration will more than likely
NOT work. Please see the section on subclassing for more information. The test
suite also includes several example subclasses ranging from simple to complex.

=head1 CONFIGURATION

There are two sets of configuration that this module uses: Module and Request.

Module configuration includes the list of mogile trackers, mogile domain,
static servers, etc that tell the module how to operate.

Request configuration includes the per request (uri) options and rules which
dictate how it is handled.

Both sorts are directly affected and controlled through the sub-classed
module.

=head2 Module Configuration

=head3 MogTrackers

This module configuration module sets the mogile trackers to use. It is an
array ref.

   [ 'localhost:11211', 'localhost:11212', '192.168.199.3:11213' ]

=head3 MogReproxyToken

This configuration setting tells the dispatcher whether or not to reproxy the
request to perlbal using a reproxy service token ('X-REPROXY-SERVICE') or just
a reproxy url ('X-REPROXY-URL').

=head3 MogStaticServers

This configuration setting contains a list (array ref) of web servers to
reproxy requests to if mogile is not handling the request.

  [ 'localhost:80', '192.168.198:80', 'webservice1' ]

=head3 MogDomain

This configuration setting contains the mogile domain to use when querying
the trackers for a given key. This is passed directly to mogile object
creation.

=head2 Request Configuration

=head3 mogile

This is the meat of the request handling. If this is defined and set to '1'
then the request will be processed through mogile. If it is defined and set to
'0' then it will be processed through the static servers or reproxy token.

=head3 reproxy

The 'reproxy' config option is checked before the 'mogile' option. If it is
set and the value is a valid URL than the dispatcher will immediately set the
'X-REPROXY-URL' header field and return with Apache2::Const::DONE.

=head1 FUNCTIONS

=head2 get_mogile_object

=head2 get_working_path

=head2 handler

=head2 mogile_key

=head2 reproxy_request

=head2 get_config

=head2 get_direction

=head1 CAVEATS

If the neither 'mogile' nor 'reproxy' is set in the request config, the module
will return with Apache2::Const::DONE thus nothing will happen. Note this when
debugging your subclass.

When supplied with a list of mogile or static servers it will attempt to
make a HEAD request to determine if the server can serve the file or not.

=head1 AUTHOR

Nick Gerakines, C<< <nick at socklabs.com> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-apache2-mogile-dispatch at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Apache2-Mogile-Dispatch>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 CAVEATS

When supplied with a list of mogile or static servers it will attempt to
make a HEAD request to determine if the server can serve the file or not.

=head1 TODO

Add fallback support -- When severing files it should fallback to either
mogile or static when it can't find what it wants.

Add more tests to check if the mogile trackers are reachable.

Add more tests for mogile up/down situation

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

  perldoc Apache2::Mogile::Dispatch

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Apache2-Mogile-Dispatch>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Apache2-Mogile-Dispatch>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Apache2-Mogile-Dispatch>

=item * Search CPAN

L<http://search.cpan.org/dist/Apache2-Mogile-Dispatch>

=item * The socklabs-cpan project page

The project page: 
L<http://dev.socklabs.com/projects/cpan/>

The SVN repository:
L<http://dev.socklabs.com/svn/cpan/Apache2-Mogile-Dispatch/trunk/>

=item * MogileFS project page on Danga Interactive

L<http://www.danga.com/mogilefs/>

=back

=head1 ACKNOWLEDGEMENTS

Mark Smith requested this module and gave the first requirements. Should also
quickly thank everyone who worked on MogileFS, Perlbal and Memcache for making
a product worth using. Cheers.

=head1 COPYRIGHT & LICENSE

Copyright 2006 Nick Gerakines, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
