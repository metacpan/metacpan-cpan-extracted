#-*- mode: cperl -*-#
use Test::More;
use blib;

chdir 't' if -d 't';
require './setup.pl';

unless( have_crontab() ) {
    plan skip_all => "no crontab available";
}
plan tests => 43;

use_ok('Config::Crontab');

my $ct;

my $crontabf = ".tmp_crontab.$$";
my $crontabd = <<'_CRONTAB_';
MAILTO=scott

## logs nightly
#30 4 * * * /home/scott/bin/weblog.pl -v -s daily >> ~/tmp/logs/weblog.log 2>&1

## logs weekly
#35 4 * * 1 /home/scott/bin/weblog.pl -v -s weekly >> ~/tmp/logs/weblog.log 2>&1

## run a backup
20 2 * * 5 /usr/bin/tar -zcvf .backup/`$HOME/bin/dateish`.tar.gz ~/per
40 2 * * 5 /usr/bin/scp $HOME/.backup/`$HOME/bin/dateish`.tar.gz mx:~/backup/tub

## fetch ufo
13 9 * * 1-5 env DISPLAY=tub:0 ~/bin/fetch_image

## check versions
#MAILTO=phil
#10 5 * * 1-5 $HOME/fetch_version -q

## start spamd
@reboot /usr/local/bin/spamd -c -d -p 1783
_CRONTAB_

my $crontabd2 = <<'_CRONTAB_';
MAILTO=scott

## fetch ufo
13 9 * * 1-5 env DISPLAY=tub:0 ~/bin/fetch_image

## logs nightly
#30 4 * * * /home/scott/bin/weblog.pl -v -s daily >> ~/tmp/logs/weblog.log 2>&1

## run a backup
20 2 * * 5 /usr/bin/tar -zcvf .backup/`$HOME/bin/dateish`.tar.gz ~/per
40 2 * * 5 /usr/bin/scp $HOME/.backup/`$HOME/bin/dateish`.tar.gz mx:~/backup/tub

## logs weekly
#35 4 * * 1 /home/scott/bin/weblog.pl -v -s weekly >> ~/tmp/logs/weblog.log 2>&1

## start spamd
@reboot /usr/local/bin/spamd -c -d -p 1783

## check versions
#MAILTO=phil
#10 5 * * 1-5 $HOME/fetch_version -q
_CRONTAB_

my $crontabd3 = <<'_CRONTAB_';
MAILTO=scott

## fetch ufo
13 9 * * 1-5 env DISPLAY=tub:0 ~/bin/fetch_image

## logs nightly
#30 4 * * * /home/scott/bin/weblog.pl -v -s daily >> ~/tmp/logs/weblog.log 2>&1

## logs weekly
#35 4 * * 1 /home/scott/bin/weblog.pl -v -s weekly >> ~/tmp/logs/weblog.log 2>&1

## start spamd
@reboot /usr/local/bin/spamd -c -d -p 1783

## check versions
#MAILTO=phil
#10 5 * * 1-5 $HOME/fetch_version -q

## run a backup
20 2 * * 5 /usr/bin/tar -zcvf .backup/`$HOME/bin/dateish`.tar.gz ~/per
40 2 * * 5 /usr/bin/scp $HOME/.backup/`$HOME/bin/dateish`.tar.gz mx:~/backup/tub
_CRONTAB_

## write a crontab file
open FILE, ">$crontabf"
  or die "Couldn't open $crontabf: $!\n";
print FILE $crontabd;
close FILE;

## read our crontab
$ct = new Config::Crontab( -file => $crontabf );
ok( $ct->read, "read" );
is( $ct->dump, $crontabd, "dump" );

## rearrange the furniture
ok( $ct->up($ct->block($ct->select( data_re => 'start spamd' ))), "up" );
ok( $ct->down($ct->block($ct->select( data_re => 'logs weekly' ))), "down" );
ok( $ct->first($ct->block($ct->select( data_re => 'fetch ufo' ))), "first" );
ok( $ct->down($ct->block($ct->select( data_re => 'fetch ufo' ))), "down" );
is( $ct->dump, $crontabd2, "dump clean" );
ok( $ct->write, "write" );
undef $ct;

## read our file again
$ct = new Config::Crontab;
$ct->file($crontabf);
$ct->read;
is( $ct->dump, $crontabd2, "dump clean" );

## more furniture adjustments
ok( $ct->last($ct->block($ct->select( data_re => 'run a backup' ))), "last" );
is( $ct->dump, $crontabd3, "dump clean" );

## write to a different file
ok( $ct->file(".foo_" . $crontabf), "new file" );
ok( $ct->write, "write" );
undef $ct;

## test a pipe with 'new'
$ct = new Config::Crontab( -file => "cat $crontabf|" );
$ct->read;
is( $ct->dump, $crontabd2, "dump clean" );
undef $ct;

## test a pipe with 'new'
$ct = new Config::Crontab( -file => "perl -ne 'print' $crontabf|" );
$ct->read;
is( $ct->dump, $crontabd2, "dump clean" );
undef $ct;

## test a pipe with 'file'
$ct = new Config::Crontab;
$ct->file("perl -ne 'print' $crontabf|");
$ct->read;
is( $ct->dump, $crontabd2, "dump clean" );
undef $ct;

## test a pipe with 'file'
$ct = new Config::Crontab;
$ct->read( -file => "perl -ne 'print' $crontabf|" );
is( $ct->dump, $crontabd2, "dump clean" );
undef $ct;

##
$ct = new Config::Crontab( -file => ".foo_" . $crontabf );
ok( $ct->read, "read" );
is( $ct->dump, $crontabd3, "dump clean" );

## make sure nothing bad happened to this file
ok( $ct->file($crontabf) );
ok( $ct->read );
is( $ct->dump, $crontabd2, "dump clean" );

## make all the comments last
$ct = new Config::Crontab( -file => $crontabf );
ok( $ct->read, "read" );
for my $block ( $ct->blocks ) {
    $block->last($block->select( type => 'comment' ));
}
undef $ct;

## do mode tests

## line tests turned out to be "shoot the arrow, whatever it hits, call the target"
$ct = new Config::Crontab( -file => $crontabf,
                           -mode => 'line' );
is( $ct->mode, 'line', "line mode" );
ok( $ct->read, "read" );
is( $ct->blocks, $ct->select, "blocks selected" );

my $crontabd4 = $crontabd2; $crontabd4 =~ s/(\S)\n(\S)/$1\n\n$2/sg;
is( $ct->dump, $crontabd4, "dump clean" );
undef $ct;

## file tests
$ct = new Config::Crontab( -file => $crontabf,
                           -mode => 'file' );
is( $ct->mode, 'file', "file mode" );
ok( $ct->read, "read" );
is( $ct->dump, $crontabd2, "dump clean" );
undef $ct;

## do squeeze tests
my $crontabd5 = <<_CRONTAB_;
## comment 1
5 8 * * * /bin/command1


## for best results
## squeeze from end of tube
5 10 * * * /bin/command2









## comment 3
MAILTO=joe
0 0 * * Fri /bin/backup


_CRONTAB_

open FILE, ">$crontabf"
  or die "Could not open $crontabf: $!\n";
print FILE $crontabd5;
close FILE;

## squeeze: FIXME: squeeze(0) doesn't work properly
$ct = new Config::Crontab( -file    => $crontabf,
                           -squeeze => 0 );
ok( $ct->squeeze(1) );  ## squeeze
ok( $ct->read );
is( $ct->dump, <<_CRONTAB_, "squeeze dump clean" );
## comment 1
5 8 * * * /bin/command1

## for best results
## squeeze from end of tube
5 10 * * * /bin/command2

## comment 3
MAILTO=joe
0 0 * * Fri /bin/backup
_CRONTAB_
undef $ct;


## test reading/writing from a nonexistent file: strict should take effect here
$ct = new Config::Crontab( -file => ".tmp_foo.$$" );
ok( $block = new Config::Crontab::Block, "new block" );
ok( $block->last( new Config::Crontab::Event( -data => '5 10 15 20 Mon /bin/monday' ) ), "last" );
ok( $ct->last($block), "last again" );
ok( $ct->write, "write" );
undef $ct;

$ct = new Config::Crontab( -file => ".tmp_foo.$$" );
is( $ct->dump, <<_DUMP_, "strict good" );
5 10 15 20 Mon /bin/monday
_DUMP_
undef $ct;
unlink ".tmp_foo.$$";

eval { $ct = new Config::Crontab( -file => ".tmp_foo.$$", -strict => 1 ) };
ok( $@, "strict error" );

undef $ct;
eval { $ct = new Config::Crontab( -file => ".tmp_foo.$$", -strict => 0 ) };
ok( !$@, "unstrict clean" );

SKIP: {
    skip "WRITE_CRONTAB not set", 2 unless $ENV{WRITE_CRONTAB};

    undef $ct;
    $ct = new Config::Crontab;
    $block = new Config::Crontab::Block;
    $block->last( new Config::Crontab::Event( -data => '5 * * * * /bin/true' ) );
    $ct->last($block);
    ok($ct->write, "crontab written");

    undef $ct;
    $ct = new Config::Crontab;
    $ct->read;
    like($ct->dump, qr(^5.*/bin/true$), "crontab written");
    $ct->remove_tab;
}

## we don't test non-squeeze mode because it doesn't really work

END {
    unlink $crontabf;
    unlink ".foo_$crontabf";
    unlink ".tmp_foo.$$";
}

## this is a test for trying to write bogus data into the crontab
#perl -Mblib -MConfig::Crontab -e '$c=new Config::Crontab; $c->read; $c->last(new Config::Crontab::Block(-data => "## testing\n5 * * * Buz /bin/date")); $c->write or die "Bad write: $@\n"'
