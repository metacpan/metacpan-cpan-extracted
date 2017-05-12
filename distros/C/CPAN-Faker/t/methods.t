use strict;
use warnings;

use Test::More;

if (eval "use CPAN::SQLite; 1") {
  plan 'no_plan';
} else {
  plan skip_all => "CPAN::SQLite required to read index";
}

use CPAN::Faker;
use File::Temp ();

my $tmpdir = File::Temp::tempdir(CLEANUP => 1);

my $faker = CPAN::Faker->new({
  source => 'eg',
  dest   => $tmpdir,
});

$faker->index_package('My::Fake' => {
  version => '1.00',
  dist_version  => '1.00',
  dist_filename => 'L/LO/LOCAL/My-Fake-1.00.tar.gz',
  dist_author   => 'LOCAL',
});

$faker->make_cpan;

my $cpan = CPAN::SQLite->new(
  CPAN   => $tmpdir,
  db_dir => $tmpdir,
);

$cpan->index(setup => 1);

$cpan->query(
  mode => 'module',
  name => 'My::Fake',
);

my $result = $cpan->{results};

is($result->{mod_name}, 'My::Fake');
is($result->{dist_name}, 'My-Fake');
is($result->{dist_file}, 'My-Fake-1.00.tar.gz');
