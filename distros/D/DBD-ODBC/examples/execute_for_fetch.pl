# $Id$
#
# Demonstrate DBD::ODBC's execute_for_fetch.
# By default DBD::ODBC has its own execute_for_fetch which should always
# be quicker than DBI's implementation which just does loads of execute calls
# one for each insert whereas DBD::ODBC's defaults to 10 inserts at a time.
# Also shows how changing DBD::ODBC's odbc_batch_size can influence the
# speed but at the expense of memory.
#
# You can run with no args to run the Benchmark or you can provide an
# command line arg of 'dbi', 'eff' or 'eff50', efftxn and eff50txn
# to run an individual method.
# The tests with txn in the name start a transaction at the start and commit
# at the end which is always faster.
use DBI;
use Data::Dumper;
use strict;
use warnings;
use Benchmark;

my $fetch_row = 0;
my $x = '11111111112' x 1000;
my @p = split (/2/,$x);
print "Total rows to insert = ", scalar(@p), "\n";

if (@ARGV) {
    if ($ARGV[0] eq 'dbi') {
	two();
    } elsif ($ARGV[0] eq 'dbitxn') {
	two(1);
    } elsif ($ARGV[0] eq 'eff') {
	one();
    } elsif ($ARGV[0] eq 'eff50') {
	one(1);
    } elsif ($ARGV[0] eq 'efftxn') {
	one(undef, 1);
    } elsif ($ARGV[0] eq 'eff50txn') {
	one(1,1);
    }
} else {
    timethese(20, {
	'execute_for_fetch_default' => sub {one()},
	'dbi' => sub {two()},
	'dbitxn' => sub {two(1)},
	'execute_for_fetch_batch_size' => sub {one(1)},
	'execute_for_fetch_txn', => sub {one(undef, 1)},
	'execute_for_fetch_batch_size_txn' => sub {one(1,1)}
	      });
}

# any arg true enables odbc array operations
sub dbconnect {
    my $enable = shift;

    my $h =  DBI->connect("dbi:ODBC:DSN=baugi","sa","easysoft",
			  {RaiseError => 1, PrintError => 0,
			   odbc_array_operations => $enable,
			  });
    eval {
	local $h->{PrintError} = 0;
	$h->do(q/drop table two/);
    };

    $h->do(q/create table two (a varchar(20))/);
    return $h;
}

# any true first arg sets odbc_batch_size to 50 (5 * the default)
# any true second arg starts a transaction and commits it at the end
sub one {
    my $h = dbconnect(1);
    $h->{odbc_batch_size} = 50 if $_[0];
    $h->begin_work if $_[1];
    doit($h);
    $h->commit if $_[1];
    $h->disconnect;
}

sub two {
    my $h = dbconnect(0);
    $h->begin_work if $_[0];
    doit($h);
    $h->commit if $_[0];
    $h->disconnect;
}

sub doit {
    my $h = shift;
    #print "dbh odbc_batch_size=", $h->{odbc_batch_size}, "\n";
    my $s = $h->prepare(q/insert into two values(?)/);
    #print "sth odbc_batch_size=", $s->{odbc_batch_size}, "\n";
    my ($tuples, $rows, @tuple_status);
    #print "About to run execute_for_fetch\n";
    eval {
        ($tuples, $rows) = $s->execute_for_fetch(\&fetch_sub, \@tuple_status);
    };
    if ($@) {
        print "execute_for_fetch died : $@ END\n";
    }
    #print "tuples = ", Dumper($tuples), "rows = ", Dumper($rows), "\n";
    #print "tuple status ", Dumper(\@tuple_status), "\n";

    $s = undef;


    #my $r = $h->selectall_arrayref(q/select * from two/);
    #print "Rows:", scalar(@$r), "\n";
    #print Dumper($r);

    #$h->do(q/delete from two/);

}

sub fetch_sub {
    #print "fetch_sub $fetch_row\n";
    if ($fetch_row == @p) {
        #print "returning undef\n";
        $fetch_row = 0;
        return;
    }

    return [$p[$fetch_row++]];

}


