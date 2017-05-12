#!/usr/bin/env perl
use feature ':5.10';
use Test::More;
use lib 'lib';
use Apache::SiteConfig;
use Apache::SiteConfig::Template;

# default template
my $template = Apache::SiteConfig::Template->new;
ok( $template );
# my $context = $template->build( );
# say $context->to_string;




done_testing;
