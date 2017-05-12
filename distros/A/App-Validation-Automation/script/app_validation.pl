#!/usr/local/bin/perl -w

use strict;
use Carp;
use App::Validation::Automation;
use Config::Simple;
use Crypt::Lite;
use Getopt::Long;
use Error::TryCatch;
use English qw( -no_match_vars );

my ($config_file, $secret_pphrase, %config, $obj, $msg, $day_time, $day, 
    $time, $mon, $year, $date_stamp, $log_file_name, $force_run, $config);

#Command line processing and Validation
GetOptions(
    'c=s' => \$config_file,
    'p=s' => \$secret_pphrase,
    'f=s' => \$force_run,
);
usage() if((not $config_file) || (not $secret_pphrase)); 
confess "Config File doesn't exist/size 0" if(not -s $config_file);

try {
    #Parse and Store config 
    %config = Config::Simple->new($config_file)->vars();
    #Read password from encrypted file loc. stored in config
    $config{'COMMON.PASSWORD'} = decrypt_encypted_pass($secret_pphrase);

    #Create log file and open handle
    ( $day, $mon, $year ) = ( localtime( time ) )[3,4,5];
    $date_stamp    = ( $year + 1900 ).( $mon + 1 ).$day;
    $log_file_name = $0."_".$date_stamp.".".$config{'COMMON.LOG_EXTN'};

    open my $log_handle,">>", "$config{'COMMON.LOG_DIR'}/$log_file_name"
            || confess "$config{'COMMON.LOG_DIR'}/$log_file_name : $OS_ERROR";

    $obj = App::Validation::Automation->new(
        config          => \%config,
        log_file_handle => $log_handle,
        user_name       => $config{'COMMON.USER'},
        password        => $config{'COMMON.PASSWORD'},
        site            => $config{'COMMON.SITE'},
        zone            => $config{'COMMON.ZONE'},
        secret_pphrase  => $secret_pphrase,
    );

    #Sleep if maintenance is on and force not specified
    if( ( is_mtce_on() ) and (not defined $force_run)){ 
        $msg 
            = "Maintenance on - $config{'COMMON.MTCE_WINDOW'} .. Exiting! \n";
        $msg .= "To run in mtce windwo use the force cmd parameter\n";
        $obj->log($msg);
        printf "%s",$msg;
        usage();
    }

    #Validate App URLS
    $msg = $obj->validate_urls() ? "App URLS validated : OK"
                             : "App URLS validated : NOT OK";
    printf "%s", "$msg\n";
    $obj->log($msg);

    #Validate DNS round robin and load balancing
    $msg = $obj->test_dnsrr_lb() ? "DNS RR & LB validated : OK"
                             : "DNS RR & LB validated : NOT OK";
    printf "%s", "$msg\n";
    $obj->log($msg);

    #Validate App processes
    $msg = $obj->validate_processes_mountpoints() 
            ? "App processes and mountpoints Validated : OK"
            : "App processes and mountpoints Validated : NOT OK";
    printf "%s", "$msg\n";   
    $obj->log($msg);

    #Purge old log files as per RET_PERIOD
    $obj->purge();
}
catch Error::Unhandled with {
    $obj->log($@);
    confess $@;
}

sub decrypt_encypted_pass {

    # localize passphrase
    my $secret_pphrase = shift;
    my $crypt = Crypt::Lite->new();
    my ($encrypted_pass, $decrypted_pass);

    # Construct path of encrypted password file
    my $encrypted_pass_file_loc 
        = $config{'COMMON.DEFAULT_HOME'}."/".$config{'COMMON.ENC_PASS_LOC'};

    # Open file handle to password file
    open my $enc_file_handle,"<",$encrypted_pass_file_loc
        || confess "Could Not open $encrypted_pass_file_loc :: $OS_ERROR";
    {
        local $INPUT_RECORD_SEPARATOR = undef;
        $encrypted_pass = <$enc_file_handle>;
        # Decrypt whatever is stored in $encrypted_pass with $secret_pass_phrase
        $decrypted_pass = $crypt->decrypt($encrypted_pass,$secret_pphrase);
    }
    close $enc_file_handle;
 
    return $decrypted_pass;
}

sub is_mtce_on {

    my ($day_time, $day, $hour, $min, $time, $mtce_day, $mtce_start,
        $mtce_end);

    $day_time = scalar localtime(time);
    ($day, $hour, $min) = ($day_time =~ /^(\w+)\s+.+?(\d+?):(\d+?):\d+\s+/ );
    $time = $hour.$min;

    ($mtce_day, $mtce_start, $mtce_end)
        = ( $config{'COMMON.MTCE_WINDOW'} =~ /^(\w+)\s+(\d+)\-(\d+)$/ );

    return 1 if(       ($day =~ /$mtce_day/i) 
                   and (($mtce_start <= $time) and ($time <= $mtce_end)));

    return 0;
}

sub usage {
    printf "%s", <<EOF;
        Script not started with correct Args.The Correct way is -

        ./$0 -c <LOCATION_CONFIG_FILE> -p <SECRET_PASS_PHRASE> -f <FORCED_RUN>
EOF
    exit;
}

