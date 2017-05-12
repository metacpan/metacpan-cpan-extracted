#!/usr/bin/perl

use strict;
use warnings;

use lib 'lib';

use English qw( -no_match_vars );
use Getopt::Long;
use Pod::Usage;
use Apache::Logmonster '3.07';
use Apache::Logmonster::Utility 5; 

my %command_line_options = (
    'bump:i'     => \my $bump,       # an optional time offset
    'clean!'     => \my $clean,      # ability to override conf file
    'interval:s' => \my $interval,   # hour/day/month
    'hourly'     => \my $hourly,
    'daily'      => \my $daily,
    'monthly'    => \my $monthly,
    'n'          => \my $dry_run,    # just show what we would do
    'verbose+'   => \my $verbose,    # incremental -v options
    'report'     => \my $report_mode,
);
if ( ! GetOptions (%command_line_options) ) {
    pod2usage;
};

# a generic utility object that provides many useful functions
my $lm = Apache::Logmonster->new( $verbose );
my $utility = $lm->get_util();
my $banner  = "\n\t\t Apache Log Monster \n\n";
my $config  = $lm->get_config( 'logmonster.conf' );

$config->{'clean'} = $clean if defined $clean; # allow CLI to override file
$config->{'time_offset'} = $bump if defined $bump;


# if this is not enabled, our report formatting will be jumbled
$OUTPUT_AUTOFLUSH++;

if ( $verbose && ! $report_mode ) {
  print $verbose == 1 ? "verbose mode (1).\n"
      : $verbose == 2 ? "very verbose mode (2).\n"
      : $verbose == 3 ? "screaming at you (3).\n"
      : "unknown verbosity\n";
};

print $banner if $verbose;

# run sanity tests
$lm->check_config();

# CLI backwards compatability with previous versions
$interval ||= $hourly  ? "hour"
            : $daily   ? "day"
            : $monthly ? "month"
            : q{};

my %valid_intervals = ( hour => 1, day => 1, month => 1 );

if ( ! defined $valid_intervals{$interval} ) {
    pod2usage;
};

# stuff a few settings into the $lm object so
# Apache::Logmonster functions can access them.

my @hosts = split(/ /, $config->{'hosts'});
my $host_count = @hosts;
$lm->{'host_count'} = $host_count;
$lm->{'rotation_interval'} = $interval;
$lm->{'dry_run'} = $dry_run || 0;

if ($report_mode) {
    # prints out the last intervals hit count and exit, useful for SNMP
    $lm->report_hits();
    exit 1;
};

# open a file to log our activities to
my $REPORT = $lm->report_open("Logmonster", $verbose);

# store the file handle in the $lm object for functions
$lm->{'report'} = $REPORT;

$lm->_progress($banner) if $verbose;
print $REPORT $banner;

# do the work
$lm->fetch_log_files();
my $domains_ref = $lm->split_logs_to_vhosts();
$lm->sort_vhost_logs      () if !$dry_run;
$lm->feed_the_machine     ($domains_ref);
$lm->report_close         ($REPORT);

exit 1;

__END__


=head1 NAME

Logmonster - log utility for merging, sorting, and processing web logs

=head1 SYNOPSIS

logmonster.pl -i <interval> [-v] [-r] [-n] [-b N]

   Interval is one of:

       hour    (last hour)
       day     (yesterday)
       month   (last month)

   Optional:

      -v     verbose     - lots of status messages 
      -n     dry run     - do everything except feed the logs into the processor
      -r     report      - last periods hit counts
      -b N   back N days - use with -i day to process logs older than one day


=head1 USAGE

To see what it will do without actually doing anything

   /usr/local/sbin/logmonster -i day -v -n

From cron: 

   5 1 * * * /usr/local/sbin/logmonster -i day

From cron with a report of activity: 

   5 1 * * * /usr/local/sbin/logmonster -i day -v


=head1 DESCRIPTION

Logmonster is a tool to collect log files from one or many web servers, split them based on the virtual host they were served for, sort the logs into cronological order, and pipe the sorted logs to a log file analyzer. Webalizer, http-analyze, and AWstats are currently supported.


=head2 MOTIVATION

Log collection: I have several web sites that are mirrored. I only care agreggate statistics. To accomplish that, the logs must be collected from each server. 

Sorting: Since most log processors require the log file entries to be in chronological order, simply concatenating them, or feeding them one after another does not work. Logmonster sorts all the log entries for each vhost into chronological order.

Agnostic: If I want to switch to another log processor, it is simple and painless. Each domain can have a preferred processor.


=head2 FEATURES

=over

=item * Log Retrieval from one or many hosts

=item * Ouputs to webalizer, http-analyze, and AWstats.

=item * Automatic vhost detection 

Logmonster generates config files as required (ie, awstats.example.com.conf).

=item * Efficient

Reads directly from compressed log files to minimize network and disk usage. Skips sorting if you only have logs from a single host.

=item * Flexible update intervals

runs monthly, daily, or hourly

=item * Reporting

logs an activity report and sends an email friendly report.

=item * Reliable

When something goes wrong, it provides useful error messages.

=back


=head1 INSTALLATION

=over

=item Step 1 - Download and install (it's FREE!)

https://www.tnpi.net/cart/index.php?crn=210&rn=385&action=show_detail

Install like typical perl modules:

   perl Makefile.PL
   make test
   make install 

To install the config file, 'make conf' or 'make newconf'. The newconf target will overwrite any existing config file.

=item Step 2 - Edit logmonster.conf

 vi /usr/local/etc/logmonster.conf

=item Step 3 - Edit your web servers config

=over 4 

=item Apache

Adjust the CustomLog and ErrorLog definitions. We make two changes, appending %v (the vhost name) to the CustomLog and adding cronolog to automatically rotate the log files.

  LogFormat "%h %l %u %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-Agent}i\" %v" combined
  CustomLog "| /usr/local/sbin/cronolog /var/log/apache/%Y/%m/%d/access.log" combined
  ErrorLog "| /usr/local/sbin/cronolog /var/log/apache/%Y/%m/%d/error.log"

=item Lighttpd

 accesslog.format = "%h %l %u %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-Agent}i\" %v"
 accesslog.filename = "|/usr/local/sbin/cronolog /var/log/http/%Y/%m/%d/access.log"
 server.errorlog  = "/var/log/http/error.log"

=back

=item Step 4 - Test manually, then add to cron.

  crontab -u root -e
  5 1 * * * /usr/local/sbin/logmonster -i day

=item Step 5 - Read the FAQ

L<http://tnpi.net/wiki/Logmonster_FAQ>

=item Step  6 - Enjoy

Enjoy the daily summary emails.

=back


=head1 DIAGNOSTICS

Run in verbose mode (-v) to see additional status and error messages. Verbosity can be increased by appending another -v, or even (-v -v -v) maximal verbosity. If that is not enough, the source is with you.

Also helpful when troubleshooting is the ability to skip cleanup (so logfiles do not have to be fetched anew) with the --noclean command line option.


=head1 DEPENDENCIES

Not perl builtins

  Compress::Zlib
  Date::Parse (TimeDate)
  Params::Validate

Builtins

  Carp
  Cwd
  FileHandle
  File::Basename
  File::Copy


=head1 BUGS AND LIMITATIONS

Report problems to author. Patches welcome.


=head1 AUTHOR
 
Matt Simerson  (msimerson@cpan.org)
 

=head1 ACKNOWLEDGEMENTS

 Gernot Hueber - sumitted the daily userlogs feature
 Lewis Bergman - funded authoring of several features
 Raymond Dijkxhoorn - suggested not sorting the files for one log host
 Earl Ruby  - a better regexp for apache log date parsing


=head1 TODO

Add support for analog.

Add support for individual webalizer.conf file for each domain (this will likely not happen until someone submits a diff. I don't use webalizer any more).

Delete log files older than X days/months - low priority, it's easy and low maintenance to manually delete a few months log files when I'm sure I don't need them any longer.

Do something with error logs (other than just compress)

If files to process are larger than 10MB, find a nicer way to sort them rather than reading them all into a hash. Now I create two hashes, one with data and one with dates. I sort the date hash, and using those sorted hash keys, output the data hash to a sorted file. This is necessary as wusage and http-analyze require logs to be fed in chronological order. Look at awstats logresolvemerge as a possibility.

Add config file setting for the location of awstats.pl


=head1 SEE ALSO

http://tnpi.net/wiki/Logmonster


=head1 COPYRIGHT AND LICENSE

Copyright (c) 2003-2012, The Network People, Inc. (info@tnpi.net) All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
Neither the name of The author nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR AND CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut
