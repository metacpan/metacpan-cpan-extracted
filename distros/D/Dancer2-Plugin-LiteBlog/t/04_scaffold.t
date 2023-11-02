use Test::More;
use strict;
use warnings;

use Dancer2::Plugin::LiteBlog::Scaffolder;
use Dancer2::Plugin::LiteBlog::Scaffolder::Data;

SKIP: {
    skip "because the scafolder has not been built"
        if ! defined Dancer2::Plugin::LiteBlog::Scaffolder::Data->build;

    my $d = Dancer2::Plugin::LiteBlog::Scaffolder->load;
    like $d->{'views/layouts/liteblog.tt'}, qr{<title>\[% title %\]}, 
        "Found views/layouts/liteblog.tt, looks good";

    like $d->{'public/images/liteblog.jpg'}, qr/4AAQSkZJRgABAQEASABIAAD/,
        "Image liteblog.jpg is encoded as base64 content";

    like $d->{'public/css/liteblog.css'}, qr/clickable-div/,
        "Stylesheet liteblog.css looks good";
};
done_testing;
