package Apache::UploadMeter;

use strict;
use warnings;
use vars qw($VERSION @ISA);
use mod_perl2 ();
use Apache2::Const -compile=>qw(:common :context HTTP_BAD_REQUEST OR_ALL EXEC_ON_READ RAW_ARGS);
use Apache2::RequestRec ();
use Apache2::Log ();
use Apache2::RequestUtil ();
use Apache2::RequestIO ();
use Apache2::Response ();
use Apache2::Filter ();
use Apache2::Module ();
use Apache2::Directive ();
use Apache2::CmdParms ();
use Apache2::ServerRec ();
use Apache2::ServerUtil ();
use Apache2::Connection ();
use Apache2::Util ();
use APR::Const     -compile=>qw(:common);
use APR::URI ();
use APR::Pool ();
use APR::Brigade ();
use APR::Bucket ();
use APR::BucketType ();
use APR::BucketAlloc ();

use Apache2::Request ();
use APR::Request ();
use Digest::SHA1 ();
use Cache::FileCache ();
use Number::Format ();
use Date::Format ();
use HTML::Parser ();

BEGIN {
    $VERSION=0.99_15;
}

### Version History
# 0.10 : Oct  28, 2001 - Restarted when file got wiped :-(
# 0.11 : Nov  12, 2001 - Added new SSI to replace JS handler and increase unique-id reliability
# 0.12 : Nov  17, 2001 - Switched output to XML
# 0.14 : Dec  11, 2001 - Added configuration code
# 0.15 : Dec  12, 2001 - Improved configuration code to auto-detect namespace (for possible future subclassing)
# 0.15a: Dec  30, 2001 - Recovered version 0.15 (Thanks - you know who you are if you made it possible) and moved namespace to sourceforge.
# 0.16a: Jan  08, 2002 -  Added basic JIT handlers to configuration
# 0.17 : Jan  13, 2002 - Cleaned up some more code and documentation - seems beta-able
# 0.21 : Feb   3, 2002 - Prebundled "basic" skin on sourceforge.  Migrate from DTD to schema.  Time/Date formatting currently server-side.
# 0.22 : Feb   3, 2002 - Fixed typo in URI for XSLT
# 0.99_03 : Jan  22, 2007 - Upgraded for mod_perl2; we'll have a stable 1.00 release with a few more fixes here
# 0.99_05 : Jan  23, 2007 - Finished outstanding issues using XML-based meter.
# 0.99_12 : Jan  23, 2007 - Internalized XML resources.  This is 1.00RC1
# 0.99_13 : Feb  11, 2007 - Initial JSON support + initial UploadMeter object in JavaScript
# 0.99_14 : Feb  15, 2007 - Fixed config issues, added lots of docs.
# 0.99_15 : Feb  21, 2007 - Fixed some MSIE-specific JavaScript issues, fixed up doc formatting. 

### Globals
my %cache_options=('default_expires_in'=>900,'auto_purge_interval'=>60,'namespace'=>'apache_umeter','auto_purge_on_get'=>1); #If the hooks don't get called in 15 minute, assume it's done
my $MaxTime="+900";
my $TIMEOUT=15;

### Handlers
sub hook_handler {
    my $r = shift;
    my $hook_data = shift; # joes says libapreq2 should use perl closures for
                           # implementing $hook_data - who am i to argue?
    ### Upload hook handler
    return sub {
	my ($upload, $new_data)=@_;
	my $len = length($new_data);
        my $hook_cache=new Cache::FileCache(\%cache_options);
        unless ($hook_cache) {
	    $r->log_reason("[Apache::UploadMeter] Could not instantiate FileCache.", __FILE__.__LINE__);
	    return Apache2::Const::DECLINED; 
	}
	my $oldlen=$hook_cache->get($hook_data."len") || 0;
	$len=$len+$oldlen;
	if ($oldlen==0)
	{
	    $r->log->notice("[Apache::UploadMeter] Starting upload $hook_data");
	    $hook_cache->set($hook_data."starttime",time());
	}
        unless ($hook_cache->get($hook_data."name") eq $upload->upload_filename) {
            my $name = $upload->upload_filename;
            $r->log->debug("[Apache::UploadMeter] Updating cache: $hook_data NAME --> $name");
            $hook_cache->set($hook_data."name",$name);
        }
	$r->log->debug("[Apache::UploadMeter] Updating cache: $hook_data LEN --> $len");
        $hook_cache->set($hook_data."len",$len);
        
        if ($r->pnotes("finished_upload")) {
            # Our filter deteced EOS.  Update finished, size == len
            $hook_cache->set($hook_data."size",$len);
        }
    };
}

### Upload meter generator - Master process
sub u_handler
{
    my $r=shift;
    # Read request
    my $req = APR::Request::Apache2->handle($r);
    my $u_id = $req->args('meter_id') || undef;
    return Apache2::Const::HTTP_BAD_REQUEST unless defined($u_id);
    $r->pnotes("u_id" => $u_id);
    # Initialize cache
    my $hook_cache=new Cache::FileCache(\%cache_options);
    unless ($hook_cache) {
	$r->log_reason("[Apache::UploadMeter] Could not instantiate FileCache.", __FILE__.__LINE__);
        return Apache2::Const::SERVER_ERROR; 
    }
    # Initialize apreq
    $req->upload_hook(hook_handler($r, $u_id));
    my $rsize=$r->headers_in->{"Content-Length"};
    $hook_cache->set($u_id."size",$rsize);
    $r->log->notice("[Apache::UploadMeter] Initialized cache for $u_id");
    return Apache2::Const::DECLINED;
}

### Upload meter generator - Slave process
sub um_handler
{
    my $r=shift;
    $r->no_cache(1);
    my $req = APR::Request::Apache2->handle($r);
    my $hook_id=$req->param('meter_id') || undef;
    my $initial_request=!($req->param('returned') || 0);
    return Apache2::Const::HTTP_BAD_REQUEST unless defined($hook_id);
    my $hook_cache=new Cache::FileCache(\%cache_options);
    unless ($hook_cache) {
	$r->log_reason("[Apache::UploadMeter] Could not instantiate FileCache.", __FILE__.__LINE__);
        return Apache2::Const::DECLINED;
    }
    my $finished = $hook_cache->get($hook_id."finished") || 0;
    my $len=$hook_cache->get($hook_id."len") || undef;
    if (!(defined($len))) {
	my $problem=1;
	if ($initial_request) {
	    my $count=0;
	    my $i;
	    my $c=$r->connection;
	    for ($i=0;$i<$TIMEOUT;$i++)
	    {
		$len=$hook_cache->get($hook_id."len") || undef;
		if (defined($len)) {
		    $problem=0;
		    last;
		}
		$r->log->info("[Apache::UploadMeter] Waiting for upload cache $hook_id to initialize ($i / $TIMEOUT)...");
		sleep 1;
		last if $c->aborted;
	    }
	}
	if ($problem) {
	    $r->custom_response(Apache2::Const::NOT_FOUND, "This upload meter is either invalid, or has expired.");
            return Apache2::Const::NOT_FOUND;
	}
    }
    my $size=$hook_cache->get($hook_id."size") || "Unknown";
    my $fname=$hook_cache->get($hook_id."name") || "Unknown";
    
    # Get response format.  Favor legacy XML here
    # Reasoning: XML is more portable; that's one of the reasons we support it
    # Although I expect 95% of users to use the JSON response, those same 95%
    # of the users are going to be using the bundled JS code, or forking from
    # it, meaning they already have what they need.
    # The other 5% are writing from scratch; hopefully embedding into some non-
    # browser based application.  They most likely want XML anyway, and its
    # their life that I want to make easier :-)
    my $format = $req->param("format") || "XML";

    my $currenttime = time();
    my $starttime=$hook_cache->get($hook_id."starttime") || $currenttime;
  
    # JSON response
    if ($format=~/^json$/i) {
        # Hardcode object for now.  No need to require YAML or YAML::Syck as prereq
        my $json=sprintf('{"meter_id":"%s","filename":"%s","finished":%d,"status":{"timestamp":%d,"start":%d,"received":%d,"total":%d}}',
                         $hook_id, $fname, $finished, $currenttime, $starttime, $len, $size);
        $r->content_type("application/json");
        $r->set_content_length(length($json));
        $r->print($json) unless $r->header_only;
        return Apache2::Const::OK;
    }
    # XML response (legacy)

    # This is better done in the XSL, I think.  I want to minimize Apache's work here and leave the browser to calculate the stuff.  What I may eventually do is create a second XSL stylesheet which translates the "minimal" formatting into this formatting.  I'm not going to change this first, but it's on my list of things to do - Issac
    # Calculate total rate and current rate
    my $lastupdatetime = $hook_cache->get($hook_id."lastupdatetime");
    my $lastupdatelen = $hook_cache->get($hook_id."lastupdatelen");
    my $currentrate = int (($len - $lastupdatelen) / ($currenttime - $lastupdatetime)) if ($currenttime != $lastupdatetime);
    my $rate = int ($len / ($currenttime - $starttime)) if ($currenttime != $starttime);
    $hook_cache->set($hook_id."lastupdatetime", $currenttime);
    $hook_cache->set($hook_id."lastupdatelen", $len);
    
    # Calculate elapsed and remaining time
    my $etime = $currenttime - $starttime;
    my $rtime = ($finished) ? 0 : int ($etime / $len * $size) - $etime;

    # Format values for easy display
    my $fsize = Number::Format::format_bytes($size, 2);
    my $flen = Number::Format::format_bytes($len, 2);
    my $fetime = Date::Format::time2str('%H:%M:%S', $etime, 'GMT');
    my $frtime = Date::Format::time2str('%H:%M:%S', $rtime, 'GMT');
    my $fcurrentrate = Number::Format::format_bytes($currentrate, 2).'/s';
    my $frate = Number::Format::format_bytes($rate, 2).'/s';

    # build the Refresh url
    my $args=$r->args;
    if ($initial_request) { $args=$args.(defined($args)?"&":"")."returned=1";}
    if ($finished) {
    	# Cleanup the cache since we are finished
# Not needed.  The hook automatically dumps values every 15 minutes for this reason.  - Issac.  But a purge is probably needed somewhere else for a global scale

        $hook_cache->remove($hook_id."finished");
        $hook_cache->remove($hook_id."len");
        $hook_cache->remove($hook_id."name");
        $hook_cache->remove($hook_id."size");
        $hook_cache->remove($hook_id."starttime");
        $hook_cache->remove($hook_id."lastupdaterate");
        $hook_cache->remove($hook_id."lastupdatelen");
	$hook_cache->clear;
	$hook_cache->purge; #best I can do for now...
    } else {
    	# Set a refresh header so the meter gets updated
	my $uri = APR::URI->parse($r->pool, $r->uri);
	$uri->scheme($ENV{HTTPS}?"https":"http");
	$uri->port($r->server->port ? $r->server->port : APR::URI::port_of_scheme($uri->scheme));
	$uri->path($r->uri);
	$uri->hostname($r->server->server_hostname);
	$uri->query($args);
        $r->headers_out->add("Refresh"=>"5;url=".$uri->unparse());
    }
    $r->content_type('text/xml');
    return Apache2::Const::OK if $r->header_only;
    my $config = $r->pnotes("Apache::UploadMeter::Config");
    my $meter = $config->("UploadMeter") || $r->uri;
    my $xsl="$meter/styles/xml/aum.xsl";
    my $xsd="$meter/styles/xml/aum.xsl";
    my $out= <<EOF;
<?xml version="1.0" encoding="UTF-8"?>
<?xml-stylesheet type="text/xsl" href="$xsl"?>
<APACHE_UPLOADMETER METER_ID="$hook_id" FILE="$fname" FINISHED="$finished" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="$xsd">
    <RECEIVED VALUE="$len">$flen</RECEIVED>
    <TOTAL VALUE="$size">$fsize</TOTAL>
    <ELAPSEDTIME VALUE="$etime">$fetime</ELAPSEDTIME>
    <REMAININGTIME VALUE="$rtime">$frtime</REMAININGTIME>
    <RATE VALUE="$rate">$frate</RATE>
    <CURRENTRATE VALUE="$currentrate">$fcurrentrate</CURRENTRATE>
</APACHE_UPLOADMETER>
EOF

    $r->print($out);
    return Apache2::Const::OK;
}

# Form fixup
sub uf_handler
{
    my $r=shift;
    $r->no_cache(1); # CRITICAL!  No caching allowed!
    $r->set_last_modified(time());
    $r->err_headers_out->add("Expires" => Apache2::Util::ht_time($r->pool));
    my $digest=Digest::SHA1::sha1_hex(time,(defined $r->subprocess_env('HTTP_HOST') ? $r->subprocess_env('HTTP_HOST') : 0),(defined $r->subprocess_env('HTTP_X_FORWARDED_FOR') ?$r->subprocess_env('HTTP_X_FORWARDED_FOR') : 0 ));
    $r->pnotes("u_id"=>$digest);
    return Apache2::Const::OK;
}

### Support handlers (for debugging)

# Simple response handler for displaying upload information
sub r_handler
{
    my $r=shift;
    my $req = APR::Request::Apache2->handle($r);
    $r->no_cache(1);
    my $uploads=$req->upload;
    $r->content_type('text/plain');
    return Apache2::Const::OK if $r->header_only;
    $r->print("Results:\n");
    while (my ($field, $upload) = each %$uploads) {
	$r->print("Parsed upload field $field:\n\tFilename: ".$upload->upload_filename());
	$r->print("\n\tSize: ".$upload->upload_size()."\n\n");
    }
    $r->print("Done\n");
    return Apache2::Const::OK;
}

### Output filters
sub f_xml_uploadform {
    my ($f, $bb) = @_;
    my $bb_ctx = APR::Brigade->new($f->c->pool, $f->c->bucket_alloc);
    unless ($f->ctx) {
        my $config = $f->r->pnotes("Apache::UploadMeter::Config");
        my $handler = $config->{"UploadHandler"} || undef;
        my $meter = $config->{"UploadMeter"} || undef;
        my $aum_id = $config->{"MeterName"} || undef;
        
        if (!(defined($handler) && defined($aum_id) && defined($meter))) {
              #&& $srv_cfg->{UploadMeter}->{aum_id}->{UploadForm} eq $uri)) {
            $f->r->log_error("[Apache::UploadMeter] No configuration data found for this UploadMeter");
            $f->remove;
            return Apache2::Const::DECLINED;
        }
	my $u_id=$f->r->pnotes('u_id') || undef;
	if (!(defined($u_id))) {
	    ### FIX THE ERROR
	    $f->r->log_error("[Apache::UploadMeter] No u_id in pnotes table. Make sure you ran configure()");
	    $f->remove; # We can't do anything useful anymore
            return Apache2::Const::DECLINED;
	}
        $f->r->log->debug("[Apache::UploadMeter] Initialized XML $aum_id with instance $u_id");
	my $output=<<"EOF";
<script type="text/javascript">
// <![CDATA[
function openUploadMeter()
{
    uploadWindow=window.open(\"${meter}?meter_id=${u_id}\",\"_new\",\"toolbar=no,location=no,directories=no,status=yes,menubar=no,scrollbars=no,resizeable=no,width=450,height=240\");
}
// ]]>
</script>
<noscript>You must use a JavaScript-enabled browser to use this page properly</noscript>
<form action=\"${handler}?hook_id=${u_id}\" method=\"post\" enctype=\"multipart/form-data\" onSubmit=\"openUploadMeter()\">
EOF

	$f->ctx({leftover => undef, output => $output});
    }
  
    while (!$bb->is_empty) {
        my $b = $bb->first;
        $b->remove;
        
        if ($b->is_eos) {            
            if (defined(${$f->ctx}{leftover})) {
                $bb_ctx->insert_tail(APR::Bucket->new($bb_ctx->bucket_alloc, ${$f->ctx}{leftover}));
            }
            $bb_ctx->insert_tail($b);
            last;
        } elsif ($b->read(my $buf)) {
            my $outbuf = "";
            # We need an output buffer, since we can't copy string data going into buckets
            
            $buf = ${$f->ctx}{leftover}.$buf if defined(${$f->ctx}{leftover});
            while ($buf=~/^(.*?)(<.*?>)(.*)/ms) {
                my ($pre,$tag);
                ($pre,$tag,$buf) = ($1,$2,$3);
                $outbuf.=$pre;
                if ($tag=~/\<\!--\s*?#uploadform\s*?--\>/i) {
                    $tag = ${$f->ctx}{output};
                }                
                $outbuf.=$tag;
            }
            $bb_ctx->insert_tail(APR::Bucket->new($bb_ctx->bucket_alloc, $outbuf));

            ${$f->ctx}{leftover} = $buf || undef;
        } else {
            $bb_ctx->insert_tail($b);
        }
    }
    
    my $rv = $f->next->pass_brigade($bb_ctx);
    return $rv unless $rv == APR::Const::SUCCESS;
    return Apache2::Const::OK;
}

sub f_json_uploadform {
    my ($f, $bb) = @_;
    my $bb_ctx = APR::Brigade->new($f->c->pool, $f->c->bucket_alloc);
    unless ($f->ctx) {
        my $config = $f->r->pnotes("Apache::UploadMeter::Config");
        my $handler = $config->{"UploadHandler"} || undef;
        my $meter = $config->{"UploadMeter"} || undef;
        my $aum_id = $config->{"MeterName"} || undef;
        
        if (!(defined($handler) && defined($aum_id) && defined($meter))) {
              #&& $srv_cfg->{UploadMeter}->{aum_id}->{UploadForm} eq $uri)) {
            $f->r->log_error("[Apache::UploadMeter] No configuration data found for this UploadMeter");
            $f->remove;
            return Apache2::Const::DECLINED;
        }
	my $u_id=$f->r->pnotes('u_id') || undef;
	if (!(defined($u_id))) {
	    ### FIX THE ERROR
	    $f->r->log_error("[Apache::UploadMeter] No u_id in pnotes table. Make sure you ran configure()");
	    $f->remove; # We can't do anything useful anymore
            return Apache2::Const::DECLINED;
	}
        $f->r->log->debug("[Apache::UploadMeter] Initialized JSON $aum_id with instance $u_id");
	my $header = "";
	$header.=<<"END-INC" unless defined($config->{'MeterOptions'}{'JSON-LITE'});
<script type="text/javascript" src="$meter/styles/js/prototype.js"></script>
<script type="text/javascript" src="$meter/styles/js/behaviour.js"></script>
<script type="text/javascript" src="$meter/styles/js/scriptaculous.js"></script>
END-INC
	
	$header.=<<"END-HEADER";
<link rel="StyleSheet" type="text/css" href="$meter/styles/css/aum.css"/>
<script type="text/javascript">
// <![CDATA[
var meter_id = "$u_id";
var meter_url = "$meter";
// ]]>
</script>
<script type="text/javascript" src="$meter/styles/js/aum.js"></script>
END-HEADER
	$f->ctx({leftover => undef, header => $header});
    }
  
    while (!$bb->is_empty) {
        my $b = $bb->first;
        $b->remove;
        
        if ($b->is_eos) {
            if (defined(${$f->ctx}{leftover})) {
                $bb_ctx->insert_tail(APR::Bucket->new($bb_ctx->bucket_alloc, ${$f->ctx}{leftover}));
            }
            $bb_ctx->insert_tail($b);
            last;
        } elsif ($b->read(my $buf)) {
            my $outbuf = "";
            # We need an output buffer, since we can't copy string data going into buckets
            
            $buf = ${$f->ctx}{leftover}.$buf if defined(${$f->ctx}{leftover});
            while ($buf=~/^(.*?)(<.*?>)(.*)/ms) {
                my ($pre,$tag);
                ($pre,$tag,$buf) = ($1,$2,$3);
                $outbuf.=$pre;
                if ($tag=~/^\<head>$/i) {
                    $tag .= ${$f->ctx}{header};
                }                
                $outbuf.=$tag;
            }
            $bb_ctx->insert_tail(APR::Bucket->new($bb_ctx->bucket_alloc, $outbuf));

            ${$f->ctx}{leftover} = $buf || undef;
        } else {
            $bb_ctx->insert_tail($b);
        }
    }
    
    my $rv = $f->next->pass_brigade($bb_ctx);
    return $rv unless $rv == APR::Const::SUCCESS;
    return Apache2::Const::OK;
}



# Input filters
# We use a null input filter (placed after apreq) to detect finished requests
sub f_ufu_handler {
    my ($f, $bb, $mode, $block, $readbytes) = @_;   
    my $c = $f->c;
    my $bb_ctx = APR::Brigade->new($c->pool, $c->bucket_alloc);
    my $rv = $f->next->get_brigade($bb_ctx, $mode, $block, $readbytes);
    return $rv unless $rv == APR::Const::SUCCESS;

    # Loop until we get EOS
    while (!$bb_ctx->is_empty) {
        my $b = $bb_ctx->first;

        if ($b->is_eos) {
            $f->ctx(1);
            $bb->insert_tail($b);
            last;
        }

        $b->remove;
        $bb->insert_tail($b);
    }

    # If we've seen EOS, update the cache 
    if ($f->ctx) {
        my $req = APR::Request::Apache2->handle($f->r);
        my $u_id=$f->r->pnotes("u_id");
        $f->r->pnotes("finished_upload" => 1);
        my $hook_cache=new Cache::FileCache(\%cache_options);
        unless ($hook_cache) {
            $f->r->log_reason("[Apache::UploadMeter] Could not instantiate FileCache.", __FILE__.__LINE__);
            return Apache2::Const::DECLINED;
        }
        my $size=$hook_cache->get($u_id."size");
        $hook_cache->set($u_id."len",$size);
        $hook_cache->set($u_id."finished",1);
    }
    return Apache2::Const::OK;
}    

# Utility routines

sub __add_version_string {
    my $r = shift;
    $r->err_headers_out->add("X-Powered-By" => "Apache-UploadMeter/$VERSION");
}

sub upload_jit_handler($)
{
    my $r=shift;
    my $config = __lookup_config($r, "UploadHandler");
    unless ($config) {
        $r->log->warn("[Apache::UploadMeter] Couldn't find configuration data for url " . $r->uri);
        return Apache2::Const::DECLINED;
    }
    $r->pnotes("Apache::UploadMeter::Config" => $config);
    __add_version_string($r);
    $r->add_input_filter(\&f_ufu_handler);
    #$r->push_handlers("PerlHandler",\&r_handler);
    #$r->handler("perl-script");
    return u_handler($r);
}

sub meter_jit_handler($)
{
    my $r=shift;
    __add_version_string($r);
    my $config = __lookup_config($r, "UploadMeter");
    unless ($config) {
        # Don't warn here; it shouldn't happen + we store all of our resources under this URI, so this will generate LOTs of false positives
        return Apache2::Const::DECLINED;
    }
    $r->pnotes("Apache::UploadMeter::Config" => $config);
    $r->handler("perl-script");
    $r->push_handlers("PerlHandler",\&um_handler);
    return Apache2::Const::DECLINED;
}
 
sub form_jit_handler($)
{
    my $r=shift;
    __add_version_string($r);
    my $config = __lookup_config($r, "UploadForm");
    unless ($config) {
        $r->log->warn("[Apache::UploadMeter] Couldn't find configuration data for url " . $r->uri);
        return Apache2::Const::DECLINED;
    }
    $r->pnotes("Apache::UploadMeter::Config" => $config);
    $r->push_handlers("PerlFixupHandler",\&uf_handler);
    my $format = $config->{'MeterType'};
    if ($format=~/^XML$/i) {
        $r->add_output_filter(\&f_xml_uploadform);
    } elsif ($format=~/^JSON$/i) {
        $r->add_output_filter(\&f_json_uploadform);
    } elsif ($format=~/^NONE$/i) {
        # Do nothing - user-experience will be managed externally
    } else {
        $r->log->warn("[Apache::UploadMeter] Invalid meter type $format");
    }
    return Apache2::Const::DECLINED;
}

sub __lookup_config {
    my $r = shift;
    my $match = shift;    
    my $dir_config = Apache2::Module::get_config(__PACKAGE__, $r->server, $r->per_dir_config);    
    my $config = undef;
    no strict 'refs';
    map {$config = $_ if ($_->{$match} && ($_->{$match} eq $r->uri));} %{$dir_config->{'meters'}};
    use strict 'refs';
    return $config;
}

my @directives = (
    {
        name            => "<UploadMeter",
        func            => __PACKAGE__ . "::configure",
        req_override    => Apache2::Const::OR_ALL,
        args_how        => Apache2::Const::RAW_ARGS,
        errmsg          => "Container to define an Apache::UploadMeter instance.",
    }, {
        name            => "</UploadMeter",
        func            => __PACKAGE__ . "::configure_end",
        req_override    => Apache2::Const::OR_ALL,
        args_how        => Apache2::Const::RAW_ARGS,
    }, {
        name            => "UploadMeter",
        func            => __PACKAGE__ . "::configure_invalid",
        req_override    => Apache2::Const::OR_ALL,
        args_how        => Apache2::Const::RAW_ARGS,
        cmd_data        => "UploadMeter",
    }, {
        name            => "UploadHandler",
        func            => __PACKAGE__ . "::configure_invalid",
        req_override    => Apache2::Const::OR_ALL,
        args_how        => Apache2::Const::RAW_ARGS,
        cmd_data        => "UploadHandler",
    }, {
        name            => "UploadForm",
        func            => __PACKAGE__ . "::configure_invalid",
        req_override    => Apache2::Const::OR_ALL,
        args_how        => Apache2::Const::RAW_ARGS,
        cmd_data        => "UploadForm",
    }, {
        name            => "MeterType",
        func            => __PACKAGE__ . "::configure_invalid",
        req_override    => Apache2::Const::OR_ALL,
        args_how        => Apache2::Const::RAW_ARGS,
        cmd_data        => "MeterType",
    },
);

Apache2::Module::add(__PACKAGE__, \@directives);

sub configure
{
    my ($self, $parms, $val) = @_;
    my $namespace=__PACKAGE__;
    $val =~s/^(.*)>$/$1/; # Clean trailing ">"
    if (my $error = $parms->check_cmd_context(Apache2::Const::NOT_IN_LIMIT |
                                              Apache2::Const::NOT_IN_DIR_LOC_FILE)) {
        die $error;
    }
    #Ignore <UploadMeter xxx> directive
    my $dir = $parms->directive->as_hash->{"UploadMeter"}->{$val};
    my $tmp = {};
    # Verify that we have our directives and get rid of other junk
    map {
        if (!(defined($dir->{$_}))) {
            die "Missing mandatory $_ parameter";
        }
        $tmp->{$_} = $dir->{$_};
    } qw(UploadMeter UploadHandler UploadForm);
    $tmp->{MeterType} = $dir->{MeterType} || "JSON";
    map {
        $tmp->{MeterOptions}{uc($_)}=1;
        } split(/\s/,$dir->{'MeterOptions'}) if defined($dir->{'MeterOptions'});
    $tmp->{MeterName} = $val;
    
    $self->{'meters'}{$val} = $tmp;
    my ($UH, $UF, $UM, $TYPE) = ($tmp->{UploadHandler},
                                 $tmp->{UploadForm},
                                 $tmp->{UploadMeter},
                                 $tmp->{MeterType},
                                 );
    my $config = <<"EOC";
<Location $UH>
    Options +ExecCGI
    PerlInitHandler Apache::UploadMeter::upload_jit_handler
</Location>
<Location $UF>
    Options +ExecCGI
    PerlInitHandler Apache::UploadMeter::form_jit_handler
</Location>
<Location $UM>
    Options +ExecCGI
    PerlInitHandler Apache::UploadMeter::meter_jit_handler
</Location>
PerlModule Apache::UploadMeter::Resources::XML
<Location $UM/styles/xml/aum.xsl>
    SetHandler perl-script
    PerlResponseHandler Apache::UploadMeter::Resources::XML::xsl
</Location>
<Location $UM/styles/xml/aum.xsd>
    SetHandler perl-script
    PerlResponseHandler Apache::UploadMeter::Resources::XML::xsd
</Location>
PerlModule Apache::UploadMeter::Resources::JavaScript
<Location $UM/styles/js/prototype.js>
    SetHandler perl-script
    PerlResponseHandler Apache::UploadMeter::Resources::JavaScript::prototype
</Location>
<Location $UM/styles/js/behaviour.js>
    SetHandler perl-script
    PerlResponseHandler Apache::UploadMeter::Resources::JavaScript::behaviour
</Location>
<Location $UM/styles/js/scriptaculous.js>
    SetHandler perl-script
    PerlResponseHandler Apache::UploadMeter::Resources::JavaScript::scriptaculous
</Location>
<Location $UM/styles/js/aum.js>
    SetHandler perl-script
    PerlResponseHandler Apache::UploadMeter::Resources::JavaScript::json_js
</Location>
PerlModule Apache::UploadMeter::Resources::CSS
<Location $UM/styles/css/aum.css>
    SetHandler perl-script
    PerlResponseHandler Apache::UploadMeter::Resources::CSS::json_css
</Location>
PerlModule Apache::UploadMeter::Resources::HTML
<Location $UM/styles/aum_popup.html>
    SetHandler perl-script
    PerlResponseHandler Apache::UploadMeter::Resources::HTML::json_popup
</Location>

EOC

    $parms->server->add_config([split /\n/, $config]);
    $parms->server->log->info("Configured $namespace v$VERSION \"$val\" $UH - $UM - $UF [$TYPE]");
}

sub configure_invalid {
    my ($self, $parms, $val) = @_;
    my $conf = $parms->info;
    die "Error: $conf must appear inside an <UploadMeter> container";
}

sub configure_end {
    my ($self, $parms, $val) = @_;
    my $conf = $parms->info;
    die "Error: </UploadMeter> without opening <UploadMeter>";
}

1;
__END__

=head1 NAME

Apache::UploadMeter - Apache module which implements an upload meter for form-based uploads

=head1 SYNOPSIS

XML-based graphical meter
  (in httpd.conf)
  
  PerlLoadModule Apache::UploadMeter
  <UploadMeter MyUploadMeter>
      UploadForm    /form.html
      UploadHandler /perl/upload
      UploadMeter   /perl/meter
      MeterType     XML
  </UploadMeter>

  (in /form.html)
  <!--#uploadform-->
  <INPUT TYPE="FILE" NAME="theFile"/>
  <INPUT TYPE="SUBMIT"/>
  </FORM>

Web 2.0 JS-based graphical meter
  (in httpd.conf)
  
  PerlLoadModule Apache::UploadMeter
  <UploadMeter MyUploadMeter>
      UploadForm    /form.html
      UploadHandler /perl/upload
      UploadMeter   /perl/meter
      MeterType     JSON
  </UploadMeter>

  (in /form.html)
  <FORM ACTION="/perl/upload" ENCTYPE="multipart/form-data" METHOD="POST" class="uploadform">
  <INPUT TYPE="FILE" NAME="theFile"/>
  <INPUT TYPE="SUBMIT"/>
  </FORM>
  
  <DIV class="uploadmeter"></DIV>


=head1 ONLINE DEMO

An online demo of a (fairly) up-to-date version of the progress meter can be seen
at http://uploaddemo.beamartyr.net/  [To conserve bandwidth, this URL won't allow
more than 5MB of uploaded data.  An attempt to upload more than that will cause
the upload to be prematurely canceled, so try to ensure the total size of the
files to be uploaded there is less than 5MB]

=head1 DESCRIPTION

Apache::UploadMeter is a mod_perl module which implements a status-meter/progress-bar
to show realtime progress of uploads done using a form with enctype=multipart/form-data.

The software includes several built-in DHTML widgets to display the progress bar
out-of-the box, or alternatively you can create your own custom widgets.

To use the enclosed JavaScript powered widget, simply modify the E<lt>formE<gt> tag to
include class="uploadform".

To use the XML/XSL powered widget, simply replace the existing opening E<lt>FORME<gt>
tag, with the a special directive E<lt>!--#uploadform--E<gt>.

NOTE: To use this module, mod_perl MUST be built with StackedHandlers enabled.

=head1 CONFIGURATION

Configuration is done in httpd.conf using <UploadMeter> sections which contain
the URLs needed to manipulate each meter.  Currently multiple meters are supported
with the drawback that they must use distinct URLs (eg, you can't have 2 meters
with the same UploadMeter path).

=over

=item *

E<lt>UploadMeter I<MyMeter>E<gt>
Defines a new UploadMeter.  The I<MyMeter> parameter specifies a unique name
for this uploadmeter.  Currently, names are required and must be unique.

In a future version, if no name is given, a unique symbol will be generated
for the meter.

Each UploadMeter section requires at least 2 sub-parameters

=over

=item *
UploadForm

This should point to the URI on the server which contains the upload form with
the special E<lt>!--#uploadform--E<gt> tag.  Note that there should NOT be an
opening E<lt>FORME<gt> tag, but there SHOULD be a closing E<lt>/FORME<gt>
tag on the HTML page.

=item *
UploadHandler

This should point to the target (eg, ACTION) of the upload form.  The target
should already exist and do something useful.

=item *
UploadMeter

This should point to an unused URI on the server. This URI will be used to
provide the progress-meter data.  If legacy XML/XSL mode is used, this will also
provide the actual meter window.

=item *
MeterType

Optional parameter specifying the type of pre-bundled meter (see L<BUILT-IN TYPES>
below).  If this parameter is omitted, JSON is assumed as the default value.

=item *
MeterOptions

Optional set of parameters for the meter (space delimited).  Can include one or
more of the following:

=over

=item *
JSON-LITE

Don't include external JavaScript dependencies by default.  If you specify this
option make sure you already include compatible versions of JavaScript dependencies
in your pages, or you may get errors.

Current requred libraries are:

Prototype-1.5.0
Behaviour-1.1
Scriptaculous-1.7.0

=back

=back

=back

=head1 DATA FORMAT

Apache::UploadMeter currently provides 2 types of meters: JavaScript (JSON)
based, and XML-based.  The JSON is the new default; it's sexier, slicker, works
out-of-the-box with modern browsers, and with the magic of AJAX and DHTML, doesn't
even need a popup window.  XML is also still actively supported and is aimed at
users who wish to further customize the user-experience or provide a non-browser
based UploadMeter.  Both JSON and XML provide identical data; a formal XSL schema
can be seen at http://uploaddemo.beamartyr.net/demo/xml/meter/styles/xml/aum.xsd

=head1 BUILT-IN TYPES

Apache::UploadMeter comes pre-bundled with 2 DHTML-based graphical meters that
can be used as-is, or just as reference points for builing your own custom
meters.  Currently the 2 types can be selected by specifying I<JSON> or I<XML> in
the MeterType configuration directive.  Each of these will cause
Apache::UploadMeter to add relevant code to your upload form page.

=head1 CUSTOMIZATION

Additionally, I<NONE> can be specified, which will allow you to customize your
user-experience without using any of the built-in meters.  To use this, you
must define your own widget, and query the UploadMeter URL on your own.

The UploadMeter currently accepts the following parameter:

=over

=item *
meter_id

The meter identifier.  This must be unique across all meters on the server.
A future version of this library will likely require that this be server-generated
and will embed this in the HTML form, either in JavaScript or elsewhere in the DOM
tree, but for now, you can specify anything you like (as long as each is unique).

=item *
format

This determines the data format that the meter will return.  Currently JSON can be
specified to return a JSON structure, otherwise an XML structure will be returned.
See L<DATA FORMAT>, above.

=item *
returned

This is a boolean (0 or 1) value used to help reduce race conditions when a new
upload is initiated.  If it is 0 or not defined, the server will cause the request
to block (for up to 15 seconds by default - overridable by setting
$Apache::UploadMeter::TIMEOUT) until the uploading content is detected by the
server and the meter's datastructure is initialized.  If it is 1, and the
I<meter_id> is not found on the server, a 404 error will be immediately returned.

=back

=head1 COMPATIBILITY

Beginning from version 0.99_01, this module is only compatible with
Apache2/mod_perl2 Support for Apache 1.3.x is discontinued, as it's too damn
complicated to configure in Apache 1.3.x  This may change in the future, but I
doubt it; servers are slowly but surely migrating from 1.3 to 2.x  Maybe it's
finally time for you to upgrade too.

=head1 AUTHOR AND COPYRIGHT

Copyright (c) 2001-2007 Issac Goldstand E<lt>margol@beamartyr.netE<gt> - All rights reserved.

This library is free software. It can be redistributed and/or modified
under the same terms as Perl itself.

This software contains third-party components licensed under BSD and MIT style
open-source licenses.

=head1 SEE ALSO

Apache2::Request(3)

=cut
