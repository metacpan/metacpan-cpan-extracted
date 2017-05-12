package main;

use 5.006002;

use strict;
use warnings;

use Astro::SpaceTrack;
use File::Temp;
use Test::More 0.96;	# For subtest

use lib qw{ inc };
use My::Module::Test;

my $skip;
$skip = site_check 'mike.mccants'
    and plan skip_all => $skip;

my $st = Astro::SpaceTrack->new();

is_success $st, qw{ mccants classified }, 'Get classified elements';

is $st->content_type(), 'orbit', "Content type is 'orbit'";

is $st->content_source(), 'mccants', "Content source is 'mccants'";

is_success $st, qw{ mccants integrated }, 'Get integrated elements';

is $st->content_type(), 'orbit', "Content type is 'orbit'";

is $st->content_source(), 'mccants', "Content source is 'mccants'";

my $temp = File::Temp->new();

# In order to try to force a cache miss, we set the access and
# modification time of the file to the epoch.
my @opt = eval { utime 0, 0, $temp->filename() } ?
    ( '-file' => $temp->filename() ) :
    ();

is_success $st, 'mccants', @opt, 'mcnames',
    'Get molczan-style magnitudes';

is $st->content_type(), 'molczan', "Content type is 'molczan'";

is $st->content_source(), 'mccants', "Content source is 'mccants'";

ok ! $st->cache_hit(), 'Content did not come from cache';

if ( $ENV{AUTHOR_TEST} ||
    defined $ENV{SPACETRACK_TEST_CACHE} && '' ne $ENV{SPACETRACK_TEST_CACHE} ) {

    my $dump = $ENV{SPACETRACK_TEST_CACHE};
    defined $dump
	or $dump = 0;
    if ( $dump =~ m/ \A 0 (?: x [[:xdigit:]]+ | [0-7]+ ) \z /smx ) {
	$dump =~ oct $dump;
    } elsif ( $dump =~ m/ [^0-7] /smx ) {
	$dump = $st->DUMP_NONE();
    }

    @opt
	or BAIL_OUT 'Cache test requires functional uname()';

    my $want = most_recent_http_response()->content();
    $dump
	and $st->set( dump_headers => $dump );
    is_success $st, qw{ mccants -file }, $temp->filename(), 'mcnames',
	'Get molczan-style magnitudes from cache';
    my $obj_pragmata = $st->{_pragmata};
    $dump
	and $st->set( dump_headers => $st->DUMP_NONE() );

    TODO: {
	local $TODO = 'Flaky server suooprt';

	ok $st->cache_hit(), 'This time content came from cache';
	$st->cache_hit()
	    and diag "Cache hit";
	$st->cache_hit()
	    or eval {
	    diag <<'EOD';
The above cache test seems to fail much more often than not, with the
trace information (available by setting environment variable
SPACETRACK_TEST_CACHE to 0x22) showing that the If-Modified-After header
is in fact set but the server returns 200 anyway.
EOD
	    require YAML;
	    diag 'Response pragmata: ', YAML::Dump( [
		    most_recent_http_response()->header( 'pragma' ) ] );
	    diag 'Object pragmata: ', YAML::Dump( $obj_pragmata );
	    1;
	} or diag 'Pragmata not dumped; can not load YAML';
    }

    is most_recent_http_response()->content(), $want,
	'We got the same result from the cache as from on line';
} else {
    note 'Cache test skipped. Neither AUTHOR_TEST nor SPACETRACK_TEST_CACHE set.';
}

is_success $st, qw{ mccants quicksat }, 'Get quicksat-style magnitudes';

is $st->content_type(), 'quicksat', "Content type is 'quicksat'";

is $st->content_source(), 'mccants', "Content source is 'mccants'";

is_success $st, qw{ mccants rcs }, 'Get McCants-format RCS data';

is $st->content_type(), 'rcs.mccants', "Content type is 'rcs.mccants'";

is $st->content_source(), 'mccants', "Content source is 'mccants'";

is_success $st, qw{ mccants vsnames }, 'Get molczan-style magnitudes for visual satellites';

is $st->content_type(), 'molczan', "Content type is 'molczan'";

is $st->content_source(), 'mccants', "Content source is 'mccants'";

done_testing;

1;

# ex: set textwidth=72 :
