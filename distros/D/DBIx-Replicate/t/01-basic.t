use strict;
use warnings;

use Test::More;

BEGIN {
    if (! $ENV{DBI_URI}) {
        plan skip_all => 'set DBI_URI, DBI_USER, DBI_PASSWORD to run these tests';
    } else {
        plan tests => 12;
    }
    use_ok('DBIx::Replicate', qw/dbix_replicate/);
};

my $engine = $ENV{DBI_ENGINE} || '';
if ($engine eq '' && $ENV{DBI_URI} =~ /^dbi:mysql:/i) {
    $engine = 'engine=innodb';
}

my $dbh = DBI->connect($ENV{DBI_URI}, $ENV{DBI_USER}, $ENV{DBI_PASSWORD})
    or die DBI->errstr;

# prepare tables
$dbh->do('drop table if exists drtest_src')
    or die $dbh->errstr;
$dbh->do(
    "create table drtest_src (id int not null primary key, str varchar(63)) $engine"
) or die $dbh->errstr;
$dbh->do('drop table if exists drtest_dest')
    or die $dbh->errstr;
$dbh->do(
    "create table drtest_dest (id int not null primary key, str varchar(63)) $engine"
) or die $dbh->errstr;
my $st = $dbh->prepare('replace into drtest_src (id,str) values (?,?)')
    or die $dbh->errstr;

foreach my $copy_mode (qw/primary_key copy_by/) {
    
    my %args = (
        src_conn   => $dbh,
        src_table  => 'drtest_src',
        dest_conn  => $dbh,
        dest_table => 'drtest_dest',
        $copy_mode => [ qw/id/ ],
        columns    => [ qw/id str/ ],
        ($copy_mode eq 'primary_key' ? (limit => 5) : ()),
    );
    # copy empty tables
    dbix_replicate(\%args);
    is_deeply(
        $dbh->selectall_arrayref('select * from drtest_src order by id'),
        $dbh->selectall_arrayref('select * from drtest_dest order by id'),
        "Copy empty tables",
    );
    
    # fill in data and copy
    for (my $i = 0; $i < 1000; $i++) {
        $st->execute($i, "this is a test $i")
            or die $dbh->errstr;
    }
    dbix_replicate(\%args);
    is_deeply(
        $dbh->selectall_arrayref('select * from drtest_src order by id'),
        $dbh->selectall_arrayref('select * from drtest_dest order by id'),
        "Copy with some data",
    );
    
    # remove some of the rows
    $dbh->do('delete from drtest_src where id%13=0')
        or die $dbh->errstr;
    dbix_replicate(\%args);
    is_deeply(
        $dbh->selectall_arrayref('select * from drtest_src order by id'),
        $dbh->selectall_arrayref('select * from drtest_dest order by id'),
        "Copy after removing rows",
    );
    
    # insert a couple of rows
    for (my $i = 0; $i < 2000; $i += 17) {
        $st->execute($i, "this is a test $i")
            or die $dbh->errstr;
    }
    dbix_replicate(\%args);
    is_deeply(
        $dbh->selectall_arrayref('select * from drtest_src order by id'),
        $dbh->selectall_arrayref('select * from drtest_dest order by id'),
        "Copy after inserting rows",
    );
    
    # limit rows to be copied by using extra_cond
    if ($copy_mode eq 'primary_key') {
        dbix_replicate({
            %args,
            extra_cond => 'id%7=0'
        });
        is_deeply(
            [
                grep {
                    $_->[0] %7 == 0
                } @{$dbh->selectall_arrayref(
                    'select * from drtest_src order by id'
                )},
        ],
            $dbh->selectall_arrayref('select * from drtest_dest order by id'),
            "Copy with limit on rows (copy mode = $copy_mode)",
        );
    }
    
    # limit rows to be updated using limit_cond
    if ($copy_mode eq 'primary_key') {
        dbix_replicate({
            %args,
            extra_cond     => 'id%10=0',
        });
        is_deeply(
            $dbh->selectall_arrayref('select * from drtest_src where id%10=0 order by id'),
            $dbh->selectall_arrayref('select * from drtest_dest order by id'),
            'Prepare for extra_cond test',
        );
        dbix_replicate({
            %args,
            limit_cond => 'id between 300 and 500',
        });
        is_deeply(
            $dbh->selectall_arrayref('select * from drtest_src where id%10=0 or id between 300 and 500 order by id'),
            $dbh->selectall_arrayref('select * from drtest_dest order by id'),
            'extra_cond',
        );
    }
    
    $dbh->do('delete from drtest_src')
        or die $dbh->errstr;
    $dbh->do('delete from drtest_dest')
        or die $dbh->errstr;
}

$dbh->do('drop table drtest_src')
    or die $dbh->errstr;
$dbh->do('drop table drtest_dest')
    or die $dbh->errstr;
