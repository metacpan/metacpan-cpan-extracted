use strict;
use Benchmark;
use Apache::Session::Store::DB_File;

use vars qw($rs $ws $n);

my $dir = int(rand(10000));
mkdir $dir, 0700;
chdir $dir;

$ws = {
    args => {FileName => 'bench.dbm'},
    data => {_session_id => 0},
    serialized => "A"x2**10
};
$rs = {
    args => {FileName => 'bench.dbm'},
    data => {_session_id => 0},
    serialized => "A"x2**10
};

sub insert {
    my $store = new Apache::Session::Store::DB_File;
    $store->insert($ws);
    $ws->{data}->{_session_id}++;
}

sub materialize {
    $rs->{data}->{_session_id} = int(rand($ws->{data}->{_session_id} - 1));
    my $store = new Apache::Session::Store::DB_File;
    $store->materialize($rs);
}

timethis(1000, \&insert, 'Insert First 1000');
timethis(1000, \&materialize, 'Random Access n=1000');

for (my $i = 0; $i < 9000; $i++) {
    &insert;
}

timethis(1000, \&insert, 'Insert 10000-11000');
timethis(1000, \&materialize, 'Random Access n=11000');

for (my $i = 0; $i < 89000; $i++) {
    &insert;
}

timethis(1000, \&insert, 'Insert 100000-101000');
timethis(1000, \&materialize, 'Random Access n=101000');

unlink './bench.dbm';
chdir '..';
rmdir $dir;
