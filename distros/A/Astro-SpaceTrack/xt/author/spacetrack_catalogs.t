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

    defined $node
	or do {
	fail 'Space Track catalog information could not be found';
	last;
    };

    # We have to remove the links to the complete daily files, since
    # these change from day to day. If we can't find it, we probably get
    # an error anyway, so we can fix what went wrong.
#    if (
#	my $daily = $node->look_down(
#	    _tag => 'div', class => 'span3 offset2' )
#    ) {
#	$daily->detach();
#    }
    foreach my $daily ( $node->look_down(
	    _tag => 'a', href => qr< \b PUBLISH_EPOCH \b >smx ) ) {
	$daily->detach();
    }

    my %data;
    $data{expect} = <<'EOD';
<div class="tab-pane" id="recent">
    <div class="panel panel-default panel-st-primary">
        <div class="panel-heading"> Bulk Download Alternative</div>
        <div class="panel-body">
            <div class="row">
                <div class="col-md-6">
                    <h2>Current Catalog Files</h2>  The following links show the most recent element set (&quot;elset&quot;) for every object in the specified group that has received an update within the past 30 days. Other options are available on the <a href="https://www.space-track.org/#favorites">Favorites page</a>. Use Favorites to get the most recent elsets for objects in a list. <br />
                    <br />
                    <div class="row">
                        <div class="col-md-6"> Full Catalog <ul>
                                <li><a data-original-title="Query URL" href="https://www.space-track.org/basicspacedata/query/class/gp/EPOCH/%3Enow-30/orderby/NORAD_CAT_ID,EPOCH/format/xml" target="_blank"> OMM (XML)</a><li><a data-original-title="Query URL" href="https://www.space-track.org/basicspacedata/query/class/gp/EPOCH/%3Enow-30/orderby/NORAD_CAT_ID,EPOCH/format/3le" target="_blank"> 3LE</a></ul> Geosynchronous* (GEO) <ul>
                                <li><a data-original-title="Query URL" href="https://www.space-track.org/basicspacedata/query/class/gp/EPOCH/%3Enow-30/MEAN_MOTION/0.99--1.01/ECCENTRICITY/%3C0.01/OBJECT_TYPE/payload/orderby/NORAD_CAT_ID,EPOCH/format/xml" target="_blank"> OMM (XML)</a><li><a data-original-title="Query URL" href="https://www.space-track.org/basicspacedata/query/class/gp/EPOCH/%3Enow-30/MEAN_MOTION/0.99--1.01/ECCENTRICITY/%3C0.01/OBJECT_TYPE/payload/orderby/NORAD_CAT_ID,EPOCH/format/3le" target="_blank"> 3LE</a></ul> Medium Earth Orbit* (MEO) <ul>
                                <li><a data-original-title="Query URL" href="https://www.space-track.org/basicspacedata/query/class/gp/EPOCH/%3Enow-30/MEAN_MOTION/1.8--2.39/ECCENTRICITY/%3C0.25/OBJECT_TYPE/payload/orderby/NORAD_CAT_ID,EPOCH/format/xml" target="_blank"> OMM (XML)</a><li><a data-original-title="Query URL" href="https://www.space-track.org/basicspacedata/query/class/gp/EPOCH/%3Enow-30/MEAN_MOTION/1.8--2.39/ECCENTRICITY/%3C0.25/OBJECT_TYPE/payload/orderby/NORAD_CAT_ID,EPOCH/format/3le" target="_blank"> 3LE</a></ul> Low Earth Orbit* (LEO) <ul>
                                <li><a data-original-title="Query URL" href="https://www.space-track.org/basicspacedata/query/class/gp/EPOCH/%3Enow-30/MEAN_MOTION/%3E11.25/ECCENTRICITY/%3C0.25/OBJECT_TYPE/payload/orderby/NORAD_CAT_ID,EPOCH/format/xml" target="_blank"> OMM (XML)</a><li><a data-original-title="Query URL" href="https://www.space-track.org/basicspacedata/query/class/gp/EPOCH/%3Enow-30/MEAN_MOTION/%3E11.25/ECCENTRICITY/%3C0.25/OBJECT_TYPE/payload/orderby/NORAD_CAT_ID,EPOCH/format/3le" target="_blank"> 3LE</a></ul> Highly Elliptical Orbit* (HEO) <ul>
                                <li><a data-original-title="Query URL" href="https://www.space-track.org/basicspacedata/query/class/gp/EPOCH/%3Enow-30/ECCENTRICITY/%3E0.25/OBJECT_TYPE/payload/orderby/NORAD_CAT_ID,EPOCH/format/xml" target="_blank"> OMM (XML)</a><li><a data-original-title="Query URL" href="https://www.space-track.org/basicspacedata/query/class/gp/EPOCH/%3Enow-30/ECCENTRICITY/%3E0.25/OBJECT_TYPE/payload/orderby/NORAD_CAT_ID,EPOCH/format/3le" target="_blank"> 3LE</a></ul>
                        </div>
                        <div class="col-md-6"> Globalstar <ul>
                                <li><a data-original-title="Query URL" href="https://www.space-track.org/basicspacedata/query/class/gp/EPOCH/%3Enow-30/OBJECT_TYPE/payload/orderby/NORAD_CAT_ID,EPOCH/format/xml/OBJECT_NAME/globalstar~~/" target="_blank"> OMM (XML)</a><li><a data-original-title="Query URL" href="https://www.space-track.org/basicspacedata/query/class/gp/EPOCH/%3Enow-30/OBJECT_TYPE/payload/orderby/NORAD_CAT_ID,EPOCH/format/3le/OBJECT_NAME/globalstar~~/" target="_blank"> 3LE</a></ul> Inmarsat <ul>
                                <li><a data-original-title="Query URL" href="https://www.space-track.org/basicspacedata/query/class/gp/EPOCH/%3Enow-30/OBJECT_TYPE/payload/orderby/NORAD_CAT_ID,EPOCH/format/xml/OBJECT_NAME/inmarsat~~/" target="_blank"> OMM (XML)</a><li><a data-original-title="Query URL" href="https://www.space-track.org/basicspacedata/query/class/gp/EPOCH/%3Enow-30/OBJECT_TYPE/payload/orderby/NORAD_CAT_ID,EPOCH/format/3le/OBJECT_NAME/inmarsat~~/" target="_blank"> 3LE</a></ul> Intelsat <ul>
                                <li><a data-original-title="Query URL" href="https://www.space-track.org/basicspacedata/query/class/gp/EPOCH/%3Enow-30/OBJECT_TYPE/payload/orderby/NORAD_CAT_ID,EPOCH/format/xml/OBJECT_NAME/intelsat~~/" target="_blank"> OMM (XML)</a><li><a data-original-title="Query URL" href="https://www.space-track.org/basicspacedata/query/class/gp/EPOCH/%3Enow-30/OBJECT_TYPE/payload/orderby/NORAD_CAT_ID,EPOCH/format/3le/OBJECT_NAME/intelsat~~/" target="_blank"> 3LE</a></ul> Iridium <ul>
                                <li><a data-original-title="Query URL" href="https://www.space-track.org/basicspacedata/query/class/gp/EPOCH/%3Enow-30/OBJECT_TYPE/payload/orderby/NORAD_CAT_ID,EPOCH/format/xml/OBJECT_NAME/iridium~~/" target="_blank"> OMM (XML)</a><li><a data-original-title="Query URL" href="https://www.space-track.org/basicspacedata/query/class/gp/EPOCH/%3Enow-30/OBJECT_TYPE/payload/orderby/NORAD_CAT_ID,EPOCH/format/3le/OBJECT_NAME/iridium~~/" target="_blank"> 3LE</a></ul> Orbcomm <ul>
                                <li><a data-original-title="Query URL" href="https://www.space-track.org/basicspacedata/query/class/gp/EPOCH/%3Enow-30/OBJECT_NAME/~~orbcomm,~~VESSELSAT/OBJECT_TYPE/payload/orderby/NORAD_CAT_ID,EPOCH/format/xml" target="_blank"> OMM (XML)</a><li><a data-original-title="Query URL" href="https://www.space-track.org/basicspacedata/query/class/gp/EPOCH/%3Enow-30/OBJECT_NAME/~~orbcomm,~~VESSELSAT/OBJECT_TYPE/payload/orderby/NORAD_CAT_ID,EPOCH/format/3le" target="_blank"> 3LE</a></ul>
                            <br />
                            <br />
                        </div>
                    </div>
                </div>
                <div class="col-md-6">
                    <h2>Complete Data Files (Daily ELSETs)</h2>
                    <p>These links show every element set (&quot;elset&quot;) published on the indicated Julian date (GMT). Note that not every satellite may be represented on every day, while some satellites may have many ELSETs in a given day.<ul class=" margin-top-10">
                        <li><a data-original-title="Query URL" href="https://www.space-track.org/basicspacedata/query/class/gp_history/CREATION_DATE/2026-01-17--2026-01-18/orderby/NORAD_CAT_ID,EPOCH/format/tle/emptyresult/show" target="_blank">2026 017</a><li><a data-original-title="Query URL" href="https://www.space-track.org/basicspacedata/query/class/gp_history/CREATION_DATE/2026-01-18--2026-01-19/orderby/NORAD_CAT_ID,EPOCH/format/tle/emptyresult/show" target="_blank">2026 018</a></ul>
                </div>
                <div class="col-md-6 margin-top-30">
                    <h2>Well-Tracked Analyst Objects</h2>
                    <p>Well-tracked analyst objects are on-orbit objects that are consistently tracked by the U.S. Space Surveillance Network that cannot be associated with a specific launch. These objects of unknown origin are not entered into the <a href="https://www.space-track.org/#/catalog">satellite catalog</a>, but are maintained using satellite numbers between 80000 and 89999. For more information, please see our <a href="https://www.space-track.org/documentation#/faq">FAQ</a>. The following link shows every element set (elset) published for current well-tracked analyst objects <i>within the last 30 days</i>. <p><b>Note: There will be no SATCAT entries for analyst objects.</b><ul class="margin-top-10">
                        <li><a href="https://www.space-track.org/basicspacedata/query/class/gp/EPOCH/&gt;now-30/NORAD_CAT_ID/80000--89999/orderby/NORAD_CAT_ID/format/tle/emptyresult/show" target="_blank">Analyst Satellite ELSETs (TLE)</a><li><a href="https://www.space-track.org/basicspacedata/query/class/gp/EPOCH/&gt;now-30/NORAD_CAT_ID/80000--89999/orderby/NORAD_CAT_ID/format/xml/emptyresult/show" target="_blank">Analyst Satellite ELSETs (XML)</a></ul>
                </div>
                <div class="col-md-6 margin-top-30">
                    <h2>Space Fence Analyst Object Element Sets</h2>
                    <p>Well-tracked analyst objects are now tracked by Space Fence radar but do not appear in the <a href="https://www.space-track.org/#/catalog">satellite catalog (SATCAT)</a>. They are maintained using satellite numbers between 270,000 and 339,999. While the <a href="https://www.space-track.org/documentation#tle-alpha5" target="_blank">Alpha-5</a> schema is a stop-gap measure for legacy TLE and 3LE formats, space-track.org encourages users to retrieve these as an Orbit Mean-Elements Message (OMM) in XML, JSON, HTML, or CSV format. <br />
                        <br /> For more information, please see our <a href="https://www.space-track.org/documentation#/faq">FAQ</a>. <br />
                        <br /> The following link shows every elset published for the newest Space Fence tracked analyst objects <i>within the last 30 days</i> in XML format. <ul>
                        <li><a href="https://www.space-track.org/basicspacedata/query/class/gp/EPOCH/&gt;now-30/NORAD_CAT_ID/270000--339999/orderby/NORAD_CAT_ID/format/xml/emptyresult/show" target="_blank">XML Formatted Space Fence Analyst Satellite Elsets</a></ul>
                </div>
            </div>
        </div>
    </div>
    <div class="well text-muted"> *GEO: 0.99 &lt;= Mean Motion &lt;= 1.01 and Eccentricity &lt; 0.01 <br /> *MEO: 600 minutes &lt;= Period &lt;= 800 minutes and Eccentricity &lt; 0.25 <br /> *LEO: Mean Motion &gt; 11.25 and Eccentricity &lt; 0.25 <br /> *HEO: Eccentricity &gt; 0.25 </div>
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
