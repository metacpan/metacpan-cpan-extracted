#!/usr/bin/perl

use warnings;
use strict;

use lib 'lib';
use Test::More tests => 6;

# The versions of the following packages are reported to help understanding
# the environment in which the tests are run.  This is certainly not a
# full list of all installed modules.
my @show_versions =
 qw/Test::More
    XML::LibXML
    XML::LibXML::Simple
   /;

foreach my $package (@show_versions)
{   eval "require $package";

    no strict 'refs';
    my $report
      = !$@    ? "version ". (${"$package\::VERSION"} || 'unknown')
      : $@ =~ m/^Can't locate/ ? "not installed"
      : "reports error";

    warn "$package $report\n";
}

my $xml2_version = XML::LibXML::LIBXML_DOTTED_VERSION();
warn "libxml2 $xml2_version\n";

my ($major,$minor,$rev) = split /\./, $xml2_version;
if(  $major < 2
 || ($major==2 && $minor < 6)
 || ($major==2 && $minor==6 && $rev < 23))
{   warn <<__WARN;

*
* WARNING:
* Your libxml2 version ($xml2_version) is quite old: you may
* have failing tests and poor functionality.
*
* Please install a new version of the library AND reinstall the
* XML::LibXML module.  Otherwise, you may need to install this
* module with force.
*

__WARN

    warn "Press enter to continue with the tests: \n";
    <STDIN>;
}

require_ok('Apache::Solr::Tables');
require_ok('Apache::Solr');
require_ok('Apache::Solr::Document');
require_ok('Apache::Solr::Result');
require_ok('Apache::Solr::XML');
require_ok('Apache::Solr::JSON');
