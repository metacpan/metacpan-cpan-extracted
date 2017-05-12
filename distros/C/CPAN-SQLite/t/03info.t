# $Id: 03info.t 42 2013-06-29 20:44:17Z stro $

use strict;
use warnings;
use Test::More;
use Cwd;
use File::Spec::Functions;
use File::Path;
use CPAN::DistnameInfo;
use FindBin;
use lib "$FindBin::Bin/lib";
use TestSQL qw($mods $auths $dists has_hash_data);
use CPAN::SQLite::Info;

plan tests => 2929;

my $cwd = getcwd;
my $CPAN = catdir $cwd, 't', 'cpan';
my $t_dir = catdir $cwd, 't';

my $db_name = 'cpandb.sql';
my $db_dir = $cwd;
unlink($db_name) if (-e $db_name);

ok (-d $CPAN);
use CPAN::SQLite::Info;
my $info = CPAN::SQLite::Info->new(CPAN => $CPAN, db_dir => $db_dir);
isa_ok($info, 'CPAN::SQLite::Info');

$info->fetch_info();
my $info_dists = $info->{dists};
my $info_mods = $info->{mods};
my $info_auths = $info->{auths};

ok(has_hash_data($info_dists));
ok(has_hash_data($info_mods));
ok(has_hash_data($info_auths));

foreach my $cpanid (keys %$auths) {
  ok(defined $info_auths->{$cpanid});
  foreach (qw(fullname email)) {
    next unless $auths->{$cpanid}->{$_};
    is($info_auths->{$cpanid}->{$_}, $auths->{$cpanid}->{$_});
  }
}

foreach my $dist_name (keys %$dists) {
  ok(defined $info_dists->{$dist_name});
  foreach (qw(dist_vers dist_file dist_abs dist_dslip cpanid)) {
    next unless $dists->{$dist_name}->{$_};
    is($info_dists->{$dist_name}->{$_}, $dists->{$dist_name}->{$_});
  }
  my $modules = $dists->{$dist_name}->{modules};
  if (has_hash_data($modules)) {
    foreach my $key(keys %$modules) {
      ok(exists $info_dists->{$dist_name}->{modules}->{$key});
      next unless $modules->{$key};
      is($info_dists->{$dist_name}->{modules}->{$key}, $modules->{$key});
    }
  }
  my $chapterid = $dists->{$dist_name}->{chapterid};
  if (has_hash_data($chapterid)) {
    foreach my $key(keys %$chapterid) {
      ok(exists $info_dists->{$dist_name}->{chapterid}->{$key});
      foreach my $subchapter (keys %{$chapterid->{$key}}) {
        is($info_dists->{$dist_name}->{chapterid}->{$key}->{$subchapter},
           $chapterid->{$key}->{$subchapter});
      }
    }
  }
}

foreach my $mod_name (keys %$mods) {
  ok(defined $info_mods->{$mod_name});
  foreach (qw(mod_abs chapterid dist_name dslip mod_vers)) {
    next unless $mods->{$mod_name}->{$_};
    is($info_mods->{$mod_name}->{$_}, $mods->{$mod_name}->{$_});
  }
}

ok(not defined $info->{auths}->{ZZZ});
ok(not defined $info->{mods}->{ZZZ});
ok(not defined $info->{dists}->{ZZZ});

my @tables = qw(dists mods auths info);
my $index;
my $package = 'CPAN::SQLite::Index';
foreach my $table(@tables) {
  my $class = $package . '::' . $table;
  my $this = {info => $info->{$table}};
  $index->{$table} = bless $this, $class;
}

use CPAN::SQLite::DBI qw($tables);
my $cdbi = CPAN::SQLite::DBI::Index->new(CPAN => $CPAN,
                                         db_name => $db_name,
                                         db_dir => $db_dir);
isa_ok($cdbi, 'CPAN::SQLite::DBI::Index');

use CPAN::SQLite::Populate;
my $pop = CPAN::SQLite::Populate->new(db_name => $db_name,
                                      db_dir => $db_dir,
                                      setup => 1,
                                      CPAN => $CPAN,
                                      index => $index);
isa_ok($pop, 'CPAN::SQLite::Populate');
$pop->populate();
ok(1);
