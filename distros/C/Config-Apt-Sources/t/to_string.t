#!perl -T

use strict;
use warnings;
use Test::More tests => 1;

use Config::Apt::Sources;
my $srcs = Config::Apt::Sources->new();
my $text = do { local $/; <DATA> };

$srcs->parse_stream($text);
ok($srcs->to_string() eq $text);

__DATA__
deb http://ftp.us.debian.org/debian/ unstable main non-free contrib
deb-src http://ftp.us.debian.org/debian/ unstable main non-free contrib
deb http://security.debian.org/ testing/updates main
