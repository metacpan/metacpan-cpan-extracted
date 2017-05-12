use strict;
use warnings;
use Test::More;
use Config;

use DBIx::ObjectMapper::Engine::DBI;
use DBIx::ObjectMapper;

BEGIN {
    plan skip_all => 'Your perl does not support ithreads'
        if !$Config{useithreads} || $] < 5.008;
}

use threads;

# README: If you set the env var to a number greater than 10,
#   we will use that many children
my ($dsn, $user, $pass) = @ENV{map { "MAPPER_TEST_PG_${_}" } qw/DSN USER PASS/};

plan skip_all => 'Set $ENV{MAPPER_TEST_PG_DSN}, _USER and _PASS to run this test' unless ($dsn && $user);

my $num_children = $ENV{MAPPER_TEST_THREAD_STRESS};
plan skip_all => 'Set $ENV{MAPPER_TEST_THREAD_STRESS} to run this test'
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
    $cd => 'My::ThreadTest',
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
    my $attr = $mapper->attribute('My::ThreadTest');
    $parent_rs = $session->search('My::ThreadTest')->filter( $attr->p('year') == 1901 )->execute;
    $parent_rs->next;
};
ok(!$@) or diag "Creation eval failed: $@";

my @children;
while(@children < $num_children) {
    my $newthread = async {
        my $tid = threads->tid;
        my $session = $mapper->begin_session;
        my $attr = $mapper->attribute('My::ThreadTest');
        my $child_rs = $session->search('My::ThreadTest')->filter( $attr->p('year') == 1901 )->execute;
        my $row = $parent_rs->next;
        if($row && $row->artist =~ /^(?:123|456)$/) {
            $session->add(
                My::ThreadTest->new(
                    title => "test success $tid",
                    artist => $tid,
                    year => scalar(@children),
                ),
            );
        }
        sleep(3);
    };
    die "Thread creation failed: $! $@" if !defined $newthread;
    push(@children, $newthread);
}

{
    $_->join for(@children);
}

while(@children) {
    my $child = pop(@children);
    my $tid = $child->tid;
    my $session = $mapper->begin_session;
    my $attr = $mapper->attribute('My::ThreadTest');
    my $rs = $session->search('My::ThreadTest')->filter(
        $attr->p('title') == "test success $tid",
        $attr->p('artist') == $tid,
        $attr->p('year') == scalar(@children)
    )->execute;
    is($rs->next->artist, $tid, "Child $tid successful");
}

$engine->dbh->do(q{DROP TABLE cd});

done_testing;
