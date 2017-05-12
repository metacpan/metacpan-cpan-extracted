#!/usr/bin/perl

use FindBin;
use lib ( "$FindBin::Bin/../lib" );
use strict;
use warnings;
use CSS::SpriteBuilder;
use Data::Dumper;

my $root = $FindBin::Bin;

my $builder = CSS::SpriteBuilder->new(
    source_dir     => "$root/icons",
    output_dir     => "$root/sprites",
    css_url_prefix => 'sprites/',
);

$builder->build(config => "$root/config.xml");
print $builder->write_html();

