use strict;
use warnings;
use Test::More;
use Module::CoreList::DBSchema;
use App::CPANIDX::Queries;

my $mcdbs = Module::CoreList::DBSchema->new();

my %tests = (
  'mod' => [ 'select mods.mod_name,mods.mod_vers,mods.cpan_id,dists.dist_name,dists.dist_vers,dists.dist_file from mods,dists where mod_name = ? and mods.dist_name = dists.dist_name and mods.dist_vers = dists.dist_vers', 1 ],
  'dist' => [ 'select * from dists where dist_name = ?', 1 ],
  'auth' => [ 'select * from auths where cpan_id = ?', 1 ],
  'dists' => [ 'select * from dists where cpan_id = ?', 1 ],
  'perms' => [ 'select * from perms where mod_name = ?', 1 ],
  'timestamp' => [ 'select * from timestamp', 0 ],
  'firstmod' => [ 'select mod_name from mods order by mod_name limit 1', 0 ],
  'nextmod' => [ 'select mod_name from mods order by mod_name limit ?,1', 1 ],
  'firstauth' => [ 'select cpan_id from auths order by cpan_id limit 1', 0 ],
  'nextauth' => [ 'select cpan_id from auths order by cpan_id limit ?,1', 1 ],
  'modkeys'  => [ 'select mod_name from mods order by mod_name', 0 ],
  'authkeys' => [ 'select cpan_id from auths order by cpan_id', 0 ],
  'topten' => [ 'select cpan_id, count(*) as "dists" from dists group by cpan_id order by count(*) desc limit 10', 0 ],
  'mirrors' => [ 'select * from mirrors', 0 ],
);

$tests{$_} = $mcdbs->query( $_ ) for $mcdbs->queries();

plan tests => ( scalar keys %tests ) * 4 + 1;

my @origs = sort keys %tests;
my @types = sort App::CPANIDX::Queries->queries();

is_deeply( \@origs, \@types, 'We got the right types back' );

foreach my $test ( sort keys %tests ) {
  my ($tsql,$tflag) = @{ $tests{$test} };
  my ($sql,$flag) = App::CPANIDX::Queries->query($test);
  my $aref = App::CPANIDX::Queries->query($test);
  is( $sql, $tsql, "The SQL was okay for '$test'" );
  is( $flag, $tflag, "The flag was okay for '$test'");
  is( $aref->[0], $tsql, "The SQL was okay for '$test'" );
  is( $aref->[1], $tflag, "The flag was okay for '$test'");
}
