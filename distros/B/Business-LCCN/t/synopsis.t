#!perl

use Test::More;
use strict;
use warnings;

plan tests => 17;
use_ok('Business::LCCN') || BAIL_OUT('Could not load Business::LCCN');

my $lccn = Business::LCCN->new('he 68001993 /HE/r692');
ok($lccn);

is( $lccn->prefix,         'he',                   'Prefix ' );
is( $lccn->prefix_encoded, 'he ',                  'Prefix field ' );
is( $lccn->year_cataloged, 1968,                   'Year cataloged ' );
is( $lccn->year_encoded,   '68',                   'Year field ' );
is( $lccn->serial,         '001993',               'Serial ' );
is( $lccn->canonical,      'he 68001993 /HE/r692', 'Canonical ' );
is( $lccn->normalized,     'he68001993',           'Normalized ' );
is( $lccn->info_uri,       'info:lccn/he68001993', 'Info URI ' );
is( $lccn->permalink, 'http://lccn.loc.gov/he68001993', 'Permalink' );
is( $lccn->lccn_structure, 'A', 'LCCN Type ' );
is( $lccn->suffix_encoded,        '/HE', 'Suffix field ' );
is( $lccn->revision_year,         1969,  'Revision year' );
is( $lccn->revision_year_encoded, '69',  'Revision year encoded' );
is( $lccn->revision_number,       2,     'Revision number' );
is_deeply( $lccn->suffix_alphabetic_identifiers, ['HE'], 'Suffix parts' );

# Local Variables:
# mode: perltidy
# End:
