#!perl -T

use strict;
use warnings;
use Test::More tests => 2;

use Config::Apt::Sources;

### Test comment bug in SourceEntry
my $src = Config::Apt::SourceEntry->new("deb http://example.com/debian testing main contrib#comment");
my @components = $src->get_components();
ok($components[1] eq "contrib", 'no comment bug');

### Comment with leading whitespace in Sources
my $srcs = Config::Apt::Sources->new();
$srcs->parse_stream(do { local $/; <DATA> });
ok((($srcs->get_sources)[0]->get_components())[1] eq "non-free", 'comments with leading whitespace');

__DATA__
  # aoeu
deb http://ftp.us.debian.org/debian/ unstable main non-free contrib
