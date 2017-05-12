# $Id$
#
# Multiple ways of getting DML counts
# Provided for:
# http://stackoverflow.com/questions/4202178/perl-dbi-getting-records-affected-of-each-statement-in-a-transaction
use DBI;
use strict;
use warnings;
use Data::Dumper;

my $h = DBI->connect();
$h->{RaiseError} = 1;

eval {$h->do(q/drop table mje/)};

$h->do(q/create table mje (a int)/);

sub example1 {
    my $s = $h->prepare(<<'EOT');
declare @insert_count int
declare @update_count int
declare @delete_count int

begin tran
insert into mje values(1);
select @insert_count = @@rowcount

update mje set a = 2 where a = 1;
select @update_count = @@rowcount

delete from mje where a = 2;
select @delete_count = @@rowcount
commit tran

select @insert_count, @update_count, @delete_count
EOT
    print "execute: ", $s->execute, "\n";
    return $s;
}

sub example2 {

    my $s = $h->prepare(<<'EOT');

begin tran
insert into mje values(1);
select @@rowcount

update mje set a = 2 where a = 1;
select @@rowcount

delete from mje where a = 2;
select @@rowcount
commit tran

EOT
    print "execute: ", $s->execute, "\n";
    return $s;
}

sub example3 {
    eval {$h->do(q/drop procedure pmje/)};

    $h->do(<<'EOT');
create procedure pmje (@insert int OUTPUT, @update int OUTPUT, @delete int OUTPUT) AS
begin tran
insert into mje values(1);
select @insert = @@rowcount

update mje set a = 2 where a = 1;
select @update = @@rowcount

delete from mje where a = 2;
select @delete = @@rowcount
commit tran
EOT
    my $s = $h->prepare(q/{call pmje(?,?,?)}/);

    $s->bind_param_inout(1, \my $insert, 100);
    $s->bind_param_inout(2, \my $update, 100);
    $s->bind_param_inout(3, \my $delete, 100);
    $s->execute;
    print "example3 insert=$insert, update=$update, delete=$delete\n";
}

sub example4 {
    my ($inserted, $updated, $deleted);
    eval {
        $h->begin_work;

        $inserted = $h->do(q/insert into mje values(1)/);
        $updated = $h->do(q/update mje set a = 2 where a = 1/);
        $deleted = $h->do(q/delete from mje where a = 2/);
        $h->commit;
    };
    if ($@) {
        $h->rollback or warn "Failed to rollback";
    }
    print "example4 insert=$inserted, update=$updated, delete=$deleted\n";
}


sub show_result {
    my $s = shift;

    do {
        while (my @row = $s->fetchrow_array) {
            print Dumper(\@row), "\n";
        }
    } while ($s->{odbc_more_results});
}

my $s = example1();
show_result($s);
$s = example2();
show_result($s);
example3();
example4();
