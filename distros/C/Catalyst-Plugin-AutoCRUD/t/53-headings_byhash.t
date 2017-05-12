#!/usr/bin/perl

use strict;
use warnings;
use lib qw( t/lib );
use JSON::XS;

use Test::More 'no_plan';

# test should allow override of display_name but not change
# the displayed columns

# application loads
BEGIN {
    $ENV{AUTOCRUD_DEBUG} = 1;
    $ENV{AUTOCRUD_CONFIG} = 't/lib/headings_byhash.conf';
    use_ok "Test::WWW::Mechanize::Catalyst::AJAX" => "TestAppCustomConfig";
}
my $mech = Test::WWW::Mechanize::Catalyst::AJAX->new;

$mech->get_ok("/autocrud/site/default/schema/dbic/source/album/dumpmeta", "Get metadata for album table");
my $content = JSON::XS::decode_json($mech->content);

ok(exists $content->{cpac}->{conf}->{dbic}->{t}->{album}->{headings}, 'headings created');

my $headings = $content->{cpac}->{conf}->{dbic}->{t}->{album}->{headings};
ok(ref $headings eq 'HASH', 'headings imported as hash');

#use Data::Dumper;
#print STDERR Dumper $headings;

ok(scalar keys %$headings, 'only two columns selected');
ok($headings->{title} eq 'TheTitle', 'heading value for Title preserved');
ok($headings->{recorded} eq 'Recorded', 'heading value for Recorded preserved');
ok($headings->{copyright} eq 'Copyrights', 'heading value for Copyright preserved');

__END__
