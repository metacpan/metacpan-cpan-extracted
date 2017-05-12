use strict;
use warnings;
use Test::More 0.96;
use File::Spec::Functions qw( catfile ); # core
use File::Temp 0.19 qw( tempdir );
use DBI;

# Ensure the script runs.

my $script_dir = (grep { /blib.lib/ } @INC)
  ? [qw( blib script )]
  : ['bin'];

my $script = catfile(@$script_dir, 'csv2sqlite');
my $dir    = tempdir('csv2sqlite.XXXXXX', TMPDIR => 1, CLEANUP => 1);

sub run_app (@) {
  my @args = ($^X, $script, @_);
  note join ' ', @args;
  system @args;
}

sub test_run {
  my ($db, $files, $rs) = @_;
  $db  = catfile($dir, $db);

  run_app @$files, $db;
  is $?, 0, 'script executed successfully'
    or diag $!;

  my $dbh = DBI->connect("dbi:SQLite:dbname=$db");

  while( my ($sql, $exp) = each %$rs ){
    is_deeply $dbh->selectall_arrayref($sql), $exp, 'database populated';
  }
}

test_run(
  'snacks.sqlite',
  [map { catfile(corpus => $_) } qw( chips.csv pretzels.csv )],
  {
    'SELECT flavor, size FROM chips ORDER BY flavor DESC' => [
      ['spicy', 'medium'],
      ['plain', 'large'],
      ['bbq', ' small'],
    ],
  },
);

done_testing;
