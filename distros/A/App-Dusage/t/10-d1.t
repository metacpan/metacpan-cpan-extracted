#!perl

use strict;
use warnings;

use Test::More tests => 7;

chdir('..') if -d '../t';

require_ok( './script/dusage' );

open( my $fd, '>', 't/du.tst' );
ok( $fd, "create du.tst" );

print $fd ( <<EOD );
# glob lib/* -> lib/App
# glob * -> blib lib script t
lib/*
*
EOD

ok( close($fd), 'created du.tst' );

test1();
test2();

sub test1 {
    @ARGV = qw(  -i t/du.d1 -u t/du.tst );

    app_options();
    parse_ctl();
    gather();

    my $res = "";
    open( my $out, '>', \$res );
    report_and_update($out);

    $res =~ s/^\n+//;
    $res =~ s/^Disk usage statistics.*\n+//;

    is( $res, <<EXP, "result" );
  blocks    +day     +week  directory
--------  -------  -------  --------------------------------
      20                    lib/App
     172                    blib
      24                    lib
      56                    script
      16                    t
EXP

    open( my $du, '<', 't/du.tst' );
    $res = do { local $/; <$du> };
    is( $res, <<EXP, "du.tst updated" );
# glob * -> blib lib script t
# glob lib/* -> lib/App
lib/App	20:::::::
lib/*
blib	172:::::::
lib	24:::::::
script	56:::::::
t	16:::::::
*
EXP
}

sub test2 {
    # Important: Reload!!!
    delete $INC{'./script/dusage'};
    require './script/dusage';

    @ARGV = qw(  -i t/du.d2 -u t/du.tst );

    app_options();
    parse_ctl();
    gather();

    my $res = "";
    open( my $out, '>', \$res );
    report_and_update($out);

    $res =~ s/^\n+//;
    $res =~ s/^Disk usage statistics.*\n+//;

    is( $res, <<EXP, "result" );
  blocks    +day     +week  directory
--------  -------  -------  --------------------------------
      19       -1           lib/App
     172        0           blib
      24        0           lib
      56        0           script
      20       +4           t
EXP

    open( my $du, '<', 't/du.tst' );
    $res = do { local $/; <$du> };
    is( $res, <<EXP, "du.tst updated" );
# glob * -> blib lib script t
# glob lib/* -> lib/App
lib/App	19:20::::::
lib/*
blib	172:172::::::
lib	24:24::::::
script	56:56::::::
t	20:16::::::
*
EXP
}
