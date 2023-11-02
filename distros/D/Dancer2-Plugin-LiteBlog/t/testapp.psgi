#!/usr/bin/env perl

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";

{
    package app;
    use Dancer2;
    set appdir => 't';
    set views => 't/views';
    set public_dir => 't/public';
    set logger => 'Console::Colored';
    set log => 'info';
    set template => 'template_toolkit';

    set liteblog => {
        title => "My Testing Liteblog",
        logo => '/images/liteblog.jpg',
        feature => {
            highlight => 1,
        },
        navigation => [
            { label => 'Text Elem'},
            { label => 'Home', link => '/'},
            { label => 'About', link => '/'},
            { label => 'Perl', link => '/blog/perl'},
            { label => 'Contact', link => '/'},
        ],
        widgets => [
            { name => 'activities',
              params => { source => 'activities.yml' }},
            { name => 'blog',
              params => {
                title => "Stories of my Test App",
                mount => '/blog',
                root => 't/articles' }},
        ],
    };
    require 'Dancer2/Plugin/LiteBlog.pm';
    Dancer2::Plugin::LiteBlog->import;

    liteblog_init();
}

app->to_app;
