#!/usr/bin/perl
use strict;
use warnings;

use Cwd;
use Data::Dumper;
use English qw( -no_match_vars );
use Test::More;

if ( $OSNAME =~ /cygwin|win32|windows/i ) {
    plan skip_all => "no windows support";
};

use lib 'lib';
use lib 'inc';

use_ok( 'Apache::Logmonster' );
use_ok( 'Apache::Logmonster::Utility' );

# let the testing begin

# basic OO mechanism

my $logmonster = Apache::Logmonster->new(0);
ok ($logmonster, 'new logmonster object');

my $util = $logmonster->get_util();
my $conf = $logmonster->get_config( 'logmonster.conf',debug=>0 );
ok ($conf, 'logmonster conf object');
ok (ref $conf, 'logmonster conf object');

## new
#warn Dumper($conf);

my $original_working_directory = cwd;
#warn "my owd is $original_working_directory";

# override logdir from logmonster.conf
$logmonster->{conf}{logbase} = "$original_working_directory/t/trash";
$logmonster->{conf}{logdir}  = "$original_working_directory/t/trash";
$logmonster->{conf}{tmpdir}  = "$original_working_directory/t/trash";

my $log_fh;

## check_config
    ok( $logmonster->check_config(), 'check_config');

## get_log_dir
    $logmonster->{'conf'}->{'rotation_interval'} = "hour";
    ok( my $logdir = $logmonster->get_log_dir(), 'get_log_dir hour');
    #print "     logdir: $logdir\n";

    $logmonster->{'conf'}->{'rotation_interval'} = "day";
    ok( $logdir = $logmonster->get_log_dir(), 'get_log_dir day');
    #print "     logdir: $logdir\n";

    $logmonster->{'conf'}->{'rotation_interval'} = "month";
    ok( $logdir = $logmonster->get_log_dir(), 'get_log_dir month');
    #print "     logdir: $logdir\n";

## report_open
    $log_fh = $logmonster->report_open("Logmonster",0);
    ok( $log_fh, 'report_open');
    $logmonster->{'report'} = $log_fh;

# report_hits: set up a dummy hits file
    ## report_open
    my $hits_fh = $logmonster->report_open("HitsPerVhost",0);
    ok( $hits_fh, 'report_open');

    # dump sample data into the file
    print $hits_fh "mail-toaster.org:49300\nexample.com:13\n";

    ## report_close
    $logmonster->report_close($hits_fh);


## report_hits
    if ( -e "/tmp/HitsPerVhost.txt" ) {
        ok( $logmonster->report_hits("/tmp"), 'report_hits');
        unlink "/tmp/HitsPerVhost.txt";
    } 
    else {
        ok( $logmonster->report_hits(), 'report_hits');
    };

## compress_log_file
#    ok( $logmonster->compress_log_file(
#        "matt.cadillac.net", 
#        "/var/log/apache/2006/09/29/access.log",
#    ), 'compress_log_file');


## consolidate_logfile
#    ok( $logmonster->consolidate_logfile(
#        "matt.cadillac.net", 
#        "/var/log/apache/2006/09/29/access.log.gz",
#        "t/trash/matt.cadillac.net-access.log.gz",
#    ), 'consolidate_logfile');


## fetch_log_files
#    $conf->{'logbase'} = "/var/log/apache";
#    ok( $logmonster->fetch_log_files(), 'fetch_log_files');
    

    $logmonster->{'debug'} = 0;
    $logmonster->{'clean'} = 0;

## check_stats_dir
    if ( ! -d "t/trash/doms" ) {
        system("/bin/mkdir -p t/trash/doms");
    };


## sort_vhost_logs
#    ok ( $logmonster->sort_vhost_logs(), 'sort_vhost_logs');


## check_awstats_file


## install_default_awstats_conf


## report_close
    ok( $logmonster->report_close($log_fh, 0), 'report_close');

done_testing();
