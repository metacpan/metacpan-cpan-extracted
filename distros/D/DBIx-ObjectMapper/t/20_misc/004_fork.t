use strict;
use warnings;
use Test::More;

use DBIx::ObjectMapper::Engine::DBI;
use DBIx::ObjectMapper;

# README: If you set the env var to a number greater than 10,
#   we will use that many children
my ($dsn, $user, $pass) = @ENV{map { "MAPPER_TEST_PG_${_}" } qw/DSN USER PASS/};

plan skip_all => 'Set $ENV{MAPPER_TEST_PG_DSN}, _USER and _PASS to run this test' unless ($dsn && $user);

my $num_children = $ENV{MAPPER_TEST_FORK_STRESS};
plan skip_all => 'Set $ENV{MAPPER_TEST_FORK_STRESS} to run this test'
    unless $num_children;

if($num_children !~ /^[0-9]+$/ || $num_children < 10) {
   $num_children = 10;
}

my $engine = DBIx::ObjectMapper::Engine::DBI->new({
    dsn => $dsn,
    username => $user,
    password => $pass,
    on_connect_do => [
    ],
});

$engine->dbh->do(
    q{CREATE TABLE cd (cdid serial PRIMARY KEY, artist INTEGER NOT NULL UNIQUE, title VARCHAR(100) NOT NULL UNIQUE, year VARCHAR(100) NOT NULL, genreid INTEGER, single_track INTEGER);}
);

my $mapper = DBIx::ObjectMapper->new( engine => $engine );
my $cd = $mapper->metadata->table( cd => 'autoload' );
$mapper->maps(
    $cd => 'My::ForkTest',
    accessors => { auto => 1 },
    constructor => { auto => 1 },
);

my $parent_rs;
eval {
    my $session = $mapper->begin_session;
    $cd->insert(
        title => 'vacation in antarctica',
        artist => 123,
        year => 1901
    )->execute;

    $cd->insert(
        title => 'vacation in antarctica part 2',
        artist => 456,
        year => 1901
    )->execute;

    my $attr = $mapper->attribute('My::ForkTest');
    $parent_rs = $session->search('My::ForkTest')->filter( $attr->p('year') == 1901 )->execute;
    $parent_rs->next;
};
ok(!$@) or diag "Creation eval failed: $@";

{
    my $pid = fork;
    if(!defined $pid) {
        die "fork failed: $!";
    }

    if (!$pid) {
        exit $cd->engine->connected ? 1 : 0;
    }

    if (waitpid($pid, 0) == $pid) {
        my $ex = $? >> 8;
        ok($ex == 0, "driver->connected() returns false in child");
        if( $ex ) { # skip remaining tests
            exit $ex;
        }
    }
};

my @pids;
while(@pids < $num_children) {

    my $pid = fork;
    if(!defined $pid) {
        die "fork failed: $!";
    }
    elsif($pid) {
        # parent
        push(@pids, $pid);
        next;
    }

    # child
    $pid = $$;
    my $session = $mapper->begin_session;
    my $attr = $mapper->attribute('My::ForkTest');
    my $child_rs = $session->search('My::ForkTest')->filter( $attr->p('year') == 1901 )->execute;
    my $row = $parent_rs->next;
    if($row && $row->artist =~ /^(?:123|456)$/) {
        $session->add(
            My::ForkTest->new(
                title => "test success $pid",
                artist => $pid,
                year => scalar(@pids),
            ),
        );
    }
    sleep(3);
    exit;
}

waitpid($_,0) for(@pids);

while(@pids) {
    my $pid = pop(@pids);
    my $session = $mapper->begin_session;
    my $attr = $mapper->attribute('My::ForkTest');
    my $rs = $session->search('My::ForkTest')->filter(
        $attr->p('title') == "test success $pid",
        $attr->p('artist') == $pid,
        $attr->p('year') == scalar(@pids)
    )->execute;
    is($rs->next->artist, $pid, "Child $pid successful");
}

$engine->dbh->do(q{DROP TABLE cd});

done_testing;
