package # no_index
  C2STests;

use Test::More 0.96;
use Try::Tiny 0.09;
use File::Spec::Functions qw( catfile ); # core
use File::Temp 0.19 qw( tempdir );

use Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(
  test_import
);

my $mod = 'App::csv2sqlite';
eval "require $mod" or die $@;

my $dir = tempdir('csv2sqlite.XXXXXX', TMPDIR => 1, CLEANUP => 1);

sub test_import {
  my ($desc, $self) = @_;

  subtest $desc, sub {

    my $db = catfile($dir, 'snacks.sqlite');

    {
      my @csvf = map { catfile(corpus => $_) } @{ $self->{csvs} };
      my $app = $mod->new_from_argv([ @{ $self->{args} || [] }, @csvf, $db ]);

      is_deeply $app->csv_files, [ @csvf ], 'input csv files';
      is $app->dbname, $db, 'last arg is output database';

      while( my ($k, $v) = each %{ $self->{attr} } ){
        is_deeply $app->$k, $v, "attribute $k set";
      }

      try {
        $app->load_tables;
      }
      catch {
        if( $self->{error} ){
          like $_[0], $self->{error}, 'caught expected error';
        }
        else {
          # unexpected; rethrow
          die $_[0];
        }
      };

      # get a fresh handle but use the same attributes
      my $dbh = $app->_build_dbh;

      while( my ($sql, $exp) = each %{ $self->{rs} } ){
        is_deeply
          $dbh->selectall_arrayref($sql),
          $exp,
          'database populated from csv';
      }

    }

    # database handles must be cleaned up before removing the db file
    unlink $db unless $self->{keep_db};
  };
}

1;
