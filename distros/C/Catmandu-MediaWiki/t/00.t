#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

my @pkgs = qw(
    Catmandu::MediaWiki
    Catmandu::Importer::MediaWiki
);

require_ok $_ for @pkgs;

done_testing 2;
