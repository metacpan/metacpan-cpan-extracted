package main;

use 5.006002;

use strict;
use warnings;

use Astro::SpaceTrack;
use Test::More 0.96;	# For subtest

use lib qw{ inc };
use My::Module::Test;

my $st = Astro::SpaceTrack->new();

my $skip;
$skip = site_check 'celestrak.com'
    and plan skip_all => $skip;

$st->set(
    direct	=> 1,
);

my $rslt = eval { $st->celestrak( 'stations' ) }
    or diag "\$st->celestrak( 'stations' ) failed: $@";

ok $rslt->is_success(), 'Direct fetch Celestrak stations'
    or diag $rslt->status_line();

is $st->content_type(), 'orbit', "Content type is 'orbit'";

is $st->content_source(), 'celestrak', "Content source is 'celestrak'";

is $st->content_type( $rslt ), 'orbit', "Result type is 'orbit'";

is $st->content_source( $rslt ), 'celestrak',
    "Result source is 'celestrak'";

is_success $st, celestrak => 'iridium',
    'Direct-fetch Celestrak iridium';

is $st->content_type(), 'orbit', "Content type is 'orbit'";

is $st->content_source(), 'celestrak', "Content source is 'celestrak'";

is_error $st, celestrak => 'fubar',
    404, 'Direct-fetch non-existent Celestrak catalog';

is_success $st, celestrak_supplemental => 'orbcomm',
    'Fetch Celestrak supplemental Orbcomm data';

is $st->content_type(), 'orbit', "Content type is 'orbit'";

is $st->content_source(), 'celestrak', "Content source is 'celestrak'";

is_success $st, celestrak_supplemental => '-rms', 'intelsat',
    'Fetch Celestrak supplemental Intelsat RMS data';

is $st->content_type(), 'rms', "Content type is 'rms'";

is $st->content_source(), 'celestrak', "Content source is 'celestrak'";

done_testing;

1;

# ex: set textwidth=72 :
