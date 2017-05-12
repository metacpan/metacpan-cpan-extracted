package Apache::UploadMeter::Resources::CSS;

# Static resources (CSS) for the UploadMeter widget

use strict;
use warnings;
use Apache2::RequestRec ();
use Apache2::RequestIO ();
use Apache2::Response ();
use Apache2::Const -compile=>qw(:common);

sub json_css {
    my $r = shift;
    $r->content_type("text/css");
    $r->set_etag();
    return Apache2::Const::OK if $r->header_only();
    my $output=<<'CSS-END';
.uploadmeter {
    width: 200px;
    height: 1em;
    margin: 2px 0 2px 0;
    display: block;
    border: 1px blue solid;
}
.metercontent {
    text-align:center;
    display:inline;
}
.meterunderlay {
    background-color: blue;
    opacity: 0.5;
    filter: alpha(opacity=50);
    display:inline;
}
CSS-END
    $r->print($output);
    return Apache2::Const::OK;
}

1;