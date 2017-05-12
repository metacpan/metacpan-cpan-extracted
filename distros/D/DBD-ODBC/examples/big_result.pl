# $Id$
# create a table with lots of big rows and see how long it takes to
# get it back
# run once with any command line argument (to create and populate the table)
# then later without the argument
use DBI;
use strict;
use warnings;
use Benchmark::Timer;
use Data::Dumper;

my $t = Benchmark::Timer->new;
$t->start('main');
my $h = DBI->connect;

if ($ARGV[0]) {
    print "Recreating table\n";
    eval {$h->do(q/drop table mje/);};
    $h->do(q/create table mje (a varchar(50), b varchar(50), c varchar(50), d varchar(50))/);

    $h->begin_work;
    my $s = $h->prepare(q/insert into mje values(?,?,?,?)/);
    my $a = 'a' x 50;
    my $b = 'b' x 50;
    my $c = 'c' x 50;
    my $d = 'd' x 50;
    foreach (1..50000) {
        $s->execute($a, $b, $c, $d);
    }
    $h->commit;
}
$t->stop('main');

$t->start('fetch');
my $r = $h->selectall_arrayref(q/select * from mje/);
$t->stop('fetch');

#$t->start('dump');
#print Dumper($r);
#$t->stop('dump');

print "Rows fetched:", scalar(@$r), "\n";
print $t->reports;
