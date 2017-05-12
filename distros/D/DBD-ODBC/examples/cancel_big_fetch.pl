# $Id$
# demonstrates that not fetching all of a result-set makes can make
# a difference. More recent MS SQL Server drivers are better at this so don't
# be surprised if this shows no difference between the 2 variations.
# However, in the past, cancelling a big select when you have not selected
# all rows has made a huge difference as MS SQL Server sees the cancel and
# stops sending the result-set.
use DBI;
use strict;
use warnings;
use Benchmark;
use Data::Dumper;

my $h = DBI->connect();

if (@ARGV) {
    local $h->{PrintError} = 0;
    eval {
        $h->do(q/drop table mjebig/);
    };
    $h->do(q/create table mjebig(a varchar(255))/);
    $h->begin_work;             # quicker than autocommit
    my $val = 'a' x 255;
    my $s = $h->prepare(q/insert into mjebig values(?)/);
    foreach (1..100000) {
        $s->execute($val);
    }
    $h->commit;
}

sub one
{
    my $s = $h->prepare(q/select * from mjebig/);
    $s->execute;
    $s->fetch;
    $s = undef;
}

sub two
{
    my $s = $h->prepare(q/select * from mjebig/);
    $s->execute;
    $s->fetch;
    my $x = $s->cancel;
    #print Dumper(\$x), "\n";
    $s = undef;
}

timethese(1000, {
    'without_cancel' => sub{one()},
    'with_cancel' => sub{two()}
   });


