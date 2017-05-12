use strict;
use Test::More;
use DBIx::Schema::Annotate;
use t::Utils;
use Encode;
use IO::All;
use File::Path qw/make_path/;
use File::Temp qw/ tempdir /;

my $dbh = t::Utils->setup_dbh;
my $annotate = DBIx::Schema::Annotate->new( dbh => $dbh );


subtest 'get ddl with sql1' => sub {
    my $sql1 =<<END;
CREATE TABLE mock_basic (
  id   integer,
  名前 text,
  desc text,
  primary key ( id )
)
END
    chomp($sql1);
    my $sql1_index = 'CREATE INDEX test_index on mock_basic(名前)';
    my $sql1_index2 = 'CREATE INDEX test_index2 on mock_basic(desc)';
    $dbh->do($sql1);
    $dbh->do($sql1_index);
    $dbh->do($sql1_index2);
    is($annotate->get_table_ddl( table_name => 'mock_basic' ), join("\n", $sql1, $sql1_index,$sql1_index2));
};

subtest 'get ddl with sql2' => sub {
    my $sql2 =<<END;
CREATE TABLE mock_basic2 (
  id   integer,
  name2 text,
  primary key ( id )
)
END
    chomp($sql2);
    $dbh->do($sql2);
    is($annotate->get_table_ddl( table_name => 'mock_basic2' ), $sql2);
};

subtest 'write files' => sub {
    my $src = io->catfile(qw/t lib DB MockBasic.pm/);
    my $DB_dir = do {
        my $tempdir = tempdir( CLEANUP => 1 );
        io->catdir($tempdir,'DB');
    };
    my $error;
    make_path($DB_dir, { error => \$error, verbose => 1 }) or diag $error;
    $src > (my $dest = io->catfile($DB_dir, 'MockBasic.pm'));


    $annotate->write_files( dir => $DB_dir->pathname );

    my $src_content = $src->all;
    is(decode_utf8($dest->all."\n"), <<"END");
## == Schema Info ==
# CREATE TABLE mock_basic (
#   id   integer,
#   名前 text,
#   desc text,
#   primary key ( id )
# )
# CREATE INDEX test_index on mock_basic(名前)
# CREATE INDEX test_index2 on mock_basic(desc)
## == Schema Info ==

$src_content
END
};

done_testing;

