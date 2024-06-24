#!/usr/bin/env perl

use strict;
use warnings;

use App::CPAN::Get::MetaCPAN;
use Data::Printer;

my $obj = App::CPAN::Get::MetaCPAN->new;

my $content_hr = $obj->search({
        'package' => 'App::Pod::Example',
        'version_range' => '>0.18,<=0.40',
});

p $content_hr;

# Output (2024/06/23):
# {
#     checksum_md5      "dcc4d6f0794c6fc985a6b3c9bd22f88d",
#     checksum_sha256   "ca71d7d17fe5ea1cd710b9fce554a1219e911baefcaa8ce1ac9c09425f6ae445",
#     date              "2023-03-29T09:57:36" (dualvar: 2023),
#     download_url      "https://cpan.metacpan.org/authors/id/S/SK/SKIM/App-Pod-Example-0.20.tar.gz",
#     release           "App-Pod-Example-0.20",
#     status            "latest",
#     version           0.2
# }