package Apache::XBEL;
use strict;

# $Id: XBEL.pm,v 1.11 2004/03/01 21:25:11 asc Exp $

=head1 NAME

Apache::XBEL - mod_perl handler to transform XBEL into exciting
and foofy HTML documents.

=head1 SYNOPSIS

 <Location />
  SetHandler  perl-script
  PerlHandler Apache::XBEL

  PerlSetVar  XbelPath     /path/to/yer-xbel-file.xbel
  PerlSetVar  XslPath      /path/to/apache-xbel.xsl
  PerlSetVar  CacheDir     /path/to/yer-cache-dir

  # If set to "On", output-escaping will be disabled
  # for title and description nodes in the XSL stylesheet

  PerlSetVar DisableEscaping   On

 </Location> 

=head1 DESCRIPTION

Apache::XBEL is an Apache mod_perl handler that uses XSLT to
transform XML Bookmarks Exchange Language (XBEL) files into
exciting and foofy dynamic HTML documents. 

Documents are rendered as collapsible outlines and individual
nodes may be viewed and bookmarked as unique pages, so you don't
have to click through a gazillion nested leaves to find what
you're looking for.

Once individual nodes/pages have been rendered, they are cached
to reduce the load on the server. Cache files are updated
whenever any of the widgets involved in the transformation are
modified.

=head1 OPTIONS

=head2 XbelPath

I<required>

The path to the XBEL file you are transforming.

=head2 XslPath

I<required>

The path to the XSL file used to do the transforming.

=head2 CacheDir

I<required>

The path to a directory where the mod_perl interpreter can
write cache files.

=head2 DisableEscaping

If set to "On" (case-insenstive) output-escaping will be
disabled for title and description nodes in the XSL
stylesheet.

=head2 HtmlLang

Set this as the value of /html[@xml:lang]

=cut

$Apache::XBEL::VERSION = '1.3';

use Apache;
use Apache::Constants qw(:common :response);
use Apache::File;
use Apache::Log;
use Apache::URI;

use Digest::MD5 qw(md5_hex);

use File::Basename;
use File::Copy;
use File::Spec;

use Memoize;

use XML::LibXML;
use XML::LibXSLT;

my $xml_parser;
my $xsl_parser;
my $xsl_stylesheet;
my $xsl_transformer;

memoize ("cache_file");

sub handler {
    my $apache = shift;
    $apache->register_cleanup(sub{&cleanup($apache)});

    #

    my $root       = $apache->location();
    my $root_uri   = $apache->uri($root);
    $root_uri      =~ /($root)(.*)/;
    my $path       = $2;

    $path =~ s/\/$//;
    $path =~ s/^\///;
    $root =  &basename($root);

    #

    my $uri        = Apache::URI->parse($apache);
    my $uri_scheme = $uri->scheme();
    my $uri_host   = $uri->hostname();

    if (! ($root_uri =~ /(.*)\/$/)) {
	my $redirect = "$uri_scheme://$uri_host$root_uri/";
	$apache->headers_out->set("Location"=>$redirect);
	return REDIRECT;
    }

    #

    my $xsl_file = $apache->dir_config("XslPath");
    
    if (! -f $xsl_file) {
	$apache->log->error("Unable to locate '$xsl_file'.\n");
	return NOT_FOUND;
    }

    #

    if (! -d $apache->dir_config("CacheDir")) {
	$apache->log->error("Unable to locate the cache directory.\n");
	return SERVER_ERROR;
    }
    
    #

    $xml_parser ||= XML::LibXML->new();
	
    if (! $xml_parser) {
	$apache->log->alert("Unable to create XML::LibXML object. $!");
	return SERVER_ERROR;
    } 
	
    #

    $xsl_parser ||= XML::LibXSLT->new();

    if (! $xsl_parser) {
	$apache->log->alert("Unable to create XML::LibXSLT object. $!");
	return SERVER_ERROR;
    }

    #

    $xsl_stylesheet ||= $xml_parser->parse_file($xsl_file);

    if (! $xsl_stylesheet) {
	$apache->log->alert("Failed to parse file $xsl_file");
	return SERVER_ERROR;
    };

    #

    $xsl_transformer ||= $xsl_parser->parse_stylesheet($xsl_stylesheet);	

    if (! $xsl_transformer) {
	$apache->log->alert("Failed to parse stylesheet object.");
	return SERVER_ERROR;
    }

    #

    my $xbel_file = &load_file($apache->dir_config("XbelPath"));
    
    #
    
    my ($cache_file,$exists) = &fetch_cache($apache,$xbel_file,$path);
    
    if ($exists) {
	$apache->content_type("text/html");
	$apache->send_http_header();
	$apache->send_fd( Apache::File->new($cache_file) );
	return OK;
    }
    
    #

    my $xbel_doc = $xml_parser->parse_file($xbel_file);

    if (! $xbel_doc) {
	$apache->log->alert("Unable to parse XBEL document : $!\n");
	return SERVER_ERROR;
    }

    # Note that we actually make use of @path
    # below. We're not just cluttering up the
    # symbol table for crazy reasons like, oh
    # I don't know, increased readability...

    my @path   = File::Spec->splitdir($path);
    my $lookup = &path2node(@path);

    my $nodes  = ($xbel_doc->findnodes($lookup))[0];
    
    if (! $nodes) {
	$apache->log->error("Lookup for '$lookup' failed.\n");
	return NOT_FOUND;
    }

    #

    if ($nodes->getName eq "xbel") {

	if (! copy($xbel_file,$cache_file)) {

	    $apache->log->error("Failed to copy '$xbel_file' to '$cache_file', $!\n");
	    return SERVER_ERROR;
	}
    }

    elsif (! &render_slice($apache,$cache_file,$xbel_doc,$nodes)) {

	# error is logged in function
	return SERVER_ERROR;
    }

    else { }

    # Set up some variables that
    # we'll use later

    my $loc = $apache->location();
    $loc =~ s/\/$//;

    # XSLT parameters

    my %params = ();
    
    $params{ "base" } = 
	"'$uri_scheme://$uri_host".
	join("/",$loc,@path[0..($#path - 1)]).
	"/'";
    
    $params{ "escaping" } = 
	($apache->dir_config("DisableEscaping") =~ /^(on)$/i) ? 1 : 0; 

    if (my $lang = $apache->dir_config("HtmlLang")) {
	$params{ "lang" } = "'$lang'";
    }
    
    # XSLT functions

    my $i = 0;

    my @breadcrumbs = ("root",@path);

    my @hrefs = map { 
	join("/",@breadcrumbs[1..$i++]);
    } @breadcrumbs;

    $xsl_parser->register_function("urn:aaronstraupcope:apache:xbel",
				   "breadcrumbs",
				   sub { return shift @breadcrumbs; });   

    $xsl_parser->register_function("urn:aaronstraupcope:apache:xbel",
				   "href_for_crumb",
				   sub { return join("/",
						     "$uri_scheme://$uri_host$loc",
						     shift @hrefs); });

    # Munge munge munge

    my $xmldoc = $xml_parser->parse_file($cache_file);
    my $html   = $xsl_transformer->transform($xmldoc,%params);
    
    $xsl_transformer->output_file($html,$cache_file);

    # Send the stupid file, already

    $apache->content_type("text/html");
    $apache->send_http_header();

    $apache->send_fd(Apache::File->new($cache_file));
    return OK;
}

sub cleanup {
    my $apache = shift;
    return 1;
}

sub cache_file {
    my $apache = shift;
    my $file = shift;
    my $path = shift;

    my $hex = &md5_hex(join("#",$file,$path));
    return File::Spec->catfile($apache->dir_config("CacheDir"),$hex);
}

sub fetch_cache {
    my $apache = shift;
    my $file   = shift;
    my $path   = shift;

    my $cache = &cache_file($apache,$file,$path);

    # Check for existence

    if (! -e $cache) {
	$apache->log->debug("Cachefile '$cache' does not exist.");
	return ($cache,0);
    }

    #

    my $cache_mtime = (stat($cache))[9];

    if ((stat(__FILE__))[9] > $cache_mtime ) {
	$apache->log->debug("Cache is out of sync with handler.");
	return ($cache,0);
    }

    if ((stat($file))[9] > $cache_mtime ) {
	$apache->log->debug("Cache is out of sync with XBEL file.");
	return ($cache,0);
    }

    my $xsl_file = $apache->dir_config("XslPath");

    if ((stat($xsl_file))[9] > $cache_mtime) {
	$apache->log->debug("Cache is out of sync with stylesheet.");

	$xsl_stylesheet  = $xml_parser->parse_file($xsl_file);
	$xsl_transformer = $xsl_parser->parse_stylesheet($xsl_stylesheet);
	
	return ($cache,0);
    }

    return ($cache,1);
}

sub path2node {
    my @path = map { "folder[\@id=\"$_\"]"; } @_;
    return join("/","","xbel",@path);
}

sub render_slice {
    my $apache = shift;
    my $file   = shift;
    my $doc    = shift;
    my $node   = shift;

    #

    my $owner = $doc->find(qq(/xbel/info/metadata[\@owner]));
    my $ver   = $doc->version();
    my $enc   = $doc->encoding();

    my $dom  = XML::LibXML::Document->createDocument($ver,$enc);
    my $xbel = XML::LibXML::Element->new(qq(xbel));

    my $info = XML::LibXML::Element->new(qq(info));
    my $meta = XML::LibXML::Element->new(qq(metadata));
    $meta->setAttribute("owner",$owner);

    my $title = XML::LibXML::Element->new(qq(title));
    $title->appendText($doc->find(qq(/xbel/title)));

    my $desc = XML::LibXML::Element->new(qq(desc));
    $desc->appendText($doc->find(qq(/xbel/desc)));
    
    $info->appendChild($meta);
    $xbel->appendChild($title);
    $xbel->appendChild($info);
    $xbel->appendChild($desc);

    # Add support to expand <alias>
    # elements here. This is slated
    # for version 1.5

    $xbel->appendChild($node);
    $dom->setDocumentElement($xbel);

    #

    if (my $fh = &get_fh($apache,$file)) {

	# WTF doesn't Apache::File
	# have a print method?

	print $fh $dom->toString();
	undef $dom;
	
	$fh->close();
	return 1;
    }

    return 0;
}

sub get_fh {
    my $apache = shift;
    my $file   = shift;

    my $fh = Apache::File->new();

    if (! $fh->open(">$file")) { 
	$apache->log->error("Failed to open $file for writing : $!\n"); 
	return SERVER_ERROR;
    }

    return &lock_cache($apache,$fh);
}

sub lock_cache {
    my $apache = shift;
    my $fh     = shift;

    my $success = 0;
    my $tries   = 0;

    while ($tries++ < 10) {
	return $fh if ($success = flock($fh,2));
	sleep(1);
    }

    $apache->log->error("Failed to lock file for writing.");
    return undef;
}

# This is here so that, eventually, it can
# be sub-classed.

sub load_file {
    return $_[0];
}

=head1 VERSION

1.3

=head1 DATE

$Date: 2004/03/01 21:25:11 $

=head1 AUTHOR

Aaron Straup Cope <ascope@cpan.org>

=head1 SEE ALSO

http://pyxml.sourceforge.net/topics/xbel/

http://aaronland.info/perl/apache/xbel/example/1.3

http://aaronland.info/xsl/xbel/apache-xbel

=head1 NOTES

=over 4

=item *

If you are running this handler on a server that is also running
AxKit, pre version 1.5, Apache::XBEL may periodically fail and
return a server error. Some reports have suggested that reloading
the page may cause the widget to load properly. Or not.

=item *

Hooks for munging outliner documents with Text::Outline have been
removed as of release 1.3. They may come back, at a later date, in
a separate Apache::XBEL::Outline package.

=back 

=head1 TO DO

=over 4

=item * 

Replace nested 'div' elements with some flavour of nested lists and
de-couple CSS from apache-xbel.xsl. De-couple JavaScript from 
apache-xbel.xsl These changes are slated for version 1.4

=item *

Support for expanding <alias> elements. This is slated for version 
1.5

=item *

Support for mod_perl 2.0. This is slated for version 2.0

=back

=head1 BUGS

Please report all bugs to : http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Apache::XBEL

=head1 LICENSE

Copyright (c) 2001-2004 Aaron Straup Cope. All Rights Reserved.

This is free software, you may use it and distribute it under
the same terms as Perl itself.

=cut

return 1;
