package Apache::UploadMeter::Resources::HTML;

# Static resources (CSS) for the UploadMeter widget

use strict;
use warnings;
use Apache2::RequestRec ();
use Apache2::RequestIO ();
use Apache2::Response ();
use Apache2::Const -compile=>qw(:common);

sub json_popup {
    my $r = shift;
    $r->content_type("text/html");
    $r->set_etag();
    return Apache2::Const::OK if $r->header_only();
    my $output=<<"EOF";
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
<head>
<script type="text/javascript" src="js/prototype.js"></script>
<script type="text/javascript" src="js/scriptaculous.js"></script>
<script type="text/javascript" src="js/behaviour.js"></script>
<script type="text/javascript" src="js/aum.js"></script>
<link rel="StyleSheet" type="text/css" href="css/aum.css"/>    
<script type="text/javascript">
// <![CDATA[
var um;

UploadMeter.Responders.register({
    onCreate: function (meter) {
        Element.update(meter.desc, "Please wait...");
    }
});
    

var rules={
    '.uploadmeter':function(el) {
        um = new UploadMeter(el, meter_id, meter_url, {
            onUpdate: function (status, last) {
                Element.update('file', "Now uploading: " + status.filename);
                Element.update('bytes', status.seen + "/" + status.total + "  bytes transfered (" + Util.formatDec(status.currentrate) + " bytes/sec)");
                Element.update('time', Util.formatTime(status.elapsed) + " elapsed (" + Util.formatTime(status.remaining) + " remaining)"); 
            },
            onFinished: function(status, last) {
                Element.show('closeme');
            }
        });
        um.start();
    }
};
Behaviour.register(rules);

// ]]>
</script>
<title>Upload progress...</title>
</head>
<body>
<h1>Upload Status</h1>
<div class="uploadmeter"></div>
<div id="file" name="file"></div>
<div id="bytes" name="bytes"></div>
<div id="time" name="time"></div>
<input type="button" style="display: none" id="closeme" name="closeme" onclick="window.close()" value="Close window" />
</body>
</html>

EOF
    $r->print($output);
    return Apache2::Const::OK;
}

1;