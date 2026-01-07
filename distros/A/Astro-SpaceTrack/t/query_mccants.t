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
$skip = site_check( 'mike.mccants' )
    and plan skip_all => $skip;

my $st = Astro::SpaceTrack->new();

SKIP: {
    is_success_or_skip( $st, qw{ mccants classified },
	'Get classified elements', 2 );

    is $st->content_type(), 'orbit', "Content type is 'orbit'";

    is $st->content_source(), 'mccants', "Content source is 'mccants'";
}

SKIP: {
    is_success_or_skip( $st, qw{ mccants integrated },
	'Get integrated elements', 2 );

    is $st->content_type(), 'orbit', "Content type is 'orbit'";

    is $st->content_source(), 'mccants', "Content source is 'mccants'";
}

SKIP: {
    local $TODO = '404 2024-04-27';

    is_success_or_skip( $st, qw{ mccants rcs }, 'Get McCants-format RCS data', 2 );

    is $st->content_type(), 'rcs.mccants', "Content type is 'rcs.mccants'";

    is $st->content_source(), 'mccants', "Content source is 'mccants'";
}

done_testing;

1;

__END__

# ex: set filetype=perl textwidth=72 :
