use strict;
use warnings;
use Test::More tests => 7;
use DBI;

my $dbh = DBI->connect('dbi:Spanner:projects/p/instances/i/databases/d', '', '');

my $sth1 = $dbh->prepare('SELECT 10', { Async => 1 });
my $sth2 = $dbh->prepare('SELECT 20', { Async => 1 });
my $sth3 = $dbh->prepare('SELECT 30', { Async => 1 });

is($sth1->execute(), '0E0', 'sth1 non-blocking execute');
is($sth2->execute(), '0E0', 'sth2 non-blocking execute');
is($sth3->execute(), '0E0', 'sth3 non-blocking execute');

$sth1->{fd} = 10;
$sth2->{fd} = 11;
$sth3->{fd} = 12;

is($sth1->fileno(), 10, 'sth1 file descriptor');
is($sth2->fileno(), 11, 'sth2 file descriptor');
is($sth3->fileno(), 12, 'sth3 file descriptor');

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
