#!/usr/bin/perl

use strict;
use warnings;
use Test::More;

unless ( $ENV{RELEASE_TESTING} ) {
    plan( skip_all => "Author tests not required unless RELEASE_TESTING" );
}

eval "use Test::CheckManifest 1.42";
plan skip_all => "Test::CheckManifest 1.42 required" if $@;
ok_manifest({exclude => ['/.git', '/tools'],
			 filter => [qr/ \.git
						  | \.travis\.yml
						  | TODO.txt /x]});
