use strict;
use warnings;
use Test::More tests => 7;
use DBI;

my $dbh = DBI->connect('dbi:BigQuery:project=p;dataset=d', '', '');

my $sth1 = $dbh->prepare('SELECT 100', { Async => 1 });
my $sth2 = $dbh->prepare('SELECT 200', { Async => 1 });
my $sth3 = $dbh->prepare('SELECT 300', { Async => 1 });

is($sth1->execute(), '0E0', 'sth1 non-blocking execute');
is($sth2->execute(), '0E0', 'sth2 non-blocking execute');
is($sth3->execute(), '0E0', 'sth3 non-blocking execute');

$sth1->{fd} = 20;
$sth2->{fd} = 21;
$sth3->{fd} = 22;

is($sth1->fileno(), 20, 'sth1 file descriptor');
is($sth2->fileno(), 21, 'sth2 file descriptor');
is($sth3->fileno(), 22, 'sth3 file descriptor');

my @active = ($sth1, $sth2, $sth3);
my @results;

while (@active) {
    my @next_active;
    for my $sth (@active) {
        if ($sth->async_read_ready()) {
            my $row = $sth->fetch_async_row();
            push @results, $row->[0] if $row;
        } else {
            push @next_active, $sth;
        }
    }
    @active = @next_active;
}

is_deeply([ sort @results ], ['1', '1', '1'], 'Fetched all concurrent async handle results cleanly');
