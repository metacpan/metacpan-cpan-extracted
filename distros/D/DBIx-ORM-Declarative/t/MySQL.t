# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More;
BEGIN
{
    require "t/mysqlinfo.pl";
    our $dsn;
    if($dsn)
    {
        plan tests => 21;
    }
    else
    {
        plan skip_all => "See README.MySQL to enable this test";
    }
};
use DBIx::ORM::Declarative;
use DBI;

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

DBIx::ORM::Declarative->import
(
    {
        schema => 'Schema1',
        tables =>
        [
            {
                table               => 'dod_test1',
                primary             => [ 'recid', ],
                select_null_primary => 'SELECT LAST_INSERT_ID()',
                columns =>
                [
                    { name    => 'recid', },
                    { name    => 'name', },
                ],
            },
            {
                table               => 'dod_test2',
                primary             => [ 'recid', ],
                select_null_primary => 'SELECT LAST_INSERT_ID()',
                columns =>
                [
                    { name    => 'recid', },
                    { name    => 'nameid', },
                    { name    => 'value', },
                ],
            },
        ],
        joins =>
        [
            {
                name    => 'Join1',
                primary => 'dod_test2',
                tables =>
                [
                    {
                        table => 'dod_test1',
                        columns =>
                        {
                            nameid => 'recid',
                        },
                    },
                ],
            },
        ],
    },
) ;

my $dbh = DBI->connect($dsn, $user, $pass);
ok($dbh);

die "Can't continue without a database handle\n" unless $dbh;

my $db = new DBIx::ORM::Declarative handle => $dbh;
my $sc = $db->Schema1;

# Add a join programmatically
ok($sc->join(
    name    => 'Join2',
    primary => 'dod_test2',
    tables =>
    [
        {
            table => 'dod_test1',
            columns =>
            {
                nameid => 'recid',
            },
        },
    ],
));

my $i = 1;
my $res = $sc->dod_test1->bulk_create([qw(recid name)],
    map { [($i++, $_)], } qw(Hydrogen Helium Lithium Beryllium Boron Carbon
        Nitrogen Oxygen Flourine Neon Sodium Magnesium Aluminum Silicon
        Phosphorous Sulfur Chlorine Argon Potassium Calcium Scandium
        Titanium Vandium Chromium Manganese Iron Cobalt Nickel Copper
        Zinc Gallium Germanium Arsenic Selenium Bromine Krypton Rubidium
        Strontium Yttrium Zirconium Niobium Molybdenum Technetium Ruthenium
        Rhodium Palladium Silver Cadmium Indium Tin Antimony Tellerium
        Iodine Xenon Cesium Barium Lanthanum Cerium Praseodymium Neodymium
        Promethium Samarium Europium Gadolinium Terbium Dysprosium Holmium
        Erbium Thulium Ytterbium Lutetium Hafnium Tantalum Tungsten Rhenium
        Osmium Iridium Platinum Gold Mercury Thallium Lead Bismuth Polonium
        Astatine Radon Francium Radium Actinium Thorium Protactinium Uranium
        ));

ok($res);

$res = $sc->dod_test1->create(name => 'Neptunium', recid => 93);

ok($res);

{
    # Need to turn off warnings, or they'll muck up the display
    local($SIG{__WARN__}) = sub { };

    $res = $sc->dod_test1->create(name => 'Plutonium', recid => $res->recid);

    ok(not $res);
}

# Give us EVERYTHING...
my @res = $sc->dod_test1->search;

ok(@res > 92);

# Nuke the first one
$res[0]->delete;

$res = $res[0]->commit;

ok($res);

# Get rid of everything but the gold...
$res = $sc->dod_test1->delete([name => ne => 'Gold']);

ok($res);

# Get what we got left
($res) = $sc->dod_test1->search([name => eq => 'Gold']);

ok($res);

# Translate to Latin...
ok($res->name('Aurum'));
ok($res->commit);

# Blow it all away
$res = $sc->dod_test1->delete;

ok($res);

# Get a join
$res = $sc->Join1;

ok($res);

# Store a row

my $row = $res->create(name => 'Bromine', value => 'Liquid');

ok($row);

# Lower the temperature

$row->value('Solid');

ok($row->commit);

ok($row->value eq 'Solid');

# Create more rows to the join
ok($res->create(name => 'Mercury', value => 'Liquid'));
ok($res->create(name => 'Hydrogen', nameid => 1, value => 'Gas'));

# Search via a join
@res = $res->search([name => eq => 'Bromine'], [value => eq => 'Gas']);

ok(@res>1);

# Blow it all away
ok($sc->dod_test1->delete);
ok($sc->dod_test2->delete);
