#-*- mode: cperl -*-#
use Test::More;
use blib;

chdir 't' if -d 't';
require './setup.pl';

unless( have_crontab() ) {
    plan skip_all => "no crontab available";
    exit;
}
plan tests => 49;

use_ok('Config::Crontab');

my $ct;
my $crontabf = "_tmp_crontab.$$";
my @lines;
my $line;
my $block;

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

## write a crontab file
open FILE, ">$crontabf"
  or die "Couldn't open $crontabf: $!\n";
print FILE $crontabd;
close FILE;

## basic constructor tests (test auto-parse)
$ct = new Config::Crontab( -file => $crontabf );
is( $ct->file, $crontabf, "file output" );
is( $ct->dump, $crontabd, "clean dump" );

## select tests
@lines = $ct->select;
is( scalar @lines, 15, "crontab lines" );
@lines = $ct->select( type => 'event' );
is( scalar @lines, 7, "selection" );

## block tests
$block = $ct->block($lines[0]);  ## get the block this line is in
is( $block->dump, <<_DUMPED_, "dump block" );
## logs nightly
#30 4 * * * /home/scott/bin/weblog.pl -v -s daily >> ~/tmp/logs/weblog.log 2>&1
_DUMPED_

$block = $ct->block($lines[1]);
is( $block->dump, <<_DUMPED_, "dump block" );
## logs weekly
#35 4 * * 1 /home/scott/bin/weblog.pl -v -s weekly >> ~/tmp/logs/weblog.log 2>&1
_DUMPED_

$block = $ct->block($lines[2]);
is( $block->dump, <<'_DUMPED_', "dump block" );
## run a backup
20 2 * * 5 /usr/bin/tar -zcvf .backup/`$HOME/bin/dateish`.tar.gz ~/per
40 2 * * 5 /usr/bin/scp $HOME/.backup/`$HOME/bin/dateish`.tar.gz mx:~/backup/tub
_DUMPED_

$block = $ct->block($lines[3]);
is( $block->dump, <<'_DUMPED_', "dump block" );
## run a backup
20 2 * * 5 /usr/bin/tar -zcvf .backup/`$HOME/bin/dateish`.tar.gz ~/per
40 2 * * 5 /usr/bin/scp $HOME/.backup/`$HOME/bin/dateish`.tar.gz mx:~/backup/tub
_DUMPED_


## regular expression match
@lines = $ct->select( type   => 'event',
                      dow_re => '5' );
is( scalar @lines, 4 );

## negative regular expression match
@lines = $ct->select( type    => 'event',
                      dow_nre => '5' );
is( scalar @lines, 3 );

## string exact match
@lines = $ct->select( type => 'event',
                      dow  => '5' );
is( scalar @lines, 2 );

## tight regular expression
@lines = $ct->select( type   => 'event',
                      dow_re => '^5$' );
is( scalar @lines, 2 );

## tight negative regular expression
@lines = $ct->select( type    => 'event',
                      dow_nre => '^5$' );
is( scalar @lines, 5 );

## multiple fields
@lines = $ct->select( type   => 'event',
                      minute => '20',
                      dow_re => '^5$' );
is( scalar @lines, 1 );

## more complex expressions
@lines = $ct->select( type   => 'event',
                      dow_re => '(?:1|5)' );
is( scalar @lines, 5 );

@lines = $ct->select( type       => 'event',
                      command_re => 'dateish' );
is( scalar @lines, 2 );

## try doing some selects where the field does not exist in the object
is( @lines = $ct->select( -type   => 'event',
			  -foo_re => 'bar' ), 0 );
is( scalar @lines, 0 );

## test remove blocks
$block = $ct->block($ct->select(type => 'comment', data_re => 'logs nightly'));
ok( $ct->remove($block) );

my $crontabd2 = <<'_CRONTAB_';
MAILTO=scott

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
is( $ct->dump, $crontabd2, "dump compare" );

## "move" tests

$ct->last($block);
is( $ct->dump, <<'_DUMPED_', "block last" );
MAILTO=scott

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

## logs nightly
#30 4 * * * /home/scott/bin/weblog.pl -v -s daily >> ~/tmp/logs/weblog.log 2>&1
_DUMPED_

## grab the line above where this block used to live
($line) = $ct->select(type => 'env', value => 'scott');
is( $line->dump, 'MAILTO=scott', "selection" );

## now insert this block after the block containing our line
$ct->after($ct->block($line), $block);
is( $ct->dump, $crontabd, "dump after" );

## move it down one
$ct->down($block);

is( $ct->dump, <<'_DUMPED_', "after compare dump" );
MAILTO=scott

## logs weekly
#35 4 * * 1 /home/scott/bin/weblog.pl -v -s weekly >> ~/tmp/logs/weblog.log 2>&1

## logs nightly
#30 4 * * * /home/scott/bin/weblog.pl -v -s daily >> ~/tmp/logs/weblog.log 2>&1

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
_DUMPED_
undef $ct;


## test replace
$ct = new Config::Crontab( -file => $crontabf );
$block = new Config::Crontab::Block( -data => <<_BLOCK_ );
## new replacement block
FOO=bar
6 12 * * Thu /bin/thursday
_BLOCK_
$ct->replace($ct->block($ct->select(-data_re => 'run a backup')), $block);
is( $ct->dump, <<'_DUMPED_', "replacement dump" );
MAILTO=scott

## logs nightly
#30 4 * * * /home/scott/bin/weblog.pl -v -s daily >> ~/tmp/logs/weblog.log 2>&1

## logs weekly
#35 4 * * 1 /home/scott/bin/weblog.pl -v -s weekly >> ~/tmp/logs/weblog.log 2>&1

## new replacement block
FOO=bar
6 12 * * Thu /bin/thursday

## fetch ufo
13 9 * * 1-5 env DISPLAY=tub:0 ~/bin/fetch_image

## check versions
#MAILTO=phil
#10 5 * * 1-5 $HOME/fetch_version -q

## start spamd
@reboot /usr/local/bin/spamd -c -d -p 1783
_DUMPED_


## test selection and poking an element
$ct = new Config::Crontab( -file => $crontabf );
($ct->select(-command_re => 'weblog'))[0]->hour(5);
is( $ct->dump, <<'_DUMPED_', "replacement hour dump" );
MAILTO=scott

## logs nightly
#30 5 * * * /home/scott/bin/weblog.pl -v -s daily >> ~/tmp/logs/weblog.log 2>&1

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
_DUMPED_
undef $ct;


## test block removal using block select
$ct = new Config::Crontab;
$ct->read( -file => $crontabf );
is( $ct->dump, $crontabd, "compare read" );
for my $blk ( $ct->blocks ) {
    $blk->remove($blk->select( -type => 'comment' ));
    $blk->remove($blk->select( -type   => 'event',
			       -active => 0, ));
}
is( $ct->dump, <<'_CRONTAB_', "compare removed blocks" );
MAILTO=scott

20 2 * * 5 /usr/bin/tar -zcvf .backup/`$HOME/bin/dateish`.tar.gz ~/per
40 2 * * 5 /usr/bin/scp $HOME/.backup/`$HOME/bin/dateish`.tar.gz mx:~/backup/tub

13 9 * * 1-5 env DISPLAY=tub:0 ~/bin/fetch_image

#MAILTO=phil

@reboot /usr/local/bin/spamd -c -d -p 1783
_CRONTAB_
undef $ct;


## test block removal using crontab select
$ct = new Config::Crontab;
$ct->read( -file => $crontabf );
is( $ct->dump, $crontabd, "compare removed block via select" );
$ct->remove($ct->select( -type => 'comment' ));
$ct->remove($ct->select( -type => 'event',
			 -active => 0 ));
is( $ct->dump, <<'_CRONTAB_', "compre remove via select" );
MAILTO=scott

20 2 * * 5 /usr/bin/tar -zcvf .backup/`$HOME/bin/dateish`.tar.gz ~/per
40 2 * * 5 /usr/bin/scp $HOME/.backup/`$HOME/bin/dateish`.tar.gz mx:~/backup/tub

13 9 * * 1-5 env DISPLAY=tub:0 ~/bin/fetch_image

#MAILTO=phil

@reboot /usr/local/bin/spamd -c -d -p 1783
_CRONTAB_
undef $ct;


## test adding raw blocks
$ct = new Config::Crontab;
$ct->last(new Config::Crontab::Block( -data => <<_BLOCK_ ));
## eat ice cream
5 * * * 1-5 /bin/eat --cream=ice
_BLOCK_
is( $ct->dump, <<_BLOCK_, "add raw block" );
## eat ice cream
5 * * * 1-5 /bin/eat --cream=ice
_BLOCK_

$ct->last(new Config::Crontab::Block( -data => <<_BLOCK_ ));
## eat pizza
35 * * * 1-5 /bin/eat --pizza
_BLOCK_

is( $ct->dump, <<_BLOCK_, "add raw block" );
## eat ice cream
5 * * * 1-5 /bin/eat --cream=ice

## eat pizza
35 * * * 1-5 /bin/eat --pizza
_BLOCK_

unlink $crontabf;
$crontabd = <<'_CRONTAB_';
MAILTO=scott

## logs nightly
#30 4 * * * ipartner $HOME/bin/weblog.pl -v -s daily >> ~/tmp/logs/weblog.log 2>&1

## logs weekly
#35 4 * * 1 ipartner $HOME/bin/weblog.pl -v -s weekly >> ~/tmp/logs/weblog.log 2>&1

## run a backup
20 2 * * 5 root /usr/bin/tar -zcvf .backup/`$HOME/bin/dateish`.tar.gz ~/per
40 2 * * 5 root /usr/bin/scp $HOME/.backup/`$HOME/bin/dateish`.tar.gz mx:~/backup/tub

## fetch ufo
13 9 * * 1-5 scott env DISPLAY=tub:0 $HOME/bin/fetch_image

## check versions
#MAILTO=phil
#10 5 * * 1-5 phil $HOME/fetch_version -q

## start spamd
@reboot root /usr/local/bin/spamd -c -d -p 1783
_CRONTAB_

## write a crontab file
open FILE, ">$crontabf"
  or die "Couldn't open $crontabf: $!\n";
print FILE $crontabd;
close FILE;

$ct = new Config::Crontab( -file => $crontabf, -system => 1 );
is( ($ct->select(-command_re => 'weblog'))[0]->user, 'ipartner' );
is( ($ct->select(-command_re => 'fetch_image'))[0]->user, 'scott' );
is( ($ct->select(-user => 'phil'))[0]->dow, '1-5' );
is( ($ct->select(-user => 'root'))[1]->minute, '40' );
is( ($ct->select(-user => 'root'))[2]->special, '@reboot' );

## test pretty print for system crontab files
unlink $crontabf;
$crontabd = <<'_CRONTAB_';
MAILTO=scott

## logs nightly
#30	4	*	*	*	ipartner	$HOME/bin/weblog.pl -v -s daily >> ~/tmp/logs/weblog.log 2>&1

## logs weekly
#35	4	*	*	1	ipartner	$HOME/bin/weblog.pl -v -s weekly >> ~/tmp/logs/weblog.log 2>&1

## run a backup
20	2	*	*	5	root	/usr/bin/tar -zcvf .backup/`$HOME/bin/dateish`.tar.gz ~/per
40	2	*	*	5	root	/usr/bin/scp $HOME/.backup/`$HOME/bin/dateish`.tar.gz mx:~/backup/tub

## fetch ufo
13	9	*	*	1-5	scott	env DISPLAY=tub:0 $HOME/bin/fetch_image

## check versions
#MAILTO=phil
#10	5	*	*	1-5	phil	$HOME/fetch_version -q

## start spamd
@reboot					root	/usr/local/bin/spamd -c -d -p 1783
_CRONTAB_

## write a crontab file
open FILE, ">$crontabf"
  or die "Couldn't open $crontabf: $!\n";
print FILE $crontabd;
close FILE;

## test the purdy printin' for system crontab files
$ct = new Config::Crontab( -file => $crontabf, -system => 1 );
is( $ct->dump, $crontabd, "pretty print" );

## test select_blocks
my @blocks = $ct->select_blocks( -index => 1 );
is( ($blocks[0]->select( -type => 'comment' ))[0]->data, '## logs nightly' );

@blocks = $ct->select_blocks( -index => 2 );
is( ($blocks[0]->select( -type => 'event' ))[0]->user, 'ipartner' );

@blocks = $ct->select_blocks( -index => [0, 4, 7] );
is( ($blocks[0]->select( -type => 'env' ))[0]->value, 'scott' );
is( ($blocks[1]->select( -type => 'comment' ))[0]->data, '## fetch ufo' );
is( $blocks[2], undef, "undef" );

##
## try some owner tests
##
undef $ct;
$ct = new Config::Crontab;
$ct->owner('root');
is( $ct->owner, 'root', "owner" );

## stricter
$ct->strict(1);
eval { $ct->owner('somereallybogususername8838293') };
like( $@, qr(Unknown user)i, "unknown user" );

eval { $ct->owner("root\0 2>/dev/null; cat /etc/passwd") };
like( $@, qr(Illegal username)i, "illegal username" );

##
## test SuSE-specific nolog option
##
$crontabd =~ s/^(13\s+9\s+)/\-$1/m;

open FILE, ">$crontabf"
  or die "Couldn't open $crontabf: $!\n";
print FILE $crontabd;
close FILE;

$ct = new Config::Crontab( -file => $crontabf, -system => 1 );
my($blk) = $ct->select_blocks( -index => 4 );
is( $blk->dump, qq!## fetch ufo\n-13\t9\t*\t*\t1-5\tscott\tenv DISPLAY=tub:0 \$HOME/bin/fetch_image\n! );
($blk->select(-type => 'event'))[0]->nolog(0);
is( $blk->dump, qq!## fetch ufo\n13\t9\t*\t*\t1-5\tscott\tenv DISPLAY=tub:0 \$HOME/bin/fetch_image\n! );

END {
    unlink $crontabf;
}
