
use strict;
use warnings;

my $Per_Driver_Tests = 30;
use Test::More 'tests' => 90;

use Config::Context;

my %Config_Text;

$Config_Text{'ConfigGeneral'} = <<'EOF';

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

$Config_Text{'ConfigScoped'} = <<'EOF';

    Site BOOKSHOP {
        the_site = 'bookshop site'
        Location = {
            /admin = {
                admin_books = 1
            }
        }
    }

    Location /admin {
        the_location = /admin
        Site = {
            RECORDSHOP = {
                ye_olde_site = 'recordshop site'
                admin_records = 1
            }
        }
    }

EOF

$Config_Text{'XMLSimple'} = <<'EOF';
<opt>
    <Site name="BOOKSHOP">
        <the_site>bookshop site</the_site>
        <Location name="/admin">
            <admin_books>1</admin_books>
        </Location>
    </Site>

    <Location name="/admin">
        <the_location>/admin</the_location>
        <Site name="RECORDSHOP">
            <ye_olde_site>recordshop site</ye_olde_site>
            <admin_records>1</admin_records>
        </Site>
    </Location>
   </opt>

EOF

sub runtests {
    my $driver = shift;

    my $conf = Config::Context->new(
        driver => $driver,
        string => $Config_Text{$driver},
        match_sections => [
            {
                name         => 'Site',
                match_type   => 'exact',
                section_type => 'site',
            },
            {
                name         => 'Location',
                match_type   => 'path',
                section_type => 'path',
            },
        ],
    );

    $conf->nesting_depth(2);

    my $config  = $conf->context(
        site => 'RECORDSHOP',
        path => '/admin',
    );

    ok(! exists $config->{'the_site'},                  "$driver: [RECORDSHOP/admin] the_site");
    is($config->{'ye_olde_site'},  'recordshop site' ,  "$driver: [RECORDSHOP/admin] ye_olde_site");
    ok(! exists $config->{'admin_books'},               "$driver: [RECORDSHOP/admin] admin_books");
    is($config->{'admin_records'}, 1,                   "$driver: [RECORDSHOP/admin] admin_records");
    is($config->{'the_location'},  '/admin',            "$driver: [RECORDSHOP/admin] the_location");

    $config  = $conf->context(
        site => 'BOOKSHOP',
        path => '/admin',
    );

    is($config->{'the_site'},      'bookshop site',     "$driver: [BOOKSHOP/admin] the_site");
    ok(! exists $config->{'ye_olde_site'},              "$driver: [BOOKSHOP/admin] ye_olde_site");
    is($config->{'admin_books'},   1,                   "$driver: [BOOKSHOP/admin] admin_books");
    ok(! exists $config->{'admin_records'},             "$driver: [BOOKSHOP/admin] admin_records");
    is($config->{'the_location'},  '/admin',            "$driver: [BOOKSHOP/admin] the_location");


    $config  = $conf->context(
        site => 'CHEESESHOP',
        path => '/admin',
    );

    ok(! exists $config->{'the_site'},                  "$driver: [CHEESESHOP/admin] the_site");
    ok(! exists $config->{'ye_olde_site'},              "$driver: [CHEESESHOP/admin] ye_olde_site");
    ok(! exists $config->{'admin_books'},               "$driver: [CHEESESHOP/admin] admin_books");
    ok(! exists $config->{'admin_records'},             "$driver: [CHEESESHOP/admin] admin_records");
    is($config->{'the_location'},  '/admin',            "$driver: [CHEESESHOP/admin] the_location");


    $config  = $conf->context(
        site => 'CHEESESHOP',
        path => '/adminy',
    );

    ok(! exists $config->{'the_site'},                  "$driver: [CHEESESHOP/adminy] the_site");
    ok(! exists $config->{'ye_olde_site'},              "$driver: [CHEESESHOP/adminy] ye_olde_site");
    ok(! exists $config->{'admin_books'},               "$driver: [CHEESESHOP/adminy] admin_books");
    ok(! exists $config->{'admin_records'},             "$driver: [CHEESESHOP/adminy] admin_records");
    ok(! exists $config->{'the_location'},              "$driver: [CHEESESHOP/adminy] the_location");


    $config  = $conf->context(
        site => 'RECORDSHOP',
        path => '/adminy',
    );

    ok(! exists $config->{'the_site'},                  "$driver: [RECORDSHOP/adminy] the_site");
    ok(! exists $config->{'ye_olde_site'},              "$driver: [RECORDSHOP/adminy] ye_olde_site");
    ok(! exists $config->{'admin_books'},               "$driver: [RECORDSHOP/adminy] admin_books");
    ok(! exists $config->{'admin_records'},             "$driver: [RECORDSHOP/adminy] admin_records");
    ok(! exists $config->{'the_location'},              "$driver: [RECORDSHOP/adminy] the_location");


    $config  = $conf->context(
        site => 'BOOKSHOP',
        path => '/adminy',
    );

    is($config->{'the_site'},      'bookshop site',     "$driver: [BOOKSHOP/admin] the_site");
    ok(! exists $config->{'ye_olde_site'},              "$driver: [BOOKSHOP/adminy] ye_olde_site");
    ok(! exists $config->{'admin_books'},               "$driver: [BOOKSHOP/adminy] admin_books");
    ok(! exists $config->{'admin_records'},             "$driver: [BOOKSHOP/adminy] admin_records");
    ok(! exists $config->{'the_location'},              "$driver: [BOOKSHOP/adminy] the_location");
}

SKIP: {
    if (test_driver_prereqs('ConfigGeneral')) {
        runtests('ConfigGeneral');
    }
    else {
        skip "Config::General not installed", $Per_Driver_Tests;
    }
}
SKIP: {
    if (test_driver_prereqs('ConfigScoped')) {
        runtests('ConfigScoped');
    }
    else {
        skip "Config::Scoped not installed", $Per_Driver_Tests;
    }
}
SKIP: {
    if (test_driver_prereqs('XMLSimple')) {
        runtests('XMLSimple');
    }
    else {
        skip "XML::Simple, XML::SAX or XML::Filter::XInclude not installed", $Per_Driver_Tests;
    }
}

sub test_driver_prereqs {
    my $driver = shift;
    my $driver_module = 'Config::Context::' . $driver;
    eval "require $driver_module;";
    die $@ if $@;

    eval "require $driver_module;";
    my @required_modules = $driver_module->config_modules;

    foreach (@required_modules) {
        eval "require $_;";
        if ($@) {
            return;
        }
    }
    return 1;

}
