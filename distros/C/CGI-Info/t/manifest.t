#!perl -w

use strict;
use warnings;
use Test::Most;

if($ENV{AUTHOR_TESTING}) {
	eval 'use Test::CheckManifest 0.9';
	plan(skip_all => 'Test::CheckManifest 0.9 required') if $@;
	ok_manifest({ filter => [qr/(\.git)|(\..+\.yml$)/] });
} else {
	plan(skip_all => 'Author tests not required for installation');
}
