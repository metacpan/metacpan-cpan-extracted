package main;

use 5.006002;

use strict;
use warnings;

use Astro::SpaceTrack;
use Test::More 0.96;	# For subtest

use lib qw{ inc };
use My::Module::Test;

my $st = Astro::SpaceTrack->new();

$st->set( webcmd => undef );

is_success $st, 'banner', 'Get banner';

is_success $st, 'help', 'Get internal help';

is $st->content_type(), 'help', "Content type is 'help'";

not_defined $st->content_source(), "Content source is undef";

is_success $st, 'names', 'celestrak', 'Retrieve Celestrak catalog names';

is_not_success $st, 'names', 'bogus', 'Can not retrieve bogus catalog names';

$st->set( banner => undef, filter => 1 );
$st->shell( '', '# comment', 'set banner 1', 'exit' );
ok $st->get('banner'), 'Reset an attribute using the shell';

done_testing;

1;

# ex: set textwidth=72 :
