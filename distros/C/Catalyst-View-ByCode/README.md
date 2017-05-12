# Catalyst::View::ByCode #

Simple templating just using Perl (and a fancy syntax).

A simple template might look like:

    template {
        html {
            head {
                title { stash->{title} };
                load Js => 'site.js';
                load Css => 'site.css';
            };
            body {
                div header.noprint {
                    ul.topnav {
                        li { 'home' };
                        li { 'surprise' };
                    };
                };
                div content {
                    h1 { stash->{title} };
                    div { 'hello.pl is running!' };
                    img(src => '/static/images/catalyst_logo.png');
                };
            };
        };
    };
