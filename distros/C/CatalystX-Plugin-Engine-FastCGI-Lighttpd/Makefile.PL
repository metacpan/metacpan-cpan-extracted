#
# $Id$
#
package main;
use strict;
use warnings;
use utf8;
our $VERSION = eval { require version; version::qv('0.1.0') };

use inc::Module::Install;

name 'CatalystX-Plugin-Engine-FastCGI-Lighttpd';
version "$VERSION";
perl_version '5.008';
all_from 'lib/CatalystX/Plugin/Engine/FastCGI/Lighttpd.pm';

requires 'version';

auto_include;
auto_install;

WriteAll;

1;
