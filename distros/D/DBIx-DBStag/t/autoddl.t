use lib 't';

BEGIN {
    # to handle systems with no installed Test module
    # we include the t dir (where a copy of Test.pm is located)
    # as a fallback
    eval { require Test; };
    use Test;    
    use DBStagTest;
    plan tests => 2;
}
use DBIx::DBStag;
use DBI;
use Data::Stag;
use FileHandle;
use strict;

drop();
my $f = "t/data/game.el";
my $data = Data::Stag->parse($f);
$data->where('seq',
	     sub {
		 my $s = shift;
		 my @dbxref = $s->get_dbxref;
		 $s->unset_dbxref;
		 foreach (@dbxref) {
		     my $sx = Data::Stag->new(seq_dbxref=>[$_]);
		     $s->add_seq_dbxref($sx);
		 }
	     });
$data->where('annot',
	     sub {
		 my $s = shift;
		 my @dbxref = $s->get_dbxref;
		 $s->unset_dbxref;
		 foreach (@dbxref) {
		     my $sx = Data::Stag->new(annot_dbxref=>[$_]);
		     $s->add_annot_dbxref($sx);
		 }
	     });
print $data->sxpr;
my $dbh = dbh();
my $ddl = $dbh->autoddl($data, [qw(seq_dbxref annot_dbxref)]);
print $ddl;

$dbh->do($ddl);
$dbh->storenode($data);
my $out = $dbh->selectall_stag('SELECT * FROM game NATURAL JOIN seq NATURAL JOIN seq_dbxref NATURAL JOIN dbxref');
print $out->sxpr;
my @dbxrefs = $out->get("game/seq/seq_dbxref/dbxref");
ok(@dbxrefs ==1);
ok($dbxrefs[0]->get_db eq 'x');

$out = $dbh->selectall_stag('SELECT * FROM annot NATURAL JOIN fset NATURAL JOIN fspan NATURAL JOIN game NATURAL JOIN seq NATURAL JOIN seq_dbxref NATURAL JOIN dbxref USE NESTING (annotset (annot (game(seq(seq_dbxref(dbxref)))) (fset(fspan))))');

$dbh->disconnect;
