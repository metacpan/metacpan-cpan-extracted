#!/usr/bin/perl
use strict;
use warnings;
use utf8;

use API::Medium;

my $token = $ARGV[0];
print "Usage: $0 your_access_token\n" && exit unless $token;

my $m = API::Medium->new( { access_token => $token, } );

my $user = $m->get_current_user;

my $post_url = $m->create_post(
    $user->{id},
    {   "title"         => "Hello, Medium",
        "contentFormat" => "html",
        "content"       => "<h1>Hello, Medium</h1><p>It works...</p><p>s/🚗/🚲/g</p>",
        "tags"          => [ "Perl", "CPAN", "API" ],
        "publishStatus" => "draft",
        #"canonicalUrl": "http://example.com/it-works.html",
    }
);

print "Your post is ready: $post_url\n";

