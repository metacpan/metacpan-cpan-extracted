#!/usr/bin/perl -w

use strict;
use CGI qw(:cgi);
use XML::LibXSLT;
use XML::LibXML;
use AxKit::XSP::Wiki;

my $output = '<?xml version="1.0"?>
<xspwiki>';
my $path_info = path_info();
      
# CHANGE THESE!
my $dbroot = '/tmp/wikis';
# my $xsltroot = "$ENV{DOCUMENT_ROOT}/stylesheets";
my $xsltroot = "/tmp/wikis/stylesheets";
my $default_db = 'Xiki';
my $default_page = 'Main';

my $uri = url(-absolute => 1);
      
my ($db, $page) = AxKit::XSP::Wiki::extract_page_info($path_info);

if (!$db) {
    print redirect("$uri/$default_db/$default_page");
    exit;
}
if (!$page) {
    print redirect("$uri/$db/$default_page");
    exit;
}

my $action = param('action') || 'view';
$action = 'preview' if param('preview');
my $id = param('id');
if ($id !~ /^\d*$/) {
    die "Invalid id format";
}

if ($action eq 'save') {
    my $ip = remote_host();
    AxKit::XSP::Wiki::save_page(
        $dbroot, $db, $page, param('text'), param('texttype'), $ip,
    );
    print redirect("$uri/$db/$page");
    exit;
}
elsif ($action eq 'restore') {
    my $ip = remote_host();
    AxKit::XSP::Wiki::restore_page(
        $dbroot, $db, $page, $ip, $id,
    );
    print redirect("$uri/$db/$page");
    exit;
}
elsif ($action eq 'preview') {
    $output .= '
        <page>' . xml_escape($page) . '</page>
        <db>' . xml_escape($db) . '</db>
        ' . AxKit::XSP::Wiki::preview_page($dbroot, $db, $page, param('text'), param('texttype'));
}
elsif ($action eq 'search') {
    $output .= '
        <page>' . xml_escape($page) . '</page>
        <db>' . xml_escape($db) . '</db>
        ' . AxKit::XSP::Wiki::search($dbroot, $db, param('q'));
}
else {
    $output .= '
	<page>' . xml_escape($page) . '</page>
        <db>' . xml_escape($db) . '</db>
        ' . AxKit::XSP::Wiki::display_page($dbroot, $db, $page, $action, $id);
}

$output .= '
</xspwiki>
';

warn("Parsing: $output\n");
XML::LibXSLT->debug_callback(sub { warn(@_) });
my $source = XML::LibXML->new->parse_string($output)  || die "Couldn't parse output";
my $xslt = XML::LibXSLT->new->parse_stylesheet_file("$xsltroot/wiki.xsl") || die "Couldn't parse $xsltroot/wiki.xsl";

my $results = $xslt->transform($source);

print header, $xslt->output_string($results);

exit;

sub xml_escape {
    return AxKit::XSP::Wiki::xml_escape(@_);
}
