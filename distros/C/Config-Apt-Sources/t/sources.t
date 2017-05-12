#!perl -T

use strict;
use warnings;
use Test::More tests => 3;

use Carp;
use Config::Apt::Sources;
my $srcs = Config::Apt::Sources->new();

### Parse the file
$srcs->parse_stream(do { local $/; <DATA> });
ok((($srcs->get_sources)[0]->get_components())[1] eq "non-free", 'file parsed correctly');

### Reference bug: mirror gets updated when the array of sources gets changed.  This should not happen.
($srcs->get_sources)[2]->set_uri("http://example.com");
ok(($srcs->get_sources)[2]->to_string() ne "deb http://example.com testing/updates main", 'no reference bug');

### Test set_sources
my @sources = $srcs->get_sources;
$sources[2]->set_uri("http://example.com");
$srcs->set_sources(@sources);

ok(($srcs->get_sources)[2]->to_string() eq "deb http://example.com testing/updates main", 'set_sources');

__DATA__
deb http://ftp.us.debian.org/debian/ unstable main non-free contrib
deb-src http://ftp.us.debian.org/debian/ unstable main non-free contrib
# This is a comment.  It's cooler than all its other comment buddies because
#   it's followed by a blank line, too!

deb http://security.debian.org/ testing/updates main
