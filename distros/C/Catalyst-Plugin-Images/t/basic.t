#!/usr/bin/perl

use strict;
use warnings;

use Test::More 'no_plan';

use lib "t/lib";

use ok "Test::WWW::Mechanize::Catalyst" => "ImgTestApp";

my $mech = Test::WWW::Mechanize::Catalyst->new;

my %test_data = (
    first => {
        custom_attr => "blah",
        name => "one/foo.png",
        width => 88,
        height => 31,
    },
    second => {
        name => "two/bar.png",
        width => 1234,
        height => 50,
    },
    third => {
        name => "la.png",
        alt => "blah",
    },
    fourth => {
        name => "gorch.png",
        width => 88,
        height => 31,
    },
    fifth => {
        name => "bah/oink",
    },
);

foreach my $image ( keys %test_data ) {

    $mech->get_ok("http://localhost/images/$image");

    $mech->content_like(qr{ <img .* /> }x, "looks like an image tag");

    my $content = $mech->content;
    my %attrs = ($content =~ /(\w+)="(.*?)"/g);

    my $name = quotemeta( delete $test_data{$image}{name} );
    like( $attrs{src}, qr{^http://localhost/$name$}, "image uri is correct");

    foreach my $attr ( keys %{ $test_data{$image} } ) {
        is( $attrs{$attr}, $test_data{$image}{$attr}, "$attr has correct value" ) || warn Data::Dumper::Dumper( \%attrs );
    }
}
