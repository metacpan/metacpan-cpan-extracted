use strict;
use warnings;
use Module::CoreList::DBSchema;
use Test::More;

my $mcdbs = Module::CoreList::DBSchema->new();
my %cl_tabs = $mcdbs->tables;
my $cl_tabs = {};

while( my ($tab,$fields) = each %cl_tabs ) {
  my $tmp = 'tmp_' . $tab;
  foreach my $foo ( $tab, $tmp ) {
    $cl_tabs->{$foo} = 'CREATE TABLE IF NOT EXISTS ' . $foo . ' ( ' .
                       join(', ', @{ $fields } ) . ' )';
  }
}

my $tests = {
  auths => 'CREATE TABLE IF NOT EXISTS auths ( cpan_id VARCHAR(20) NOT NULL, fullname VARCHAR(255) NOT NULL, email TEXT )',
  dists => 'CREATE TABLE IF NOT EXISTS dists ( dist_name VARCHAR(190) NOT NULL, cpan_id VARCHAR(20) NOT NULL, dist_file VARCHAR(400) NOT NULL, dist_vers VARCHAR(50) )',
  mirrors => 'CREATE TABLE IF NOT EXISTS mirrors ( hostname VARCHAR(50) NOT NULL, dst_bandwidth VARCHAR(50), dst_contact VARCHAR(60), dst_ftp VARCHAR(250), dst_http VARCHAR(250), dst_location TEXT, dst_notes TEXT, dst_organisation TEXT, dst_rsync VARCHAR(250), dst_src VARCHAR(250), dst_timezone VARCHAR(20), frequency VARCHAR(100) )',
  mods => 'CREATE TABLE IF NOT EXISTS mods ( mod_name VARCHAR(300) NOT NULL, dist_name VARCHAR(190) NOT NULL, dist_vers VARCHAR(50), cpan_id VARCHAR(20) NOT NULL, mod_vers VARCHAR(30) )',
  perms => 'CREATE TABLE IF NOT EXISTS perms ( mod_name VARCHAR(300) NOT NULL, cpan_id VARCHAR(20) NOT NULL, perm VARCHAR(20) )',
  timestamp => 'CREATE TABLE IF NOT EXISTS timestamp ( timestamp VARCHAR(30) NOT NULL, lastupdated VARCHAR(30) NOT NULL )',
  tmp_auths => 'CREATE TABLE IF NOT EXISTS tmp_auths ( cpan_id VARCHAR(20) NOT NULL, fullname VARCHAR(255) NOT NULL, email TEXT )',
  tmp_dists => 'CREATE TABLE IF NOT EXISTS tmp_dists ( dist_name VARCHAR(190) NOT NULL, cpan_id VARCHAR(20) NOT NULL, dist_file VARCHAR(400) NOT NULL, dist_vers VARCHAR(50) )',
  tmp_mirrors => 'CREATE TABLE IF NOT EXISTS tmp_mirrors ( hostname VARCHAR(50) NOT NULL, dst_bandwidth VARCHAR(50), dst_contact VARCHAR(60), dst_ftp VARCHAR(250), dst_http VARCHAR(250), dst_location TEXT, dst_notes TEXT, dst_organisation TEXT, dst_rsync VARCHAR(250), dst_src VARCHAR(250), dst_timezone VARCHAR(20), frequency VARCHAR(100) )',
  tmp_mods => 'CREATE TABLE IF NOT EXISTS tmp_mods ( mod_name VARCHAR(300) NOT NULL, dist_name VARCHAR(190) NOT NULL, dist_vers VARCHAR(50), cpan_id VARCHAR(20) NOT NULL, mod_vers VARCHAR(30) )',
  tmp_perms => 'CREATE TABLE IF NOT EXISTS tmp_perms ( mod_name VARCHAR(300) NOT NULL, cpan_id VARCHAR(20) NOT NULL, perm VARCHAR(20) )',
  %{ $cl_tabs },
};

plan tests => 2 + ( scalar keys %$tests );

use_ok('App::CPANIDX::Tables');

my @origs = sort keys %$tests;
my @types = sort App::CPANIDX::Tables->tables();

is_deeply( \@origs, \@types, 'We got the right tables back' );

foreach my $table ( sort keys %$tests ) {
  my $sql = App::CPANIDX::Tables->table( $table );
  is( $sql, $tests->{$table}, qq{SQL for '$table' is correct} );
}
