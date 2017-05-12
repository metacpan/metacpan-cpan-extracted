package main;

use 5.006002;

use strict;
use warnings;

use Astro::SpaceTrack;
use Test::More 0.88;	# Because of done_testing();
use HTML::TreeBuilder;

use lib qw{ inc };
use My::Module::Test qw{ spacetrack_skip_no_prompt };

spacetrack_skip_no_prompt();

{
    my $st = Astro::SpaceTrack->new();
    my $resp = $st->login();
    $resp->is_success()
	or do {
	fail 'Space Track login failed: ' . $resp->status_line();
	last;
    };

    my $ua = $st->_get_agent();
    $resp = $ua->get( $st->_make_space_track_base_url() );
    $resp->is_success()
	or do {
	fail 'Space Track page fetch failed: ' . $resp->status_line();
	last;
    };

    my $tree = HTML::TreeBuilder->new_from_content( $resp->content() );
    my $node = $tree->look_down( _tag => 'div', class => 'tab-pane', id =>
	'recent' );

    # We have to remove the links to the complete daily files, since
    # these change from day to day. If we can't find it, we probably get
    # an error anyway, so we can fix what went wrong.
    if (
	my $daily = $node->look_down(
	    _tag => 'div', class => 'span3 offset2' )
    ) {
	$daily->detach();
    }

    defined $node
	or do {
	fail 'Space Track catalog information could not be found';
	last;
    };

    my %data;
    $data{expect} = <<'EOD';
<div class="tab-pane" id="recent"><font face="pirulen" size="3">Bulk Download Alternative:</font><div class="well">
        <div class="row">
            <div class="span5"><font face="pirulen" size="3">Current Catalog Files</font> The following links show the most recent element set (&quot;elset&quot; or &quot;TLE&quot;) for every object in the specified group that has received an update within the past 30 days. &quot;Admin curated&quot; lists are maintained by space-track.org administrators. Update suggestions for lists are welcome: <a href="mailto:admin@space-track.org"> admin@space-track.org</a>.<br />
                <br />
            </div>
            <div class="span4 offset1"><font face="pirulen" size="3">Complete Data Files (Daily TLEs)</font> These links show every element set (&quot;elset&quot; or &quot;TLE&quot;) published on the indicated Julian date (GMT). Note that not every satellite may be represented on every day, while some satellites may have many elsets in a given day.<br />
                <br />
            </div>
        </div>
        <div class="row">
            <div class="span2"> Full Catalog <ul>
                    <li><a data-original-title="Query URL" href="https://www.space-track.org/basicspacedata/query/class/tle_latest/ORDINAL/1/EPOCH/%3Enow-30/orderby/NORAD_CAT_ID/format/tle" target="_blank"> Two Line</a><li><a data-original-title="Query URL" href="https://www.space-track.org/basicspacedata/query/class/tle_latest/ORDINAL/1/EPOCH/%3Enow-30/orderby/NORAD_CAT_ID/format/3le" target="_blank"> Three Line</a></ul> Geosynchronous* (GEO) <ul>
                    <li><a data-original-title="Query URL" href="https://www.space-track.org/basicspacedata/query/class/tle_latest/ORDINAL/1/EPOCH/%3Enow-30/MEAN_MOTION/0.99--1.01/ECCENTRICITY/%3C0.01/OBJECT_TYPE/payload/orderby/NORAD_CAT_ID/format/tle" target="_blank"> Two Line</a><li><a data-original-title="Query URL" href="https://www.space-track.org/basicspacedata/query/class/tle_latest/ORDINAL/1/EPOCH/%3Enow-30/MEAN_MOTION/0.99--1.01/ECCENTRICITY/%3C0.01/OBJECT_TYPE/payload/orderby/NORAD_CAT_ID/format/3le" target="_blank"> Three Line</a></ul> Medium Earth Orbit* (MEO) <ul>
                    <li><a data-original-title="Query URL" href="https://www.space-track.org/basicspacedata/query/class/tle_latest/ORDINAL/1/EPOCH/%3Enow-30/MEAN_MOTION/1.8--2.39/ECCENTRICITY/%3C0.25/OBJECT_TYPE/payload/orderby/NORAD_CAT_ID/format/tle" target="_blank"> Two Line</a><li><a data-original-title="Query URL" href="https://www.space-track.org/basicspacedata/query/class/tle_latest/ORDINAL/1/EPOCH/%3Enow-30/MEAN_MOTION/1.8--2.39/ECCENTRICITY/%3C0.25/OBJECT_TYPE/payload/orderby/NORAD_CAT_ID/format/3le" target="_blank"> Three Line</a></ul> Low Earth Orbit* (LEO) <ul>
                    <li><a data-original-title="Query URL" href="https://www.space-track.org/basicspacedata/query/class/tle_latest/ORDINAL/1/EPOCH/%3Enow-30/MEAN_MOTION/%3E11.25/ECCENTRICITY/%3C0.25/OBJECT_TYPE/payload/orderby/NORAD_CAT_ID/format/tle" target="_blank"> Two Line</a><li><a data-original-title="Query URL" href="https://www.space-track.org/basicspacedata/query/class/tle_latest/ORDINAL/1/EPOCH/%3Enow-30/MEAN_MOTION/%3E11.25/ECCENTRICITY/%3C0.25/OBJECT_TYPE/payload/orderby/NORAD_CAT_ID/format/3le" target="_blank"> Three Line</a></ul> Highly Elliptical Orbit* (HEO) <ul>
                    <li><a data-original-title="Query URL" href="https://www.space-track.org/basicspacedata/query/class/tle_latest/ORDINAL/1/EPOCH/%3Enow-30/ECCENTRICITY/%3E0.25/OBJECT_TYPE/payload/orderby/NORAD_CAT_ID/format/tle" target="_blank"> Two Line</a><li><a data-original-title="Query URL" href="https://www.space-track.org/basicspacedata/query/class/tle_latest/ORDINAL/1/EPOCH/%3Enow-30/ECCENTRICITY/%3E0.25/OBJECT_TYPE/payload/orderby/NORAD_CAT_ID/format/3le" target="_blank"> Three Line</a></ul> Navigation (admin curated) <ul>
                    <li><a data-original-title="Query URL" href="https://www.space-track.org/basicspacedata/query/class/tle_latest/ORDINAL/1/EPOCH/%3Enow-30/orderby/NORAD_CAT_ID/format/tle/favorites/Navigation" target="_blank"> Two Line</a><li><a data-original-title="Query URL" href="https://www.space-track.org/basicspacedata/query/class/tle_latest/ORDINAL/1/EPOCH/%3Enow-30/orderby/NORAD_CAT_ID/format/3le/favorites/Navigation" target="_blank"> Three Line</a></ul> Weather (admin curated) <ul>
                    <li><a data-original-title="Query URL" href="https://www.space-track.org/basicspacedata/query/class/tle_latest/ORDINAL/1/EPOCH/%3Enow-30/orderby/NORAD_CAT_ID/format/tle/favorites/Weather" target="_blank"> Two Line</a><li><a data-original-title="Query URL" href="https://www.space-track.org/basicspacedata/query/class/tle_latest/ORDINAL/1/EPOCH/%3Enow-30/orderby/NORAD_CAT_ID/format/3le/favorites/Weather" target="_blank"> Three Line</a></ul> Iridium <ul>
                    <li><a data-original-title="Query URL" href="https://www.space-track.org/basicspacedata/query/class/tle_latest/ORDINAL/1/EPOCH/%3Enow-30/OBJECT_TYPE/payload/orderby/NORAD_CAT_ID/format/tle/OBJECT_NAME/iridium~~/" target="_blank"> Two Line</a><li><a data-original-title="Query URL" href="https://www.space-track.org/basicspacedata/query/class/tle_latest/ORDINAL/1/EPOCH/%3Enow-30/OBJECT_TYPE/payload/orderby/NORAD_CAT_ID/format/3le/OBJECT_NAME/iridium~~/" target="_blank"> Three Line</a></ul> Orbcomm <ul>
                    <li><a data-original-title="Query URL" href="https://www.space-track.org/basicspacedata/query/class/tle_latest/ORDINAL/1/EPOCH/%3Enow-30/OBJECT_NAME/orbcomm~~,VESSELSAT~~/OBJECT_TYPE/payload/orderby/NORAD_CAT_ID/format/tle" target="_blank"> Two Line</a><li><a data-original-title="Query URL" href="https://www.space-track.org/basicspacedata/query/class/tle_latest/ORDINAL/1/EPOCH/%3Enow-30/OBJECT_NAME/orbcomm~~,VESSELSAT~~/OBJECT_TYPE/payload/orderby/NORAD_CAT_ID/format/3le" target="_blank"> Three Line</a></ul>
            </div>
            <div class="span2">  Globalstar <ul>
                    <li><a data-original-title="Query URL" href="https://www.space-track.org/basicspacedata/query/class/tle_latest/ORDINAL/1/EPOCH/%3Enow-30/OBJECT_TYPE/payload/orderby/NORAD_CAT_ID/format/tle/OBJECT_NAME/globalstar~~/" target="_blank"> Two Line</a><li><a data-original-title="Query URL" href="https://www.space-track.org/basicspacedata/query/class/tle_latest/ORDINAL/1/EPOCH/%3Enow-30/OBJECT_TYPE/payload/orderby/NORAD_CAT_ID/format/3le/OBJECT_NAME/globalstar~~/" target="_blank"> Three Line</a></ul> Intelsat <ul>
                    <li><a data-original-title="Query URL" href="https://www.space-track.org/basicspacedata/query/class/tle_latest/ORDINAL/1/EPOCH/%3Enow-30/OBJECT_TYPE/payload/orderby/NORAD_CAT_ID/format/tle/OBJECT_NAME/intelsat~~/" target="_blank"> Two Line</a><li><a data-original-title="Query URL" href="https://www.space-track.org/basicspacedata/query/class/tle_latest/ORDINAL/1/EPOCH/%3Enow-30/OBJECT_TYPE/payload/orderby/NORAD_CAT_ID/format/3le/OBJECT_NAME/intelsat~~/" target="_blank"> Three Line</a></ul> Inmarsat <ul>
                    <li><a data-original-title="Query URL" href="https://www.space-track.org/basicspacedata/query/class/tle_latest/ORDINAL/1/EPOCH/%3Enow-30/OBJECT_TYPE/payload/orderby/NORAD_CAT_ID/format/tle/OBJECT_NAME/inmarsat~~/" target="_blank"> Two Line</a><li><a data-original-title="Query URL" href="https://www.space-track.org/basicspacedata/query/class/tle_latest/ORDINAL/1/EPOCH/%3Enow-30/OBJECT_TYPE/payload/orderby/NORAD_CAT_ID/format/3le/OBJECT_NAME/inmarsat~~/" target="_blank"> Three Line</a></ul> Amateur (admin curated) <ul>
                    <li><a data-original-title="Query URL" href="https://www.space-track.org/basicspacedata/query/class/tle_latest/ORDINAL/1/EPOCH/%3Enow-30/orderby/NORAD_CAT_ID/format/tle/favorites/Amateur" target="_blank"> Two Line</a><li><a data-original-title="Query URL" href="https://www.space-track.org/basicspacedata/query/class/tle_latest/ORDINAL/1/EPOCH/%3Enow-30/orderby/NORAD_CAT_ID/format/3le/favorites/Amateur" target="_blank"> Three Line</a></ul> Visible (admin curated) <ul>
                    <li><a data-original-title="Query URL" href="https://www.space-track.org/basicspacedata/query/class/tle_latest/ORDINAL/1/EPOCH/%3Enow-30/orderby/NORAD_CAT_ID/format/tle/favorites/Visible" target="_blank"> Two Line</a><li><a data-original-title="Query URL" href="https://www.space-track.org/basicspacedata/query/class/tle_latest/ORDINAL/1/EPOCH/%3Enow-30/orderby/NORAD_CAT_ID/format/3le/favorites/Visible" target="_blank"> Three Line</a></ul> Special Interest (admin curated) <ul>
                    <li><a data-original-title="Query URL" href="https://www.space-track.org/basicspacedata/query/class/tle_latest/ORDINAL/1/EPOCH/%3Enow-30/orderby/NORAD_CAT_ID/format/tle/favorites/Special_interest" target="_blank"> Two Line</a><li><a data-original-title="Query URL" href="https://www.space-track.org/basicspacedata/query/class/tle_latest/ORDINAL/1/EPOCH/%3Enow-30/orderby/NORAD_CAT_ID/format/3le/favorites/Special_interest" target="_blank"> Three Line</a></ul> Bright Geosynchronous (admin curated) <ul>
                    <li><a data-original-title="Query URL" href="https://www.space-track.org/basicspacedata/query/class/tle_latest/ORDINAL/1/EPOCH/%3Enow-30/orderby/NORAD_CAT_ID/format/tle/favorites/brightgeo" target="_blank"> Two Line</a><li><a data-original-title="Query URL" href="https://www.space-track.org/basicspacedata/query/class/tle_latest/ORDINAL/1/EPOCH/%3Enow-30/orderby/NORAD_CAT_ID/format/3le/favorites/brightgeo" target="_blank"> Three Line</a></ul> Human Spaceflight (admin curated) <ul>
                    <li><a data-original-title="Query URL" href="https://www.space-track.org/basicspacedata/query/class/tle_latest/ORDINAL/1/EPOCH/%3Enow-30/orderby/NORAD_CAT_ID/format/tle/favorites/human_spaceflight" target="_blank"> Two Line</a><li><a data-original-title="Query URL" href="https://www.space-track.org/basicspacedata/query/class/tle_latest/ORDINAL/1/EPOCH/%3Enow-30/orderby/NORAD_CAT_ID/format/3le/favorites/human_spaceflight" target="_blank"> Three Line</a></ul>
            </div>
        </div> *GEO: 0.99 &lt;= Mean Motion &lt;= 1.01 and Eccentricity &lt; 0.01 <br /> MEO: 600 minutes &lt;= Period &lt;= 800 minutes &amp; Eccentricity &lt; 0.25 <br /> LEO: Mean Motion &gt; 11.25 &amp; Eccentricity &lt; 0.25 <br /> HEO: Eccentricity &gt; 0.25 </div>
</div>
EOD

    $data{got} = $node->as_HTML( undef, '    ' );
    $data{got} =~ s/ (?<! \n ) \z /\n/smx;

    ok $data{got} eq $data{expect}, 'Space Track catalog check'
	or do {
	my $fn = 'space_track_catalog';
	foreach my $key ( keys %data ) {
	    open my $fh, '>:encoding(utf-8)', "$fn.$key"
		or die "Failed to write $fn.$key: $!";
	    print { $fh } $data{$key};
	    close $fh;
	}
	diag <<"EOD"

All we're really testing for here is whether the catalogs portion of the
web page has changed.

Desired and actual data written to $fn.expect and
$fn.got respectively.
EOD
    };

}

done_testing;

1;

# ex: set textwidth=72 :
