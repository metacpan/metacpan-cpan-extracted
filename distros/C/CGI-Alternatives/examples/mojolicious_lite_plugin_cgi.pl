#!/usr/bin/env perl

# automatically enables "strict", "warnings", "utf8" and Perl 5.10 features
use Mojolicious::Lite;
use Mojolicious::Plugin::CGI;
use FindBin qw/$Bin/;

#plugin CGI => [ '/example_form' => "examples/cgi_tt.pl" ];
plugin CGI => [ '/example_form' => "examples/cgi.pl" ];

app->start;
