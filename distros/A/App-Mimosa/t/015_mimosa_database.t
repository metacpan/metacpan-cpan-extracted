use Test::Most tests => 5;
use strict;
use warnings;
use Carp::Always;
use Cwd;

use lib 't/lib';
use File::Spec::Functions;
use App::Mimosa::Test;

my ($tdir, $file, $dbname);
BEGIN {
    use_ok 'App::Mimosa::Database';
    $dbname = 'blastdb_test.nucleotide';
    $file   = "$dbname.seq";
    $tdir   = catdir(qw/t data/);
}


my $cwd  = getcwd;
chdir $tdir;
my $db = App::Mimosa::Database->new(
    db_basename => 'blastdb_test.nucleotide.seq',
    alphabet    => 'nucleotide',
    context     => app(),
);
isa_ok $db, 'App::Mimosa::Database';

lives_ok sub { $db->index }, 'index does not die';

is( $db->db->title, $file, 'title is correct');

can_ok $db, qw/db_basename alphabet index/;
