package Apache::Logmonster;

use strict;
use warnings;

our $VERSION = '5.36';

use Carp;
use Compress::Zlib;
use Cwd;
#use Data::Dumper;
use Date::Parse;
use FileHandle;
use File::Basename;
use File::Copy;
use Regexp::Log;

use lib 'lib';
use Apache::Logmonster::Utility;
use Regexp::Log::Monster;
my ( $util, $err, %fhs, $debug );

sub new {
    my $class = shift;
    $debug = shift || 0;

    my $self = {
        conf  => undef,
        debug => $debug ? 1 : 0,
    };

    bless( $self, $class );

    $self->get_util();

    return $self;
};

sub check_awstats_file {
    my $self = shift;
    my $domain = shift;

    my $conf     = $self->{'conf'};
    my $confdir  = $conf->{confdir}  || '/etc/awstats';
    my $statsdir = $conf->{statsdir} || '/var/db/awstats';

    my $adc = "$confdir/awstats.$domain.conf";

    return if -f $adc;

    $util->file_write( $adc,
        lines => [
            <<"EO_AWSTATS_VHOST"
Include "$confdir/awstats.model.conf"
SiteDomain = $domain
DirData = $statsdir/$domain
HostAliases = $domain localhost 127.0.0.1
EO_AWSTATS_VHOST
        ],
        debug => 0,
    ); 
};

sub check_config {
    my $self  = shift;
    my $conf  = $self->{'conf'};

    $err = "performing sanity tests";
    $self->_progress_begin($err) if $debug;

    print "\n\t verbose mode $debug\n" if $debug > 1;

    if ( $debug > 1 ) {
        print "\t clean mode ";
        print $conf->{'clean'} ? "enabled.\n" : "disabled.\n";
    }

    my $tmpdir = $conf->{tmpdir};
    print "\t temporary working directory is $tmpdir.\n" if $debug > 1;

    if ( ! -d $tmpdir ) {
        print "\t temp dir does not existing, creating..." if $debug > 1;
        if ( !mkdir $tmpdir, oct('0755') ) {
            die "FATAL: The directory $tmpdir does not exist and I could not "
                . "create it. Edit logmonster.conf or create it.\n";
        }
        print "done.\n" if $debug > 1;

        # this will fail unless we're root, but that should not matter much
        print "\t setting permissions on temp dir..." if $debug > 1;
        $util->chown( $tmpdir,
            uid         => $conf->{'log_user'} || 'www',
            gid         => $conf->{'log_group'} || 'www',
            debug       => $debug > 1 ? 1 : 0,
            fatal       => 0,
        );
        print "done.\n" if $debug > 1;
    }

    if ( !-w $tmpdir || !-r $tmpdir ) {
        croak "FATAL: \$tmpdir ($tmpdir) must be read and writable!";
    }

    if ( $conf->{'clean'} ) {
        if ( !$util->clean_tmp_dir( $tmpdir, debug => 1, fatal=>0 ) ) {
            croak "\nfailed to clean out $tmpdir";
        }
    }

    die "\nFATAL: you must edit logmonster.conf and set default_vhost!\n"
        if ! defined $conf->{'default_vhost'};

    if ( $conf->{'time_offset'} ) {
        my ( $dd, $mm, $yy, $lm, $hh, $mn ) = $util->get_the_date( debug=>0 );

        my $interval = $self->{rotation_interval} || 'day';
        my $bump     = $conf->{time_offset};
        my $logbase  = $conf->{logbase};

        my $how_far_back = $interval eq "hour"  ? .04      # back 1 hour
                         : $interval eq "month" ? $dd + 1  # last month
                         :                        1;       # 1 day

        ( $dd, $mm, $yy, $lm, $hh, $mn )
            = $util->get_the_date( bump => $bump + $how_far_back, debug => 0 );

        die "OK then, try again.\n"
            if ! $util->yes_or_no( 
                "\nDoes the date $yy/$mm/$dd look correct? ");
    }

    $self->_progress_end('passed') if $debug == 1;

    return 1;
};

sub compress_log_file {
    my $self    = shift;
    my $host    = shift;
    my $logfile = shift;

    my $debug = $self->{'debug'};

    unless ( $host && $logfile ) {
        croak "compress_log_file: called incorrectly!";
    }

    my $REPORT = $self->{'report'};

    if ( $host eq "localhost" ) {
        my $gzip = $util->find_bin( 'gzip', debug => 0 );

        if ( !-e $logfile ) {
            print $REPORT "compress_log_file: $logfile does not exist!\n";
            if ( -e "$logfile.gz" ) {
                print $REPORT "     already compressed as $logfile.gz!\n";
                return 1;
            }
            return;
        }

        my $cmd = "$gzip $logfile";
        $self->_progress("gzipping localhost:$logfile") if $debug;
        print $REPORT "syscmd: $cmd\n";
        my $r = $util->syscmd( $cmd, debug => 0 );
        print $REPORT "syscmd: error result: $r\n" if ( $r != 0 );

        return 1;
    }

    $self->_progress_begin("checking $host for $logfile") if $debug;

    # $host is remote, so we interact via SSH
    my $ssh = $util->find_bin( "ssh", debug => 0 );
    my $cmd = "$ssh $host test -f $logfile";

    print $REPORT "compress_log_file: checking $host\n";
    print $REPORT "\tsyscmd: $cmd\n";

    $self->_progress_continue() if $debug;

    # does the file exist?
    if ( !$util->syscmd( $cmd, debug => 0, fatal => 0 ) ) {
        $self->_progress_continue() if $debug;

        # does file.gz exist?
        if ( -f "$logfile.gz" ) {
            $err = "ALREADY COMPRESSED";
            print $REPORT "\t$err\n";

            $self->_progress_end($err) if $debug;

            return 1;
        }
        $self->_progress_end("no") if $debug;

        print $REPORT "no\n";
        return;
    }

    $self->_progress_end("yes") if $debug;

    print $REPORT "yes\n";

    $err = "compressing log file on $host";
    $self->_progress_begin($err) if $debug;

    $cmd = "$ssh $host gzip $logfile";
    print $REPORT "\tcompressing\n\tsyscmd: $cmd \n";

    $self->_progress_continue() if !$debug;

    my $r = $util->syscmd( $cmd, debug => 0, fatal => 0 );
    if ( !$r ) {
        print $REPORT "\terror result: $r\n";
        return;
    }
    $debug
        ? print "done\n"
        : $self->_progress_end();

    return 1;
};

sub consolidate_logfile {

    my $self           = shift;
    my $host           = shift;
    my $remote_logfile = shift;
    my $local_logfile  = shift;

    my $dry_run = $self->{'dry_run'};
    my $debug   = $self->{'debug'};
    my $REPORT  = $self->{'report'};

    my ( $r, $size );

    # retrieve yesterdays log files
    if ( $host eq "localhost" ) {
        $err
            = "consolidate_logfile: checking localhost for\n\t $remote_logfile...";
        $self->_progress_begin($err) if $debug;
        print $REPORT $err;

        # requires "use File::Copy"
        $r = copy $remote_logfile, $local_logfile;
        print $REPORT "FAILED: $!\n" unless ($r);

        $size = ( stat $local_logfile )[7];

        if ( $size > 1000000 ) { $size = sprintf "%.2f MB", $size / 1000000; }
        else                   { $size = sprintf "%.2f KB", $size / 1000; }

        $err = "retrieved $size\n";
        $self->_progress_end($err) if $debug;
        print $REPORT $err;
        return 1;
    }

    return 1 if $dry_run;

    my $scp = $util->find_bin( "scp", debug => 0 );
    $scp .= " -q";

    $self->_progress_begin("\tconsolidate_logfile: fetching") if $debug;

    print $REPORT
        "\tsyscmd: $scp \n\t\t$host:$remote_logfile \n\t\t$local_logfile\n";

    $r = $util->syscmd( "$scp $host:$remote_logfile $local_logfile",
        debug => 0
    );
    print $REPORT "syscmd: error result: $r\n" if !$r;

    $size = ( stat $local_logfile )[7];
    if ( !$size ) {
        $err = "FAILED. No logfiles retrieved!";
        $self->_progress_end($err) if $debug;
        print $REPORT "\t $err \n";
        return;
    }

    if   ( $size > 1000000 ) { $size = sprintf "%.2f MB", $size / 1000000; }
    else                     { $size = sprintf "%.2f KB", $size / 1000; }

    $err = "retrieved $size";
    $self->_progress_end($err) if $debug;
    print $REPORT "\t $err\n";

    return 1;
};

sub feed_the_machine {
    my $self        = shift;
    my $domains_ref = shift;

    if ( !$domains_ref || ref $domains_ref ne 'HASH' ) {
        croak "feed_the_machine: invalid parameters passed.";
    }

    my $debug    = $self->{'debug'};
    my $conf     = $self->{'conf'};
    my $REPORT   = $self->{'report'};
    my $interval = $self->{'rotation_interval'};

    my ( $cmd, $r );

    my $tmpdir    = $conf->{'tmpdir'};
    my $processor = $conf->{'processor'};

    foreach my $file ( $util->get_dir_files( "$tmpdir/doms" ) ) {
        next if ( $file =~ /\.bak$/ );

        use File::Basename;
        my $domain   = fileparse($file);
        my $statsdir = "$conf->{'statsdir'}/$domain";

        $util->cwd_source_dir( $statsdir, debug => 0 );

        if ( ! -d $statsdir ) {
            print "skipping $file because $statsdir is not a directory.\n"
                if $debug;
            next;
        };

        # allow domain to select their stats processor
        if ( -f "$statsdir/.processor" ) {
            $processor = `head -n1 $statsdir/.processor`;
            chomp $processor;
        }

        if ( $processor eq "webalizer" ) {
            my $webalizer
                = $util->find_bin( "webalizer", debug => 0 );
            $webalizer .= " -q" if !$debug;
            $webalizer .= " -p"
                if ( $interval eq "hour" || $interval eq "day" );
            $cmd = "$webalizer -n $domain -o $statsdir $file";
            printf "$webalizer -n %-20s -o $statsdir\n", $domain if $debug;
            printf $REPORT "$webalizer -n %-20s -o $statsdir\n", $domain;
        }
        elsif ( $processor eq "http-analyze" ) {
            my $http_analyze
                = $util->find_bin( "http-analyze", debug => 0 );
            $http_analyze .= " -d"
                if ( $interval eq "hour" || $interval eq "day" );
            $http_analyze .= " -m" if ( $interval eq "month" );
            $cmd = "$http_analyze -S $domain -o $statsdir $file";
            printf "$http_analyze -S %-20s -o $statsdir\n", $domain if $debug;
            printf $REPORT "$http_analyze -S %-20s -o $statsdir\n", $domain;
        }
        elsif ( $processor eq "awstats" ) {
            $self->check_awstats_file( $domain );

            my $aws_cgi = "/usr/local/www/awstats/cgi-bin"; # freebsd port location
            $aws_cgi = "/usr/local/www/cgi-bin" unless -d $aws_cgi;
            $aws_cgi = "/var/www/cgi-bin"       unless -d $aws_cgi;

            my $awstats = $util->find_bin( "awstats.pl",
                debug => 0,
                dir   => $aws_cgi,
            );
            $cmd = "$awstats -config=$domain -logfile=$file";
            printf "$awstats for \%-20s to $statsdir\n", $domain if $debug;
            printf $REPORT "$awstats for \%-20s to $statsdir\n", $domain;
        }
        else {
            $err = "Sorry, that is not supported! Valid options are: webalizer, http-analyze, and awstats.\n";
            print $err;
            print $REPORT $err;
        }

        unless ( $self->{'dry_run'} ) {
            print "running $processor!\n"  if $debug;
            print $REPORT "syscmd: $cmd\n" if $debug;
            $r = $util->syscmd( $cmd, debug => 0 );
            print $REPORT "syscmd: error result: $r\n" if ( $r != 0 );
        }


        if ( $conf->{'clean'} ) {
            $util->file_delete( $file, debug => 0 );
            next;
        }

        print "\nDon't forget about $file\n";
        print $REPORT "\nDon't forget about $file\n";
    }
};

sub fetch_log_files {

    my $self    = shift;
    my $debug   = $self->{'debug'};
    my $conf    = $self->{'conf'};
    my $dry_run = $self->{'dry_run'};

    my $r;

    # in a format like this: /var/log/apache/200?/09/25
    my $logdir = $self->get_log_dir();
    my $tmpdir = $conf->{'tmpdir'};

    my $access_log = "$logdir/" . $conf->{'access'};
    my $error_log  = "$logdir/" . $conf->{'error'};

    print "fetch_log_files: warming up.\n" if $debug > 1;

WEBHOST:
    foreach my $webserver ( split( / /, $conf->{'hosts'} ) ) {
        my $compressed = 0;

        if ( !$dry_run ) {

            # compress yesterdays log files
            $self->compress_log_file( $webserver, $error_log );

            if ( !$self->compress_log_file( $webserver, $access_log ) ) {

                # if there is no compressed logfile, there is no point in
                # trying to retrieve.
                next WEBHOST;
            }
        }

        my $local_logfile = "$tmpdir/$webserver-" . $conf->{'access'} . ".gz";

        $self->consolidate_logfile(
            $webserver,          # hostname to retrieve from
            "$access_log.gz",    # the logfile to fetch
            $local_logfile,      # where to put it
        );
    }

    return 1;
};

sub get_log_dir {

    my $self  = shift;
    my $debug = $self->{'debug'};
    my $conf  = $self->{'conf'};

    my $interval = $self->{'rotation_interval'} || "day";

    unless ($conf) {
        croak "get_log_dir: \$conf is not set!\n";
    }

    my $bump    = $conf->{'time_offset'};
    my $logbase = $conf->{'logbase'};

    my ( $dd, $mm, $yy, $lm, $hh, $mn ) = $util->get_the_date( debug => 0 );

    my $how_far_back = $interval eq "hour"
        ? .04    # back 1 hour
        : $interval eq "month" ? $dd + 1    # last month
        :                        1;         # 1 day

    if ($bump) {
        ( $dd, $mm, $yy, $lm, $hh, $mn ) = $util->get_the_date(
            bump  => $bump + $how_far_back,
            debug => $debug > 1 ? 1 : 0,
        );
    }
    else {
        ( $dd, $mm, $yy, $lm, $hh, $mn ) = $util->get_the_date(
            bump  => $how_far_back,
            debug => $debug > 1 ? 1 : 0,
        );
    }

    my $logdir
        = $interval eq "hour"  ? "$logbase/$yy/$mm/$dd/$hh"
        : $interval eq "day"   ? "$logbase/$yy/$mm/$dd"
        : $interval eq "month" ? "$logbase/$yy/$mm"
        :                        "$logbase";

    print "get_log_dir: using $logdir\n" if $debug > 1;
    return $logdir;
};

sub get_log_files {
    my $self = shift;
    my $dir = shift or die "missing dir argument";

    my @logs = glob("$dir/*.gz");

    my $debug  = $self->{debug};
    my $REPORT = $self->{report};

    # make sure we have logs to process
    if ( !$logs[0] or $logs[0] eq '' ) {
        $err = "WARNING: No web server log files found!\n";
        print $err if $debug;
        print $REPORT $err;
        return;
    }

    if ( $debug > 1 ) {
        print "found logfiles \n\t" . join( "\n\t", @logs ) . "\n";
    };

    return @logs;
};

sub get_config {
    my ($self, $file, $config) = @_;

    if ( $config && ref $config eq 'HASH' ) {
        $self->{conf} = $config;
        return $config;
    }

    return $self->{conf} if (defined $self->{conf} && ref $self->{conf});

    $self->{conf} = $util->parse_config( $file || 'logmonster.conf' );
    return $self->{conf};
};

sub get_util {
    my $self = shift;
    return $util if ref $util;
    use lib 'lib';
    require Apache::Logmonster::Utility;
    $self->{util} = $util = Apache::Logmonster::Utility->new( debug => $self->{debug} );
    return $util;
};

sub report_hits {

    my $self   = shift;
    my $logdir = shift;
    my $debug  = $self->{'debug'};

    $self->{'debug'} = 0;    # hush get_log_dir
    $logdir ||= $self->get_log_dir();

    my $vhost_count_summary = $logdir . "/HitsPerVhost.txt";

    # fail if $vhost_count_summary is not present
    unless ( $vhost_count_summary
        && -e $vhost_count_summary
        && -f $vhost_count_summary )
    {
        print
            "report_hits: ERROR: hit summary file is missing. It should have"
            . " been at: $vhost_count_summary. Report FAILURE.\n";
        return;
    }

    print "report_hits: reporting summary from file $vhost_count_summary\n"
        if $debug;

    my @lines = $util->file_read( $vhost_count_summary,
        debug => $debug,
        fatal => 0,
    );

    my $lines_in_array = @lines;

    if ( $lines_in_array > 0 ) {
        print join( ':', @lines ) . "\n";
        return 1;
    }

    print "report_hits: no entries found!\n" if $debug;
    return;
};

sub report_close {
    my $self = shift;
    my $fh   = shift;

    if ($fh) {
        close($fh);
        return 1;
    }

    carp "report_close: was not passed a valid filehandle!";
    return;
};

sub report_open {
    my $self  = shift;
    my $vhost  = shift;
    my $debug = $self->{'debug'};

    $vhost || croak "report_open: no filename passed!";

    my $logdir = $self->get_log_dir();

    unless ( $logdir && -w $logdir ) {
        print "\tNOTICE!\nreport_open: logdir $logdir is not writable!\n";
        $logdir = "/tmp";
    }

    my $report_file = "$logdir/$vhost.txt";
    my $REPORT;

    if ( !open $REPORT, ">", $report_file ) {
        carp "couldn't open $report_file for write: $!";
        return;
    }

    print "\n ***  this report is saved in $report_file *** \n" if $debug;
    return $REPORT;
};

sub sort_vhost_logs {

############################################
# Usage      : see t/Logmonster.t for usage example
# Purpose    : since the log entries for each host are concatenated, they are
#              no longer in cronological order. Most stats post-processors
#              require that log entries be in chrono order so this sorts them
#              based on their log entry date, which also resolves any timezone
#              differences.
# Returns    : boolean, 1 for success
# Parameters : conf - hashref of setting from logmonster.conf
#              report

    my $self   = shift;
    my $debug  = $self->{'debug'};
    my $conf   = $self->{'conf'};
    my $REPORT = $self->{'report'};

    my ( %beastie, %sortme );

    my $dir = $conf->{'tmpdir'} || croak "tmpdir not set in \$conf";

    if ( $self->{'host_count'} < 2 ) {
        print "sort_vhost_logs: only one log host, skipping sort.\n"
            if $debug;
        return 1;    # sort not needed with only one host
    }

    $self->_progress_begin("sort_vhost_logs: sorting each vhost logfile...")
        if $debug == 1;

    my $lines = 0;
    my ($SORTED, $UNSORTED);

VHOST_FILE:
    foreach
        my $file ( $util->get_dir_files( "$dir/doms", fatal => 0 ) )
    {
        undef %beastie;    # clear the hash
        undef %sortme;

        if ( -s $file > 10000000 ) {
            print "\nsort_vhost_logs: logfile $file is greater than 10MB\n"
                if $debug;
            print $REPORT
                "sort_vhost_logs: logfile $file is greater than 10MB\n";
        }

        unless ( open $UNSORTED, '<', $file ) {
            warn
                "\nsort_vhost_logs: WARN: could not open input file $file: $!";
            next VHOST_FILE;
        }

        # make sure we can write out the results before doing all the work
        unless ( open $SORTED, ">", "$file.sorted" ) {
            print
                "\n sort_vhost_logs: FAILED: could not open output file $file: $!\n"
                if $debug;
            next VHOST_FILE;
        }

        $self->_progress_begin("    sorting $file...") if $debug > 1;

        while (<$UNSORTED>) {
            $self->_progress_continue() if $debug > 1;
            chomp;
###
      # Per Earl Ruby, switched from / / to /\s+/ so that naughty modules like
      # Apache::Register that insert extra spaces in the Log output won't mess
      # up logmonsters parsing.
      #    @log_entry_fields = split(/ /, $_)  =>  @log.. = split(/\s+/, $_)
###
#    sample log entry
#216.220.22.182 - - [16/Jun/2004:09:37:51 -0400] "GET /images/google-g.jpg HTTP/1.1" 200 539 "http://www.tnpi.biz/internet/mail/toaster/" "Mozilla/5.0 (Windows; U; Windows NT 5.0; en-US; rv:1.6) Gecko/20040113" www.thenetworkpeople.biz

 # From an Apache log entry, we first split apart the line based on whitespace

            my @log_entry_fields
                = split( /\s+/, $_ );    # split the log entry into fields

   # Then we use substr to extract the middle 26 characters:
   #   16/Jun/2004:09:37:51 -0400
   #
   # We could also use a regexp to do this but substr is more efficient and we
   # can safely expect the date format of ApacheLog to remain constant.

            my $rawdate
                = substr( "$log_entry_fields[3] $log_entry_fields[4]", 1,
                26 );

# then we convert that date string to a numeric string that we can use for sorting.

            my $date = str2time($rawdate);

   # Finally, we put the entire line into the hash beastie (keyed with $lines,
   # an incrementing number) and create a second hash ($sortme) with the
   # same key but the value is the timestamp.

            $beastie{$lines} = $_;
            $sortme{$lines}  = $date;

            $lines++;
        }
        close($UNSORTED)
            || croak "sort_vhost_logs: Gack, could not close $file: $!\n";
        $self->_progress_end() if $debug > 1;

       # We create an array (because elements in arrays stay in order) of line
       # numbers based on the sortme hash, sorted based on date

        my @sorted = sort {
                   ( $sortme{$a} <=> $sortme{$b} )
                || ( $sortme{$a} cmp $sortme{$b} );
        } ( keys(%sortme) );

        foreach (@sorted) {

# iterate through @sorted, adding the corresponding lines from %beastie to the file
            print $SORTED "$beastie{$_}\n";
        }
        close $SORTED;

        move( "$file.sorted", $file )
            or carp
            "sort_vhost_logs: could not replace $file with $file.sorted: $!\n";

        $self->_progress_continue() if $debug == 1;
    }

    $self->_progress_end() if $debug == 1;

    return 1;
};

sub split_logs_to_vhosts {
    my $self = shift;

    my $debug  = $self->{'debug'};
    my $conf   = $self->{'conf'};
    my $REPORT = $self->{'report'};

    my ( %count, %orphans, $bad );

    my $dir = $conf->{'tmpdir'};      # normally /var/log/(apache|http)/tmp
    my $countlog = $conf->{'CountLog'} || 1;

    my @webserver_logs = $self->get_log_files($dir);

    if ( !-d "$dir/doms" ) {
        if ( !mkdir "$dir/doms", oct('0755') ) {
            $err = "FATAL: couldn't create $dir/doms: $!\n";
            print $REPORT $err;
            die $err;
        }
    }

    print "\t output working dirs is $dir/doms\n" if $debug > 1;

    # use my Regexp::Log::Monster
    my $regexp_parser = Regexp::Log::Monster->new(
        format  => ':logmonster',
        capture => [qw( host vhost status bytes ref ua )],
    );

# Apache fields
# host, ident, auth, date, request, status, bytes, referer, agent, vhost
# returned from parser (available for capture) as:
# host, rfc, authuser, date, ts, request, req, status, bytes, referer, ref, useragent, ua, vhost

    my @captured_fields = $regexp_parser->capture;
    my $re              = $regexp_parser->regexp;

    foreach my $file (@webserver_logs) {

        my $gz = gzopen( $file, 'rb' ) or do {
            warn "Couldn't open $file: $gzerrno";
            next;
        };

        my $lines = 0;
        $self->_progress_begin("\t parsing entries from $file") if $debug;

        while ( $gz->gzreadline($_) > 0 ) {
            chomp $_;
            $lines++;
            $self->_progress_continue() if ( $debug && $lines =~ /00$/ );

            my %data;
            @data{@captured_fields} = /$re/;  # no need for /o, a compiled regexp

            # make sure the log format has the vhost tag appended
            my $vhost = $data{'vhost'};
            if ( !$vhost || $vhost eq '-' ) {
                #print "Invalid log entries! Read the FAQ!\n" if $debug;
                print $_ . "\n" if $debug > 2;
                $vhost = $conf->{default_vhost};
                $bad++;
            };

            $vhost = lc($vhost);

            $self->spam_check(\%data, \%count);

            if ( ! $fhs{$vhost} ) {
                $self->open_vhost_handle( $vhost );
            };
            if ( $fhs{$vhost} ) {
                my $fh = $fhs{$vhost};
                print $fh "$_\n";
                $count{$vhost}++;
                next;
            };
            print "\nthe main domain for $vhost is missing!\n" if $debug > 1;
            $orphans{$vhost} = $vhost;
        };
        $gz->gzclose();

        $self->_progress_end() if $debug;
    };

    $self->report_matches( \%count, \%orphans);
    $self->report_spam_hits( \%count );
    $self->report_bad_hits( $bad );

    return \%fhs;
};

sub spam_check {
    my ($self, $data, $count) = @_;
    my $conf = $self->{conf};

    return if ! $conf->{spam_check};

    my $spam_score = 0;

    # check for spam quotient
    if ( $data->{status} ) {
        if ( $data->{status} == 404 ) {    # check for 404 status
            $spam_score++; # a 404 alone is not a sign of naughtiness
        }

        if ( $data->{status} == 412 ) { # httpd config slapping them
            $spam_score++; 
        }

        if ( $data->{status} == 403 ) { # httpd config slapping them
            $spam_score += 2; 
        }
    }

    # nearly all of my referer spam has a # ending the referer string
    if ( $data->{ref} && $data->{ref} =~ /#$/ ) {
        $spam_score += 2;
    }

    # should check for invalid/suspect useragent strings here
    if ( $data->{ua} ) {
        $spam_score += 
              $data->{ua} =~ /crazy/ixms ? 1
            : $data->{ua} =~ /email/i    ? 3
#           : $data->{ua} =~ /windows/   ? 1
            : 0;
    }

    # if we fail more than one spam test...
    if ( $spam_score > 2 ) {
        $count->{spam}++;
        if ( defined $data->{bytes}
            && $data->{bytes} =~ /[0-9]+/ )
        {
            $count->{bytes} += $data->{bytes};
        }

        $count->{spam_agents}{ $data->{ua} }++;
        $count->{spam_referers}{ $data->{ref} }++;

#				printf "%3s - %30s - %30s \n", $data->{status},
#				$data->{ref}, $data->{ua};
        next;    # skips processing the line
    }

# TODO: also keep track of ham referers, and print in referer spam reports, so
# that I can see which UA are entirely spammers and block them in my Apache
# config.
#   else {
#       $count->{ham_referers}{$data->{ref}}++;
#   }
};

sub open_vhost_handle {
    my $self = shift;
    my $vhost = shift;

    my $fh = new FileHandle;   # create a file handle for each ServerName
    $fhs{$vhost} = $fh;         # store in a hash keyed off the domain name

    my $debug  = $self->{debug};

    my $dir = $self->{conf}{tmpdir};    # normally /var/log/(apache|http)/tmp
    open( $fh, '>', "$dir/doms/$vhost" ) and do {
        if ( $debug > 1 ) {
            print "            ";
            printf "opening file for %35s...ok\n", $vhost;
        }
        return $fh;
    };

    print "            ";
    printf "opening file for %35s...FAILED.\n", $vhost;
    return;
};

sub report_bad_hits {
    my ($self, $bad) = @_;

    return if ! $bad;

    my $conf     = $self->{conf};
    my $debug    = $self->{debug};
    my $REPORT   = $self->{report};

    printf "Default: %15.0f lines to $conf->{default_vhost}.\n", $bad if $debug;
    my $msg = "\nSee the FAQ (logging) to see why records get assigned to the default vhost.\n\n";
    print $msg if $debug;
    print $REPORT $msg;
};

sub report_matches {
    my ($self, $count, $orphans ) = @_;

    my $debug    = $self->{debug};
    my $conf     = $self->{conf};
    my $REPORT   = $self->{report};
    my $countlog = $conf->{CountLog} || 1;

    print "\n\t\t\t Matched Entries\n\n" if $debug;
    print $REPORT "\n\t\t Matched Entries\n\n";

    my $HitLog = '';
    $HitLog = $self->report_open("HitsPerVhost") if $countlog;

    foreach my $key ( keys %fhs ) {
        close $fhs{$key};

        if ( $count->{$key} ) {
            printf "         %15.0f lines to %s\n", $count->{$key}, $key if $debug;
            printf $REPORT "         %15.0f lines to %s\n", $count->{$key}, $key;
            print $HitLog "$key:$count->{$key}\n" if $countlog;
        }
    }
    $self->report_close( $HitLog, $debug ) if $countlog;

    print "\n" if $debug;
    print $REPORT "\n";

    foreach my $key ( keys %$orphans ) {
        if ( $count->{$key} ) {
            printf "Orphans: %15.0f lines to %s\n", $count->{$key}, $key if $debug;
            printf $REPORT "Orphans: %15.0f lines to %s\n", $count->{$key}, $key;
        }
    }
};

sub report_spam_hits {
    my ($self, $count ) = @_;

    return if ! $count->{spam};

    my $conf  = $self->{conf};
    my $debug = $self->{debug};

    if ( $conf->{report_spam_user_agents} ) {

        if ( $debug ) {
            printf "Referer spammers hit you $count->{spam} times";

            my $bytes = $count->{bytes};
            if ( $bytes ) {
                if    ( $bytes > 1000000000 ) {
                    $bytes = sprintf "%.2f GB", $bytes / 1000000000;
                }
                elsif ( $bytes > 1000000 ) {
                    $bytes = sprintf "%.2f MB", $bytes / 1000000;
                }
                else {
                    $bytes = sprintf "%.2f KB", $bytes / 1000;
                }

                print " and wasted $bytes of your bandwidth.";
            }
            print "\n\n";
        };

        my $REPORT = $self->{report};
        printf $REPORT "Referer Spam: %15.0f lines\n", $count->{spam};

        my $spamagents = $count->{spam_agents};
        foreach my $value ( sort { $spamagents->{$b} cmp $spamagents->{$a} } keys %$spamagents ) {
            print "\t $spamagents->{$value} \t $value\n";
        }
    }

    if ( $conf->{report_spam_referrers} ) { # This report can get very long
        my $sr = $count->{spam_referers};
        foreach ( sort { $sr->{$b} <=> $sr->{$a} } keys %$sr ) {
            print "$sr->{$_} \t $_\n";
        }
    }
}


sub _progress {
    my ($self, $mess) = @_;
    print {*STDERR} "$mess.\n";
    return;
};
sub _progress_begin {
    my ($self, $phase) = @_;
    print {*STDERR} "$phase...";
    return;
};
sub _progress_continue {
    print {*STDERR} '.';
    return;
};
sub _progress_end {
    my ($self,$mess) = @_;
    if ( $mess ) {
        print {*STDERR} "$mess\n";
    }
    else {
        print {*STDERR} "done\n";
    };
    return;
};

1;
__END__


=head1 NAME

Logmonster - Http log file splitter, processor, sorter, etc


=head1 AUTHOR

Matt Simerson (msimerson@cpan.org)


=head1 SUBROUTINES

=over

=item new

Creates a new Apache::Logmonster object. All methods in this module are OO. See t/Logmonster.t for a working examples.


=item check_awstats_file

Checks to see if $local/etc/awstats is set up for awstats config files. If not, it creates it. Make sure to drop a custom copy of your sites awstats.model.conf file in there. Finally, it makes sure the $domain it was passed has an awstats file configured for it. If not, it creates one.

=item check_config

Perform sanity tests on the system. It will complain quite loudly if it finds things are not workable.


=item compress_log_file

Compresses a file. Does a test first to make sure the file exists and then compresses it using gzip. Pass it a hostname and a file and it compresses the file on the remote host. Uses SSH to make the connection so you will need to have key based authentication set up.


=item consolidate_logfile

Collects compressed log files from a list of servers into a working directory for processing. 


=item feed_the_machine

feed_the_machine takes the sorted vhost logs and feeds them into the chosen stats processor.


=item fetch_log_files

extracts a list of hosts from logmonster.conf, and then downloads log files form each to the staging area.

=item get_log_dir

Determines where to fetch an intervals worth of logs from. Based upon the -i setting (hour,day,month), this sub figures out where to find the requested log files that need to be processed.

=item report_hits

report_hits reads a days log results file and reports the results to standard out. The logfile contains key/value pairs like so:
	
    matt.simerson:4054
    www.tnpi.net:15381
    www.nictool.com:895

This file is read by logmonster when called in -r (report) mode
and is expected to be called via a monitoring agent (nrpe, snmpd, BB, etc.).


=item report_spam_hits

Appends information about referrer spam to the logmonster -v report. An example of that report can be seen here: http://www.tnpi.net/wiki/Referral_Spam


=item sort_vhost_logs

By now we have collected the Apache logs from each web server and split them up based on vhost. Most stats processors require the logs to be sorted in cronological order. So, we open up each vhosts logs for the day, read them into a hash, sort them based on their log entry date, and then write them back out.


=item split_logs_to_vhosts

After collecting the log files from each server in the cluster, we need to split them up based upon the vhost they were intended for. This sub does that.

=back

=head1 BUGS

Report to author.


=head1 TODO

Support analog.

Support for individual webalizer.conf file for each domain

Delete log files older than X days/month

Do something with error logs (other than just compress)

If files to process are larger than 10MB, find a nicer way to sort them rather than reading them all into a hash. Now I create two hashes, one with data and one with dates. I sort the date hash, and using those sorted hash keys, output the data hash to a sorted file. This is necessary as wusage and http-analyze require logs to be fed in chronological order. Take a look at awstats logresolvemerge as a possibility.


=head1 SEE ALSO

http://www.tnpi.net/internet/www/logmonster


=head1 COPYRIGHT AND LICENSE

Copyright (c) 2003-2013, The Network People, Inc. All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

Neither the name of the The Network People, Inc. nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DIS CLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut
