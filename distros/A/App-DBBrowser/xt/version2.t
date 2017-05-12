use 5.010000;
use strict;
use warnings;

use File::Basename qw(basename);
use Time::Piece;
use Test::More;


my $v_changes     = -1;
my $v_lib         = -1;
my $v_lib_pod     = -1;
my $v_bin         = -1;
my $v_browser     = -1;
my $v_opt         = -1;
my $v_db          = -1;
my $v_db_pod      = -1;
my $v_tbl         = -1;
my $v_ju          = -1;
my $v_ut          = -1;
my $v_insert      = -1;
my $v_bin_pod     = -1;
my $v_browser_pod = -1;
my $release_date  = -1;


my $lib = 'lib/App/DBBrowser.pm';
open my $fh1, '<', $lib or die $!;
while ( my $line = <$fh1> ) {
    if ( $line =~ /^our\ \$VERSION\ =\ '(\d\.\d\d\d(?:_\d\d)?)';/ ) {
        $v_lib = $1;
    }
    if ( $line =~ /\A=pod/ .. $line =~ /\A=cut/ ) {
        if ( $line =~ /^\s*Version\s+(\S+)/ ) {
            $v_lib_pod = $1;
        }
    }
}
close $fh1;


my $bin = 'bin/db-browser';
open my $fh2, '<', $bin or die $!;
my $count;
while ( my $line = <$fh2> ) {
    if ( $line =~ /^our\ \$VERSION\ =\ '(\d\.\d\d\d(?:_\d\d)?)';/ ) {
        $count++;
        if ( $count == 1 ) {
            $v_bin = $1;
        }
        else {
            $v_db = $1;
        }
    }
    if ( $line =~ /^=pod/ .. $line =~ /\A=cut/ ) {
        if ( $line =~ /^\s*Version\s+(\S+)/ ) {
            $v_bin_pod = $1;
        }
    }
}
close $fh2;


my $browser = 'lib/App/DBBrowser.pm';
open my $fh3, '<', $browser or die $!;
while ( my $line = <$fh3> ) {
    if ( $line =~ /^our\ \$VERSION\ =\ '(\d\.\d\d\d(?:_\d\d)?)';/ ) {
        $v_browser = $1;
    }
    if ( $line =~ /^=pod/ .. $line =~ /\A=cut/ ) {
        if ( $line =~ /^\s*Version\s+(\S+)/ ) {
            $v_browser_pod = $1;
        }
    }
}
close $fh3;

my $opt = 'lib/App/DBBrowser/Opt.pm';
open my $fh4, '<', $opt or die $!;
while ( my $line = <$fh4> ) {
    if ( $line =~ /^our\ \$VERSION\ =\ '(\d\.\d\d\d(?:_\d\d)?)';/ ) {
        $v_opt = $1;
    }
}
close $fh4;

my $db = 'lib/App/DBBrowser/DB.pm';
open my $fh5, '<', $db or die $!;
while ( my $line = <$fh5> ) {
    if ( $line =~ /^our\ \$VERSION\ =\ '(\d\.\d\d\d(?:_\d\d)?)';/ ) {
        $v_db = $1;
    }
    if ( $line =~ /^=head1 VERSION/ .. $line =~ /^=head1 DESCRIPTION/ ) {
        if ( $line =~ /^\s*Version\s+(\S+)/ ) {
            $v_db_pod = $1;
        }
    }
}
close $fh5;

my $tbl = 'lib/App/DBBrowser/Table.pm';
open my $fh6, '<', $tbl or die $!;
while ( my $line = <$fh6> ) {
    if ( $line =~ /^our\ \$VERSION\ =\ '(\d\.\d\d\d(?:_\d\d)?)';/ ) {
        $v_tbl = $1;
    }
}
close $fh6;

my $ju = 'lib/App/DBBrowser/Join_Union.pm';
open my $fh7, '<', $ju or die $!;
while ( my $line = <$fh7> ) {
    if ( $line =~ /^our\ \$VERSION\ =\ '(\d\.\d\d\d(?:_\d\d)?)';/ ) {
        $v_ju = $1;
    }
}
close $fh7;

my $ut = 'lib/App/DBBrowser/Auxil.pm';
open my $fh8, '<', $ut or die $!;
while ( my $line = <$fh8> ) {
    if ( $line =~ /^our\ \$VERSION\ =\ '(\d\.\d\d\d(?:_\d\d)?)';/ ) {
        $v_ut = $1;
    }
}
close $fh8;

my $insert = 'lib/App/DBBrowser/Table/Insert.pm';
open my $fh9, '<', $insert or die $!;
while ( my $line = <$fh9> ) {
    if ( $line =~ /^our\ \$VERSION\ =\ '(\d\.\d\d\d(?:_\d\d)?)';/ ) {
        $v_insert = $1;
    }
}
close $fh9;

open my $fh_ch, '<', 'Changes' or die $!;
while ( my $line = <$fh_ch> ) {
    if ( $line =~ /^\s*(\d\.\d\d\d(?:_\d\d)?)\s+(\d\d\d\d-\d\d-\d\d)\s*\Z/ ) {
        $v_changes = $1;
        $release_date = $2;
        last;
    }
}
close $fh_ch;


my $t = localtime;
my $today = $t->ymd;


is( $v_lib,        $v_changes,     'Version in "Changes" OK' );
is( $v_lib,        $v_lib_pod,     'Version in "' . basename( $lib ) .   '" POD OK');
is( $v_lib,        $v_bin,         'Version in "' . basename( $bin ) .       '" OK');
is( $v_lib,        $v_bin_pod,     'Version in "' . basename( $bin ) .   '" POD OK');
is( $v_lib,        $v_browser,     'Version in "App::DBBrowser::Browser"        OK');
is( $v_lib,        $v_browser_pod, 'Version in "App::DBBrowser::Browser"    POD OK');
is( $v_lib,        $v_opt,         'Version in "App::DBBrowser::Opt"            OK');
is( $v_lib,        $v_db,          'Version in "App::DBBrowser::DB"             OK');
is( $v_lib,        $v_db_pod,      'Version in "App::DBBrowser::DB"         POD OK');
is( $v_lib,        $v_tbl,         'Version in "App::DBBrowser::Table"          OK');
is( $v_lib,        $v_ju,          'Version in "App::DBBrowser::Join_Union"     OK');
is( $v_lib,        $v_ut,          'Version in "App::DBBrowser::Auxil"          OK');
is( $v_lib,        $v_insert,      'Version in "App::DBBrowser::Table::Insert"  OK');
is( $release_date, $today,         'Release date in Changes is date from today'   );



done_testing();
