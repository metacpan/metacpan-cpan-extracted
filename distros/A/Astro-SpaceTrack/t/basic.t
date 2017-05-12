package main;

use strict;
use warnings;

use Test::More 0.96;

sub i_can ($);

require_ok 'Astro::SpaceTrack'
    or BAIL_OUT q{Can't continue without loading Astro::SpaceTrack.};

isa_ok Astro::SpaceTrack->new(), 'Astro::SpaceTrack'
    or BAIL_OUT q{Can't continue without instantiating Astro::SpaceTrack.};

i_can 'new';
i_can 'amsat';
i_can 'attribute_names';
i_can 'banner';
i_can 'celestrak';
i_can 'content_source';
i_can 'content_type';
i_can 'file';
i_can 'get';
i_can 'help';
i_can 'iridium_status';
i_can 'login';
i_can 'logout';
i_can 'names';
i_can 'retrieve';
i_can 'search_date';
i_can 'search_id';
i_can 'search_name';
i_can 'set';
i_can 'shell';
i_can 'source';
i_can 'spaceflight';
i_can 'spacetrack';
i_can 'spacetrack_query_v2';

is_deeply scalar Astro::SpaceTrack->attribute_names(), [ qw{
    addendum
    banner
    cookie_expires
    cookie_name
    direct
    domain_space_track
    dump_headers
    fallback
    filter
    identity
    iridium_status_format
    max_range
    password
    pretty
    prompt
    scheme_space_track
    session_cookie
    space_track_version
    url_iridium_status_kelso
    url_iridium_status_mccants
    url_iridium_status_sladen
    username
    verbose
    verify_hostname
    webcmd
    with_name
    } ], 'Attribute list is correct';

done_testing;

sub i_can ($) {
    my ( $method ) = @_;
    @_ = ( Astro::SpaceTrack->can( $method ),
	"Astro::Spacetrack->can( '$method' )" );
    goto &ok;
}

1;

__END__

#! ex: set textwidth=72 :
