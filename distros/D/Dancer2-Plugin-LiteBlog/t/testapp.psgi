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
        favicon => '/images/liteblog.jpg',
        base_url => 'http://localhost:4000/',
        description => 'Some general description of the testing app',
        tags => ['foo', 'bar', 'baz'],
        show_render_time => 1,
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
        route_widgets => {
            '/page2' => {
                navigation => [],
                widgets => [
            { 
                name => 'blog',
                params => {
                    title => "Page 2 Stories",
                    mount => '/page2/blog',
                    root => 't/articles' }
            },
            { 
                name => 'activities',
                params => { source => 'activities.yml' }
            },

            ]}
        },
        widgets => [
        {   name => 'caroussel',
                params => {
                    slides => [
                    {
                        title => 'Splash Title',
                        image => '/blog/tech/first-article/featured.jpg',
                        baseline => 'A great and minimalist blog engine for Dancer2',
                        cta => {
                            label => 'Subscribe!',
                            link => '/subscribe',
                        }
                    },
                    { 
                        title => "Some Content", 
                        baseline => "This is a second slide with a content div",
                        content => "Some content I write in HTML. <p>a paragraph</p>",
                        cta => {
                            label => 'Bouton 2',
                            link => '/subscribe',
                        }
                    },
                    { 
                        title => "Video",
                        youtube => "XZvN5W6C6No",
                        cta => {
                            label => 'Button3',
                            link => '/subscribe',
                        }
                    }
                    ]
                }
            },
            {
                name => 'custom',
                params => {
                    root => 't/slideshow-poc',
                    source => 'slidenatural.html',
                },
            },
            { 
                name => 'blog',
                params => {
                    title => "Stories of my Test App",
                    mount => '/blog',
                    root => 't/articles' }
            },
            { 
                name => 'activities',
                params => { source => 'activities.yml' }
            },
    
        ],
    };
    require 'Dancer2/Plugin/LiteBlog.pm';
    Dancer2::Plugin::LiteBlog->import;

    liteblog_init();
}

app->to_app;
