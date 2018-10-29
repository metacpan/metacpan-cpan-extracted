package main;

use 5.006002;

use strict;
use warnings;

use Astro::SpaceTrack;
use Test::More 0.96;	# For subtest

use lib qw{ inc };
use My::Module::Test;

my $skip;
$skip = site_check 'celestrak.com', 'mike.mccants'
    and plan skip_all => $skip;

my $st = Astro::SpaceTrack->new();

$st->set(
    iridium_status_format	=> 'kelso',
);

SKIP: {

    is_success_or_skip $st, 'iridium_status', 'Get Iridium status (Kelso)', 2;

    is $st->content_type(), 'iridium-status',
	"Content type is 'iridium-status'";

    is $st->content_source(), 'kelso', "Content source is 'kelso'";
}

done_testing;

1;

# ex: set textwidth=72 :
