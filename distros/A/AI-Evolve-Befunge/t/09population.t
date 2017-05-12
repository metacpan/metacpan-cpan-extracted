#!/usr/bin/perl
use strict;
use warnings;

use Cwd;
use File::Temp qw(tempdir);
use Test::More;
use Test::Exception;
use Test::MockRandom {
    rand => [qw(AI::Evolve::Befunge::Population Algorithm::Evolutionary::Wheel)],
    srand => { main => 'seed' },
    oneish => [qw(main)]
};

BEGIN { $ENV{AIEVOLVEBEFUNGE} = 't/testconfig.conf'; };

use aliased 'AI::Evolve::Befunge::Population' => 'Population';
use aliased 'AI::Evolve::Befunge::Blueprint'  => 'Blueprint';
use AI::Evolve::Befunge::Util;

push_quiet(1);

my $num_tests;
BEGIN { $num_tests = 0; };
plan tests => $num_tests;


# constructor
$ENV{HOST} = 'test';
my $population;
lives_ok(sub { $population = Population->new() }, 'defaults work');
is($population->physics->name, 'ttt' , 'default physics used');
is($population->popsize , 40         , 'default popsize used');
set_popid(1);
$population = Population->new(Host => 'host');
my $population2 = Population->new(Host => 'phost');
is(ref($population), 'AI::Evolve::Befunge::Population', 'ref to right class');
is($population2->popsize,   8, 'popsize passed through correctly');
is(ref($population->physics),  'AI::Evolve::Befunge::Physics::ttt',
                               'physics created properly');
is(ref($population2->physics), 'AI::Evolve::Befunge::Physics::test',
                               'physics created properly');
is($population->dimensions, 4, 'correct dimensions');
is($population->generation, 1, 'default generation');
BEGIN { $num_tests += 9 };


# default blueprints
my $listref = $population->blueprints;
is(scalar @$listref, 10, 'default blueprints created');
foreach my $i (0..7) {
    my $individual = $$listref[$i];
    my $code = $individual->code;
    is(index($code, "\0"), -1, "new_code_fragment contains no nulls");
    is(length($code), 256, "newly created blueprints have right code size");
}
BEGIN { $num_tests += 17 };


# new_code_fragment
seed(0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
my $code = $population->new_code_fragment(10, 0);
is(index($code, "\0"), -1, "new_code_fragment contains no nulls");
is(length($code), 10, "new_code_fragment obeys length parameter");
is($code, ' 'x10, 'prob=0 means I get a blank line');
seed(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
$code = $population->new_code_fragment(10, 100);
is(index($code, "\0"), -1, "new_code_fragment contains no nulls");
is(length($code), 10, "new_code_fragment obeys length parameter");
is($code, '0'x10, 'prob=100 means I get a line of code');
seed(oneish, oneish, oneish, oneish, oneish, oneish, oneish, oneish);
is($population->new_code_fragment( 4, 120), 'TTTT', 'Physics-specific commands are generated');
seed(oneish, oneish, oneish, oneish, oneish, oneish, oneish, oneish);
is($population2->new_code_fragment(4, 120), "''''", 'No Physics-specific commands are generated when the Physics has none.');
dies_ok(sub { AI::Evolve::Befunge::Population::new_code_fragment(1) }, "no self ptr");
dies_ok(sub { $population->new_code_fragment()  }, "no length");
dies_ok(sub { $population->new_code_fragment(5) }, "no density");
BEGIN { $num_tests += 11 };


# mutate
my $blank = Blueprint->new( code => " "x256, dimensions => 4, id => -10 );
seed(0.3,0,0,0,0,0,0,0);
$population->mutate($blank);
is($blank->code, " "x64 . "0"x192, 'big mutate');
$blank->code(" "x256);
seed(0,0,0,0,oneish,oneish,oneish,oneish);
$population->mutate($blank);
is($$blank{code}, '0' . (' 'x255), 'small mutate');
is(index($blank->code, "\0"), -1, "mutate() does not create nulls");
BEGIN { $num_tests += 3 };


# crossover
my $chromosome1 = Blueprint->new( code => "1"x256, dimensions => 4, id => -11 );
my $chromosome2 = Blueprint->new( code => "2"x256, dimensions => 4, id => -12 );
my $chromosome3 = Blueprint->new( code => "3"x16 , dimensions => 4, id => -13 );
my $chromosome4 = Blueprint->new( code => "4"x16 , dimensions => 4, id => -14 );
seed(0.3,0,0,0,0,0,0,0);
$population->crossover($chromosome1, $chromosome2);
is($$chromosome1{code}, "1"x64 . "2"x192, 'big crossover 1');
is($$chromosome2{code}, "2"x64 . "1"x192, 'big crossover 2');
$chromosome1 = Blueprint->new( code => "1"x256, dimensions => 4, id => -13 );
$chromosome2 = Blueprint->new( code => "2"x256, dimensions => 4, id => -14 );
seed(0,0,0,0,oneish,oneish,oneish,oneish);
$population->crossover($chromosome1, $chromosome2);
is($$chromosome1{code}, "2" . "1"x255, 'small crossover 1');
is($$chromosome2{code}, "1" . "2"x255, 'small crossover 2');
seed(0,0,0,0,oneish,oneish,oneish,oneish);
$population->crossover($chromosome1, $chromosome3);
is(length($chromosome3->code), 256, 'crossover upgrades size');
is(length($chromosome1->code), 256, 'crossover does not upgrade bigger blueprint');
seed(0,0,0,0,oneish,oneish,oneish,oneish);
$population->crossover($chromosome4, $chromosome2);
is(length($chromosome4->code), 256, 'crossover upgrades size');
is(length($chromosome2->code), 256, 'crossover does not upgrade bigger blueprint');
BEGIN { $num_tests += 8 };

# grow
$chromosome3 = Blueprint->new( code => "3"x16 , dimensions => 4, id => -13 );
seed(0);
my $chromosome5 = $population->grow($chromosome3);
is($chromosome3->size, '(2,2,2,2)', 'verify original size');
is($chromosome5->size, '(3,3,3,3)', 'verify new size');
is($chromosome5->code, 
     '33 '.'33 '.'   '
    .'33 '.'33 '.'   '
    .'   '.'   '.'   '
    .'33 '.'33 '.'   '
    .'33 '.'33 '.'   '
    .'   '.'   '.'   '
    .'   '.'   '.'   '
    .'   '.'   '.'   '
    .'   '.'   '.'   ',
    'verify code looks right');
BEGIN { $num_tests += 3 };


# crop
$chromosome3 = Blueprint->new( code => 
    "334334555334334555555555555334334555334334555555555555555555555555555555555555555",
    dimensions => 4, id => -13 );
$chromosome4 = Blueprint->new( code =>
    "3334333433344444333433343334444433343334333444444445444544455555",
    dimensions => 3, id => -14 );
seed(0, 0, 0, 0, 0);
seed(0, 0, 0, 0);
$chromosome5    = $population->crop($chromosome3);
my $chromosome6 = $population->crop($chromosome4);
is($chromosome3->size, '(3,3,3,3)', 'verify original size');
is($chromosome5->size, '(3,3,3,3)', 'verify same size');
is($chromosome4->size, '(4,4,4)', 'verify original size');
is($chromosome6->size, '(3,3,3)', 'verify new size');
is($chromosome6->code, '3'x27, "crop at zero offset");
seed(0, oneish, oneish, oneish, oneish, 0, oneish, oneish, oneish);
$chromosome6 = $population->crop($chromosome4);
is($chromosome4->size, '(4,4,4)', 'verify original size');
is($chromosome6->size, '(3,3,3)', 'verify new size');
is($chromosome6->code, '334334444334334444445445555', "crop at nonzero offset");
BEGIN { $num_tests += 8 };


# fight
# we're executing in a 4-dimensional space, so code size must be one of:
# 1**4 = 1
# 2**4 = 16
# 3**4 = 81
# 4**4 = 256
# 5**4 = 625
# and so forth.
my $quit1    = "q";
my $concede1 = "z";
my $dier1    = "0k" . ' 'x14;
# the following critters require 5 characters per line, thus they operate in a
# 5**4 space.
# will try (1,1), then (2,0), then (0,2)
my $scorer1 = "[   @]02M^]20M^]11M^" . (' 'x605);
# will try (2,0), then (2,1), then (2,2)
my $scorer2 = "[   @]22M^]21M^]20M^" . (' 'x605);
my $scorer3 = "[@  <]02M^]20M^]11M^" . (' 'x605);
my $popid = -10;
my @population = map { Blueprint->new( code => $_, dimensions => 4, id => $popid++, host => 'test' ) }
    ($quit1,$quit1,$concede1,$concede1,$dier1,$dier1,$scorer3,$scorer1,$scorer2, $scorer2);
$population[3]{host} = 'not_test';
$population[6]{host} = 'not_test1';
$population[7]{host} = 'not_test2';
$population[8]{host} = 'not_test';
seed(0.3, 0, 0.7, oneish);
$population->blueprints([@population]);
$population->fight();
@population = @{$population->blueprints};
is(scalar @population, 3, 'population reduced to 25% of its original size');
BEGIN { $num_tests += 1 };
my @expected_results = (
    {id => -4,  code => $scorer3,  fitness =>  3, host => 'not_test1'},
    {id => -2,  code => $scorer2,  fitness =>  2, host => 'not_test'},
    {id => -10, code => $quit1,    fitness =>  1, host => 'test'},
);
my $ref = $population->blueprints;
for my $id (0..@expected_results-1) {
    is($$ref[$id]{id},      $expected_results[$id]{id},      "sorted $id id right");
    is($$ref[$id]{fitness}, $expected_results[$id]{fitness}, "sorted $id fitness right");
    is($$ref[$id]{host},    $expected_results[$id]{host},    "sorted $id host right");
    is($$ref[$id]{code},    $expected_results[$id]{code},    "sorted $id code right");
}
BEGIN { $num_tests += 4*3 };


# pair
seed(oneish, oneish);
my ($c1, $c2) = $population->pair(map { $$_{fitness} } (@population));
is($$c1{id}, $population[2]{id}, "pair bias works");
is($$c2{id}, $population[0]{id}, "pair bias works");
seed(0, 0);
($c1, $c2) = $population->pair(map { $$_{fitness} } (@population));
is($$c1{id}, $population[0]{id}, "pair bias works");
is($$c2{id}, $population[1]{id}, "pair bias works");
BEGIN { $num_tests += 4 };


# save
my $goodfile = IO::File->new('t/savefile');
my $subdir = tempdir(CLEANUP => 1);
my $olddir = getcwd();
chdir($subdir);
$population->generation(0);
$population->cleanup_intermediate_savefiles();
$population->generation(999);
$population->save();
ok(-d 'results-host', 'results subdir has been created');
ok(-f 'results-host/host-ttt-999', 'filename is correct');
$population->generation(1000);
$population->save();
ok(!-f 'results-host/host-ttt-999', 'old filename is removed');
ok(-f 'results-host/host-ttt-1000', 'new filename is still there');
my $testfile = IO::File->new(<results-host/*>);
{
    local $/ = undef;
    my $gooddata = <$goodfile>;
    my $testdata = <$testfile>;
    is($testdata, $gooddata, 'savefile contents match up');
    undef $goodfile;
    undef $testfile;
}
chdir($olddir);
BEGIN { $num_tests += 5 };


# config
$population->generation(999);
is($population->config->config('basic_value'), 42, 'global config works');
$population->generation(1000);
is($population->config->config('basic_value'), 67, 'config overrides work');
BEGIN { $num_tests += 2 };


# breed
seed(map { oneish, 0.3, 0, 0.7, oneish, 0.5, 0.2, 0.1, 0.1, oneish, 0.4, 0, 0, 0, 0, 0 } (1..1000));
$population->breed();
@population = @{$population->blueprints};
my %accepted_sizes = (1 => 1, 256 => 1, 625 => 1, 1296 => 1);
for my $blueprint (@population) {
    ok(exists($accepted_sizes{length($blueprint->code)}), "new code has reasonable length ".length($blueprint->code));
}
BEGIN { $num_tests += 10 };


# new
$ref = ['abcdefghijklmnop'];
$population = Population->new(Host => 'whee', Generation => 20, Blueprints => $ref);
$ref = $population->blueprints;
is($population->physics->name,   'othello',
                                 'population->new sets physics right');
is($population->popsize,     5,  'population->new sets popsize right');
is($population->generation,  20, 'population->new sets generation right');
is($$ref[0]->code, 'abcdefghijklmnop', 'population->new sets blueprints right');
is($population->host,    'whee', 'population sets host right');
BEGIN { $num_tests += 5 };


# load
dies_ok(sub { Population->load('nonexistent_file') }, 'nonexistent file');
dies_ok(sub { Population->load('Build.PL') }, 'invalid file');
$population = Population->load('t/savefile');
is($population->physics->name,  'ttt', '$population->load gets physics right');
is($population->generation,      1001, '$population->load gets generation right');
is(new_popid(),                    23, '$population->load gets popid right');
$ref = $population->blueprints;
is(scalar @$ref, 3, '$population->load returned the right number of blueprints');
BEGIN { $num_tests += 6 };
@expected_results = (
    {id => -4,  code => $scorer3,  fitness =>  3, host => 'not_test1'},
    {id => -2,  code => $scorer2,  fitness =>  2, host => 'not_test'},
    {id => -10, code => $quit1,    fitness =>  1, host => 'test'},
);
for my $id (0..@expected_results-1) {
    is($$ref[$id]{id},      $expected_results[$id]{id},      "loaded $id id right");
    is($$ref[$id]{host},    $expected_results[$id]{host},    "loaded $id host right");
    is($$ref[$id]{code},    $expected_results[$id]{code},    "loaded $id code right");
    is($$ref[$id]{fitness}, $expected_results[$id]{fitness}, "loaded $id fitness right");
}
BEGIN { $num_tests += 4*3 };


package AI::Evolve::Befunge::Physics::test;
use strict;
use warnings;
use Carp;

# this is a boring, non-game physics engine.  Not much to see here.

use AI::Evolve::Befunge::Util;
use base 'AI::Evolve::Befunge::Physics';
use AI::Evolve::Befunge::Physics  qw(register_physics);

sub new {
    my $package = shift;
    return bless({}, $package);
}

sub get_token { return ord('-'); }

sub decorate_valid_moves { return 0; }
sub valid_move           { return 0; }
sub won                  { return 0; }
sub over                 { return 0; }
sub score                { return 0; }
sub can_pass             { return 0; }
sub make_move            { return 0; }
sub setup_board          { return 0; }

BEGIN { register_physics(
        name => "test",
);};
