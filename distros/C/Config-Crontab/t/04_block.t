#-*- mode: cperl -*-#
use Test::More;
use blib;

chdir 't' if -d 't';
require './setup.pl';

unless( have_crontab() ) {
    plan skip_all => "no crontab available";
    exit;
}
plan tests => 68;

use_ok('Config::Crontab');

my $block;
my $data;

## empty block
$block = new Config::Crontab::Block;
is( $block->dump, '', "empty block" );
undef $block;

## single line constructor argument
$block = new Config::Crontab::Block( -data => '## one line block' );
is( $block->dump, <<_BLOCK_, "comment block" );
## one line block
_BLOCK_
undef $block;

## a multi-line constructor argument
$block = new Config::Crontab::Block( -data => <<_BLOCK_ );
## a comment
MAILTO=joe
5  0  *  *  *       rm -ri /
_BLOCK_
is( $block->dump, <<_BLOCK_, "basic block" );
## a comment
MAILTO=joe
5 0 * * * rm -ri /
_BLOCK_
undef $block;

## using methods
$block = new Config::Crontab::Block;
$block->data('## a comment');
is( $block->dump, "## a comment\n", "comment block" );
undef $block;

## test newline
$block = new Config::Crontab::Block;
is( $block->data( "## single comment\n" ), "## single comment\n" );
is( $block->dump, "## single comment\n" );  ## should have no extra newlines
undef $block;

## test multiline block via method
$block = new Config::Crontab::Block;
$data = <<_DATAFOO_;
## this is foo
MAILTO=bob
#6 * 0 0 Sat /bin/saturday
_DATAFOO_
is( $block->data($data), $data );
undef $block;

## set via lines constructor
my $comment1 = new Config::Crontab::Comment( -data => '## just a comment' );
my $env1     = new Config::Crontab::Env( -data => 'MAILTO=joe' );
my $event1   = new Config::Crontab::Event( -data => '5 0 * * * /bin/foo' );
my @lines = ( $comment1,
	      $env1,
	      $event1, );

$block = new Config::Crontab::Block( -lines => \@lines );
is( $block->dump, <<_LINES_, "block w/ variable" );
## just a comment
MAILTO=joe
5 0 * * * /bin/foo
_LINES_
undef $block;

## set via lines method
$block = new Config::Crontab::Block;
$block->lines(\@lines);
is( $block->dump, <<_LINES_, "block set via lines()" );
## just a comment
MAILTO=joe
5 0 * * * /bin/foo
_LINES_
undef $block;


## set via -lines attribute; override with -data
$block = new Config::Crontab::Block( -lines => \@lines,
                                     -data  => $data );
is( $block->data, $data );
is( $block->dump, $data );
undef $block;


## try ->lines(undef) and see what happens
$block = new Config::Crontab::Block( -lines => undef );
is( $block->dump, '' );
undef $block;


## try adding some lines
$block = new Config::Crontab::Block( -lines => \@lines );
my $event2 = new Config::Crontab::Event( -data => '5 2 * * * /bin/bar' );
$block->last($event2);
is( $block->dump, <<_LINES_, "block initialized via -lines" );
## just a comment
MAILTO=joe
5 0 * * * /bin/foo
5 2 * * * /bin/bar
_LINES_

## try removing some lines
$block->remove($event1);
ok( defined $event1 );  ## should still be defined
is( $event1->command, '/bin/foo' );
is( $block->dump, <<_LINES_ );
## just a comment
MAILTO=joe
5 2 * * * /bin/bar
_LINES_

## add it back in, remove some more
$block->last($event1);
$block->remove($event2, $env1, $event1);
is( $block->dump, <<_LINES_, "removed entries" );
## just a comment
_LINES_

## remove the last object from the block and dump
is( $block->remove($comment1), 0 );  ## remove method in scalar context
is( $block->dump, '' );
undef $block;


## test replace
@lines = ( $comment1, $env1, $event1 );
$block = new Config::Crontab::Block( -lines => \@lines );
$event2 = new Config::Crontab::Event( -data => '5 2 * * * /bin/bar' );
$block->replace($event1 => $event2);
is( $block->dump, <<_LINES_ );
## just a comment
MAILTO=joe
5 2 * * * /bin/bar
_LINES_
undef $block;


## try adding some in different positions
@lines = ( $comment1, $env1, $event1, );
$block = new Config::Crontab::Block( -lines => \@lines );
$event2 = new Config::Crontab::Event( -data => '5 2 * * * /bin/bar' );
$block->lines( [$event2, @lines] );
is( $block->dump, <<_LINES_ );
5 2 * * * /bin/bar
## just a comment
MAILTO=joe
5 0 * * * /bin/foo
_LINES_
undef $block;


## make sure first, last only take objects
@lines = ( $comment1, $env1, $event1, );
$block = new Config::Crontab::Block( -lines => \@lines );
$event2 = new Config::Crontab::Event( -data => '5 2 * * * /bin/bar' );
$block->first($event2);
is( $block->dump, <<_LINES_ );
5 2 * * * /bin/bar
## just a comment
MAILTO=joe
5 0 * * * /bin/foo
_LINES_

## re-order a bunch of objects internally via first
$block->first($event1, 'bogus stuff', $env1, $comment1);
is( $block->dump, <<_LINES_ );
5 0 * * * /bin/foo
MAILTO=joe
## just a comment
5 2 * * * /bin/bar
_LINES_

## same thing via last
$block->last('diem', $comment1, $env1, $event1, 'carpe');
is( $block->dump, <<_LINES_ );
5 2 * * * /bin/bar
## just a comment
MAILTO=joe
5 0 * * * /bin/foo
_LINES_
undef $block;

## test select
@lines = ( $comment1, $env1, $event1, );
$block = new Config::Crontab::Block( -lines => \@lines );
my @select = $block->select( -type => 'comment' );
is( scalar @select, 1 );

$block->first( new Config::Crontab::Comment( -data => '## why?' ) );

@select = $block->select( -type => 'comment' );
is( scalar @select, 2 );

my($obj) = $block->select( -type => 'comment');
is( $obj->dump, '## why?' );
($obj) = $block->select( -type => 'event');
is( $obj->dump, '5 0 * * * /bin/foo' );
($obj) = $block->select;
is( $obj->dump, '## why?' );
undef $block;


## select some datetime attributes
$block = new Config::Crontab::Block( -lines => \@lines );
$block->last( new Config::Crontab::Event( -data => '10 10 * * Mon /bin/monday' ) );
is( $block->select( -datetime_re => '0 \* \*'), 2 );
is( $block->select( -datetime_re => ' 0 \* \*'), 1 );
is( $block->select( -datetime => '5 0 * * *'), 1, "datetime selector" );
undef $block;

## some select tests w/o the '-type' attribute
$block = new Config::Crontab::Block( -lines => \@lines );
$block->first( new Config::Crontab::Comment( -data => '## foo' ) );
is( $block->select( -data_re => 'foo' ), 2 );
is( $block->select( -data => 'foo' ), 0 );  ## no matching exact strings
undef $block;


## some empty criteria tests
$block = new Config::Crontab::Block;
$block->last( new Config::Crontab::Comment( -data => '## next is empty' ) );
$block->last( new Config::Crontab::Comment );
$block->last( new Config::Crontab::Comment( -data => '## next is empty' ) );
$block->last( new Config::Crontab::Comment );
$block->last( new Config::Crontab::Comment( -data => '## next is empty' ) );
$block->last( new Config::Crontab::Comment );
$block->last( new Config::Crontab::Comment( -data => '## next is not empty' ) );
$block->last( new Config::Crontab::Env( -data => 'FOO=next' ) );
is( $block->select( -bogus => '' ), 8 );
is( $block->select( -data_re => 'next' ), 5 );
is( $block->select( -data => '' ), 3 );
undef $block;


## create a crontab block
@lines = ( $comment1, $env1, $event1, );
$block = new Config::Crontab::Block( -lines => \@lines );
$block->last( new Config::Crontab::Event( -data => '5 1 * * * /sbin/backup' ) );
$block->last( new Config::Crontab::Event( -data => '10 4 * * 3 /bin/wednesday' ) );
is( $block->dump, <<_DUMPED_ );
## just a comment
MAILTO=joe
5 0 * * * /bin/foo
5 1 * * * /sbin/backup
10 4 * * 3 /bin/wednesday
_DUMPED_

## delete the backup event
for my $event ( $block->select( -type => 'event') ) {
    next unless $event->command =~ /\bbackup\b/;  ## look for backup command
    $block->remove($event); last;
}

is( $block->dump, <<_DUMPED_, "backup removed" );
## just a comment
MAILTO=joe
5 0 * * * /bin/foo
10 4 * * 3 /bin/wednesday
_DUMPED_

## compare string match vs regex
is( $block->select( -type => 'event', -command => 'foo' ), 0 );
is( $block->select( -type => 'event', -command_re => 'foo' ), 1 );
undef $block;


## set up block for up, down, first, last tests
@lines = ( $comment1, $env1, $event1, );
$block = new Config::Crontab::Block( -lines => \@lines );
$event2 = new Config::Crontab::Event( -data => '5 1 * * * /sbin/backup' );
is( $block->dump, <<_DUMPED_ );
## just a comment
MAILTO=joe
5 0 * * * /bin/foo
_DUMPED_

## add new event to bottom
$block->down($event2);  ## add at bottom
is( $block->dump, <<_DUMPED_ );
## just a comment
MAILTO=joe
5 0 * * * /bin/foo
5 1 * * * /sbin/backup
_DUMPED_

## add new event to top
$block->remove($event2);
is( $block->dump, <<_DUMPED_ );
## just a comment
MAILTO=joe
5 0 * * * /bin/foo
_DUMPED_

## add new event to top
$block->first($event2);
is( $block->dump, <<_DUMPED_ );
5 1 * * * /sbin/backup
## just a comment
MAILTO=joe
5 0 * * * /bin/foo
_DUMPED_

## try last
$block->last($event2);
is( $block->dump, <<_DUMPED_ );
## just a comment
MAILTO=joe
5 0 * * * /bin/foo
5 1 * * * /sbin/backup
_DUMPED_

## move back to top
$block->first($event2);
is( $block->dump, <<_DUMPED_ );
5 1 * * * /sbin/backup
## just a comment
MAILTO=joe
5 0 * * * /bin/foo
_DUMPED_

## try up (duplicate bug)
$block->up($event2);
is( $block->dump, <<_DUMPED_ );
5 1 * * * /sbin/backup
## just a comment
MAILTO=joe
5 0 * * * /bin/foo
_DUMPED_

## try down
$block->down($event2);
is( $block->dump, <<_DUMPED_ );
## just a comment
5 1 * * * /sbin/backup
MAILTO=joe
5 0 * * * /bin/foo
_DUMPED_

## last, then down again
$block->last($event2);
is( $block->dump, <<_DUMPED_ );
## just a comment
MAILTO=joe
5 0 * * * /bin/foo
5 1 * * * /sbin/backup
_DUMPED_

## (duplicate bug)
$block->down($event2);
is( $block->dump, <<_DUMPED_ );
## just a comment
MAILTO=joe
5 0 * * * /bin/foo
5 1 * * * /sbin/backup
_DUMPED_

## try up
$block->up($event2);
is( $block->dump, <<_DUMPED_ );
## just a comment
MAILTO=joe
5 1 * * * /sbin/backup
5 0 * * * /bin/foo
_DUMPED_
undef $block;


## setup tests for before, after
@lines = ( $comment1, $env1, $event1, );
$block = new Config::Crontab::Block( -lines => \@lines );
is( $block->dump, <<_DUMPED_ );
## just a comment
MAILTO=joe
5 0 * * * /bin/foo
_DUMPED_

$event2 = new Config::Crontab::Event( -data => '5 1 * * * /sbin/backup' );

$block->before($comment1, $event2);
is( $block->dump, <<_DUMPED_ );
5 1 * * * /sbin/backup
## just a comment
MAILTO=joe
5 0 * * * /bin/foo
_DUMPED_

$block->after($comment1, $event2);
is( $block->dump, <<_DUMPED_ );
## just a comment
5 1 * * * /sbin/backup
MAILTO=joe
5 0 * * * /bin/foo
_DUMPED_

## see about non-existent references
my $event3 = new Config::Crontab::Event( -minute => 33, -command => '/sbin/uptime' );
$block->before(undef, $event3);
is( $block->dump, <<_DUMPED_ );
33 * * * * /sbin/uptime
## just a comment
5 1 * * * /sbin/backup
MAILTO=joe
5 0 * * * /bin/foo
_DUMPED_

## test active
is( $block->active(0), 0 );
is( $block->dump, <<_DUMPED_, "inactive block" );
#33 * * * * /sbin/uptime
## just a comment
#5 1 * * * /sbin/backup
#MAILTO=joe
#5 0 * * * /bin/foo
_DUMPED_

ok( $block->active(1) );
is( $event3->active(0), 0 );
is( $block->dump, <<_DUMPED_ );
#33 * * * * /sbin/uptime
## just a comment
5 1 * * * /sbin/backup
MAILTO=joe
5 0 * * * /bin/foo
_DUMPED_

ok( ! $block->active(undef) );
ok( $event3->active(1) );
is( $block->dump, <<_DUMPED_ );
33 * * * * /sbin/uptime
## just a comment
#5 1 * * * /sbin/backup
#MAILTO=joe
#5 0 * * * /bin/foo
_DUMPED_

## a system block
undef $block;
$block = new Config::Crontab::Block;
$block->system(1);
$block->data(<<_DATA_);
## this is foo
#6 * 0 0 Sat rogerdodger /bin/saturday
_DATA_
is( ($block->select(-type => 'event'))[0]->user, 'rogerdodger' );

undef $block;
$block = new Config::Crontab::Block( -system => 1,
				     -data   => <<_DATA_);
## this is foo
#6 * 0 0 Sat wonka /bin/saturday
_DATA_
is( ($block->select(-type => 'event'))[0]->user, 'wonka' );

##
## remove many items using 'flag'
##
undef $block;
$block = new Config::Crontab::Block;
$block->system(1);
$block->data( <<'_DATA_');
1  5 * * *   bin    echo 1
2  5 * * *   bin    echo 2
3  5 * * *   bin    echo 3
4  5 * * *   bin    echo 4
5  5 * * *   bin    echo 5
6  5 * * *   bin    echo 6
7  5 * * *   bin    echo 7
8  5 * * *   bin    echo 8
9  5 * * *   bin    echo 9
10 5 * * *   bin    echo 10
11 5 * * *   bin    echo 11
12 5 * * *   bin    echo 12
13 5 * * *   bin    echo 13
14 5 * * *   bin    echo 14
15 5 * * *   bin    echo 15
16 5 * * *   bin    echo 16
17 5 * * *   bin    echo 17
_DATA_

## flag evens
my $count = 0;
for my $event ( $block->select( -type => 'event' ) ) {
    $event->flag('delete')
      if $count % 2 == 0;
    $count++;
}

## delete them
$block->remove( $block->select( -flag => 'delete' ) );

is( $block->dump, <<_BLOCK_ );
2	5	*	*	*	bin	echo 2
4	5	*	*	*	bin	echo 4
6	5	*	*	*	bin	echo 6
8	5	*	*	*	bin	echo 8
10	5	*	*	*	bin	echo 10
12	5	*	*	*	bin	echo 12
14	5	*	*	*	bin	echo 14
16	5	*	*	*	bin	echo 16
_BLOCK_
