use strict;
use warnings;
use utf8;
use Test2::V0;

# `girls` with a team that does not exist dies with the name of that team. The message used to be
# in single quotes, so it said "$team" itself (#7).

use Acme::PrettyCure;

like(
    dies { Acme::PrettyCure->girls('NoSuchTeam') },
    qr/\Acan't find NoSuchTeam at pretty cure at /,
    'the message names the team',
);

ok( lives { Acme::PrettyCure->girls }, 'no team is First' );

done_testing;
