#-*- mode: cperl -*-#
use Test::More;
use blib;

chdir 't' if -d 't';
require './setup.pl';

unless( have_crontab() ) {
    plan skip_all => "no crontab available";
    exit;
}

plan tests => 2;

use_ok( 'Config::Crontab' );

my $ct = new Config::Crontab( -file => ".tmp_crontab.$$" );

## make a new Block object
my $block = new Config::Crontab::Block( -data => <<_BLOCK_ );
## mail something to joe at 5 after midnight on Fridays
MAILTO=joe
5 0 * * Fri /bin/someprogram 2>&1
_BLOCK_

## add this block to the crontab object
$ct->last($block);

## make another block using Block methods
$block = new Config::Crontab::Block;
$block->last( new Config::Crontab::Comment( -data => '## do backups' ) );
$block->last( new Config::Crontab::Env( -name => 'MAILTO', -value => 'bob' ) );
$block->last( new Config::Crontab::Event( -minute  => 40,
                                          -hour    => 3,
                                          -command => '/sbin/backup --partition=all' ) );
## add this block to crontab file
$ct->last($block);

## write out crontab file
$ct->write;

is( $ct->dump, <<_DUMPED_, "dump clean" );
## mail something to joe at 5 after midnight on Fridays
MAILTO=joe
5 0 * * Fri /bin/someprogram 2>&1

## do backups
MAILTO=bob
40 3 * * * /sbin/backup --partition=all
_DUMPED_

END {
    unlink ".tmp_crontab.$$";
}
