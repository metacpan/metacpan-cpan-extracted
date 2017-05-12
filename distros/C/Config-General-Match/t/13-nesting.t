
use strict;
use warnings;

use Test::More 'no_plan';

use Config::General::Match;

my $conf_text = <<EOF;

    <Site BOOKSHOP>
        the_site = bookshop site
        <Location /admin>
            admin_books = 1
        </Location>
    </Site>

    <Location /admin>
        the_location = /admin
        <Site RECORDSHOP>
            ye_olde_site = recordshop site
            admin_records = 1
        </Site>
    </Location>

EOF

my $conf = Config::General::Match->new(
    -String => $conf_text,
    -MatchSections => [
        {
            -Name        => 'Site',
            -MatchType   => 'exact',
            -SectionType => 'site',
        },
        {
            -Name        => 'Location',
            -MatchType   => 'path',
            -SectionType => 'path',
        },
    ],
);

my $max_depth = 2;

my $config  = $conf->getall_matching_nested(
    $max_depth,
    site => 'RECORDSHOP',
    path => '/admin',
);

ok(! exists $config->{'the_site'},                  '[RECORDSHOP/admin] the_site');
is($config->{'ye_olde_site'},  'recordshop site' ,  '[RECORDSHOP/admin] ye_olde_site');
ok(! exists $config->{'admin_books'},               '[RECORDSHOP/admin] admin_books');
is($config->{'admin_records'}, 1,                   '[RECORDSHOP/admin] admin_records');
is($config->{'the_location'},  '/admin',            '[RECORDSHOP/admin] the_location');

$config  = $conf->getall_matching_nested(
    $max_depth,
    site => 'BOOKSHOP',
    path => '/admin',
);

is($config->{'the_site'},      'bookshop site',     '[BOOKSHOP/admin] the_site');
ok(! exists $config->{'ye_olde_site'},              '[BOOKSHOP/admin] ye_olde_site');
is($config->{'admin_books'},   1,                   '[BOOKSHOP/admin] admin_books');
ok(! exists $config->{'admin_records'},             '[BOOKSHOP/admin] admin_records');
is($config->{'the_location'},  '/admin',            '[BOOKSHOP/admin] the_location');


$config  = $conf->getall_matching_nested(
    $max_depth,
    site => 'CHEESESHOP',
    path => '/admin',
);

ok(! exists $config->{'the_site'},                  '[CHEESESHOP/admin] the_site');
ok(! exists $config->{'ye_olde_site'},              '[CHEESESHOP/admin] ye_olde_site');
ok(! exists $config->{'admin_books'},               '[CHEESESHOP/admin] admin_books');
ok(! exists $config->{'admin_records'},             '[CHEESESHOP/admin] admin_records');
is($config->{'the_location'},  '/admin',            '[CHEESESHOP/admin] the_location');


$config  = $conf->getall_matching_nested(
    $max_depth,
    site => 'CHEESESHOP',
    path => '/adminy',
);

ok(! exists $config->{'the_site'},                  '[CHEESESHOP/adminy] the_site');
ok(! exists $config->{'ye_olde_site'},              '[CHEESESHOP/adminy] ye_olde_site');
ok(! exists $config->{'admin_books'},               '[CHEESESHOP/adminy] admin_books');
ok(! exists $config->{'admin_records'},             '[CHEESESHOP/adminy] admin_records');
ok(! exists $config->{'the_location'},              '[CHEESESHOP/adminy] the_location');


$config  = $conf->getall_matching_nested(
    $max_depth,
    site => 'RECORDSHOP',
    path => '/adminy',
);

ok(! exists $config->{'the_site'},                  '[RECORDSHOP/adminy] the_site');
ok(! exists $config->{'ye_olde_site'},              '[RECORDSHOP/adminy] ye_olde_site');
ok(! exists $config->{'admin_books'},               '[RECORDSHOP/adminy] admin_books');
ok(! exists $config->{'admin_records'},             '[RECORDSHOP/adminy] admin_records');
ok(! exists $config->{'the_location'},              '[RECORDSHOP/adminy] the_location');


$config  = $conf->getall_matching_nested(
    $max_depth,
    site => 'BOOKSHOP',
    path => '/adminy',
);

is($config->{'the_site'},      'bookshop site',     '[BOOKSHOP/admin] the_site');
ok(! exists $config->{'ye_olde_site'},              '[BOOKSHOP/adminy] ye_olde_site');
ok(! exists $config->{'admin_books'},               '[BOOKSHOP/adminy] admin_books');
ok(! exists $config->{'admin_records'},             '[BOOKSHOP/adminy] admin_records');
ok(! exists $config->{'the_location'},              '[BOOKSHOP/adminy] the_location');
