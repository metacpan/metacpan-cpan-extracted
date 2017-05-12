use strict;
use warnings;

use Storable;
use Test::DBO Sponge => 'Sponge', tests => 26;
note 'Storable '.$Storable::VERSION;
note 'Testing with: CacheQuery => '.DBIx::DBO->config('CacheQuery');

MySponge::db::setup([qw(id name age)], [1, 'one', 1], [7, 'test', 123], [3, 'three', 333], [999, 'end', 0]);

my $dbo;
my $frozen;
my $thawed;
sub freeze_thaw {
    my $obj = shift;
    (my $type = my $class = ref $obj) =~ s/.*:://;

    ok $frozen = Storable::freeze($obj), join ' ', 'Freeze', $type, @_;
    isa_ok $thawed = Storable::thaw($frozen), $class, 'Thawed';
    exists $dbo->{$_} and $thawed->dbo->{$_} = $dbo->{$_} for qw(dbh rdbh);
}

# Create the DBO
my $dbh = MySponge->connect('DBI:Sponge:') or die $DBI::errstr;
$dbo = DBIx::DBO->new($dbh);
$dbo->config('AutoReconnect', int rand 2);
note 'AutoReconnect => '.$dbo->config('AutoReconnect');
freeze_thaw($dbo);
is_deeply $thawed, $dbo, 'Same DBO';

my $t = $dbo->table($Test::DBO::test_tbl) or die sql_err($dbo);
freeze_thaw($t);
is_deeply $thawed, $t, 'Same Table';

my $q = $dbo->query($t) or die sql_err($dbo);
$q->show($t ** 'id', $t);
freeze_thaw($q);
is_deeply $thawed, $q, 'Same Query';

my $r = $t->fetch_row(id => 1) or die sql_err($t);
freeze_thaw($r);
is_deeply $thawed, $r, 'Same Row';

$q->run;

freeze_thaw($q, '(after run)');
{ # Reset the active query
    local(@$q{qw(sth Row)});
    local(@$q{qw(Active hash)}) = 0 unless exists $q->{cache};;
    is_deeply $thawed, $q, 'Same Query';
}

$r = $q->fetch or die sql_err($q);

freeze_thaw($r, '(after fetch)');
$r->_detach; # Detach from Parent
SKIP: {
    skip 'Storable v2.38 required to freeze attached Row objects', 1 if $Storable::VERSION < 2.38;
    is_deeply $thawed, $r, 'Same Row';
}

$q->fetch or die sql_err($q);

freeze_thaw($r, '(after fetch & detach)');
is_deeply $thawed, $r, 'Same Row';

freeze_thaw($q, '(after fetch)');
{ # Reset the active query
    local(@$q{qw(sth Row)});
    local(@$q{qw(Active hash)}) = 0 unless exists $q->{cache};;
    local $q->{cache}{idx} = 0 if exists $q->{cache};
    is_deeply $thawed, $q, 'Same Query';

    if ($thawed->config('CacheQuery')) {
        is_deeply $thawed->fetch, $q->fetch, 'Same Row from $q->fetch';
    } else {
        is_deeply \@{$thawed->fetch}, [999,'end',0], 'Same Row from $q->fetch';
    }
}
is ${$thawed->{Row}}->{Columns}, $thawed->{Columns}, 'Row has not detached';

