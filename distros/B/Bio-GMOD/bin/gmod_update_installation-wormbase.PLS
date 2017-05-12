#!perl
use Config;
use File::Basename qw(&basename &dirname);
use Cwd;

$origdir = cwd;
chdir dirname($0);
$file = basename($0, '.PL','.PLS');
$file .= $^O eq 'VMS' ? '.com' : '.pl';

open OUT,">$file" or die "Can't create $file: $!";

print "Extracting $file (with variable substitutions)\n";

print OUT <<"!GROK!THIS!";
$Config{startperl}
!GROK!THIS!

# In the following, perl variables are not expanded during extraction.

print OUT <<'!NO!SUBS!';

use strict;
use Getopt::Long;
use Bio::GMOD::Admin::Update;
# use Bio::GMOD::Admin::Monitor;

my ($CONFIG,$HELP,$FORCE,$VERSION,@EXCLUDE,%OPTIONS);

GetOptions('config=s'       => \$CONFIG,
	   'help'           => \$HELP,
	   'force'          => \$FORCE,
	   'version=s'      => \$VERSION,
           'exclude=s'      => \@EXCLUDE);

my $USAGE = <<USAGE;
This script is a derivative of gmod_update_installation.pl, customized
for maintenence of a WormBase installation.

  % gmod_update_installation-wormbase.pl [options]

For a full description of options, see:

  % perldoc gmod_update_installation-wormbase.pl

USAGE

die $USAGE if $HELP;

# Read in values from the configuration file
if ($CONFIG) {
  open F,$CONFIG or die "$CONFIG: $!";
  while (<F>) {
    chomp;
    next if /^\#/;
    next if /^\s/;
    next unless /^(.+)=(.+)/o;
    $OPTIONS{lc($1)} = $2;
  }
  close F;
}

# System paths
my $MYSQL            = $OPTIONS{mysql}    || '/usr/local/mysql/data';
my $ACEDB            = $OPTIONS{acedb}    || '/usr/local/acedb';
my $TMP              = $OPTIONS{tmp}      || '/usr/local/gmod/wormbase/releases';

# Which site to sync to
my $SYNC_TO          = $OPTIONS{sync_to}  || 'live';
my $FTP_SITE         = $OPTIONS{ftp_site} || 'dev.wormbase.org',

# What steps to execute
my $UPDATE_DATABASES = $OPTIONS{update_databases};
my $UPDATE_SOFTWARE  = $OPTIONS{update_software};
my $STEPS            = $OPTIONS{steps};

# Apache monitoring
my $APACHECTL        = $OPTIONS{apachectl} || '/usr/local/apache/bin/apachectl';
my $TEST_URL         = $OPTIONS{test_url};

# ACEDB monitoring
my $ACEPL            = $OPTIONS{acepl}      || '/usr/local/acedb/bin/ace.pl';
my $ACEDB_USER       = $OPTIONS{acedb_user} || 'admin';
my $ACEDB_PASS       = $OPTIONS{acedb_pass} || 'ace123';

# Mysqld monitoring
my $MYSQL_TEST_DB    = $OPTIONS{mysql_test_db};
my $SAFE_MYSQLD      = $OPTIONS{safe_mysqld};
my $MYSQL_INITD      = $OPTIONS{mysql_initd};

# Reporting
my $EMAIL_REPORT     = $OPTIONS{email_report};
my $LOG_REPORT       = $OPTIONS{log_report};
my $EMAIL_ON         = $OPTIONS{email_on};
my $EMAIL_FROM       = $OPTIONS{email_from}    || 'webmaster@wormbase.org';
my $EMAIL_TO         = $OPTIONS{email_to};
my $EMAIL_SUBJECT    = $OPTIONS{email_subject} || 'WormBase Monitoring Report';

my %ORDER = (acedb        => 1,
              elegans_gff  => 2,
              briggsae_gff => 3,
              blast        => 4,
              analyze_logs => 5,
              clear_cache  => 6,
              software     => 7);

my @STEPS = split(/,/,$STEPS);

push (@STEPS,qw/acedb elegans_gff briggsae_gff blast clear_cache/) if $UPDATE_DATABASES;
push (@STEPS,qw/software/) if $UPDATE_SOFTWARE;

# In essence, do $gmod->update() if @STEPS is not provided
# $gmod->update(-version => $desired_version);
push (@STEPS,qw/acedb elegans_gff briggsae_gff blast clear_cache software/)
   if (!$UPDATE_DATABASES && !$UPDATE_SOFTWARE && !$STEPS);

my $gmod = Bio::GMOD::Admin::Update->new(-mod        => 'WormBase',
                                         -tmp_path   => $TMP,
			                 -mysql_path => $MYSQL,
			                 -acedb_path => $ACEDB
                                         -ftp_site   => $FTP_SITE,
                                         );

# Fetch the current live, local, and development versions of the MOD
# Each method will return a hash reference with keys of:
#      status, url, title, version, versiond

my %live  = $gmod->live_version();
my %dev   = $gmod->development_version();
my %local = $gmod->local_version();

if (keys %live < 1) {
  print "WARNING: Could not check the live versions.  You must be online to update your WormBase installation.\n";
  die;
}

print "LIVE SITE ($live{url})\n";
print "----------------------------\n";
print_keys(\%live);

print "DEV SITE ($dev{url})\n";
print "----------------------------\n";
print_keys(\%dev);

print "LOCAL INSTALLATION\n";
print "----------------------------\n";
print_keys(\%local);

# The desired version, fetched automatically or provided with --version
my $desired_version = ($SYNC_TO eq 'development') ? $dev{version} : $live{version};
$desired_version = $VERSION if $VERSION;

# Which rsync module should we sync to?
my $rsync_module = ($SYNC_TO eq 'dev') ? 'wormbase-dev' : 'wormbase-live';

# Force a specific order of steps
foreach (sort { $ORDER{$a} <=> $ORDER{$b} } @STEPS) {
    my $uptodate;
    unless ($FORCE) {
      if ($local{version} eq $desired_version) {
         # monitor_servers();
         print "Your WormBase installation is up-to-date (currently running " . $local{version} . ")\n";
         $uptodate++;
       }
    }

    # Assume we will be downloading
    $gmod->prepare_tmp_dir(-sync_to => $SYNC_TO);
    my %steps2methods = ( acedb        => 'fetch_acedb',
                            elegans_gff  => 'fetch_elegans_gff',
                            briggsae_gff => 'fetch_briggsae_gff',
                            blast        => 'fetch_blast_blat',
                            clear_cache  => 'clear_cache',
                          );

    unless ($uptodate) {
      my $method = $steps2methods{$_};
      if ($_ eq 'analyze_logs') {
         $gmod->analyze_logs(-version => $desired_version,
                             -site    => `hostname`);
      } elsif ($method) {
         $gmod->$method(-version => $desired_version);
      } else {}
    }

    # Always try to update the software regardless of whether or not the database is up-to-date 
    if ($_ eq 'software' || $uptodate) {
      do_rsync();
    }
  exit if $uptodate;
}

print "Your WormBase installation is up-to-date ($desired_version)!\n";

$gmod->cleanup() if $OPTIONS{PURGE};






###################################
# Begin subs
###################################
sub do_rsync {
  my $exclude = join(" ",map {"--exclude='$_'"} @EXCLUDE);
  $gmod->rsync_software(-module       => $rsync_module,
                        -exclude      => $exclude,
                        -install_root => '/usr/local/wormbase/',
                        );
}

sub print_keys {
  my $hash = shift;
  print "Status      : $hash->{status}\n";
  print "Title       : $hash->{title}\n";
  print "Version     : $hash->{version}\n";
  print "Released    : $hash->{released}\n\n";
}


# Not yet implemented
# Make sure all of the appropriate servers are running
#sub monitor_servers {
#  my $agent  = Bio::GMOD::Admin::Monitor->new(-mod        => 'WormBase',
#                                              -apachectl  => $APACHECTL,
#                                              -test_url   => $TEST_URL,
#                                              -test_url   => $ACEPL,
#                                              -acedb_user => $ACEDB_USER,
#                                              -acedb_pass => $ACEDB_PASS,
#                                              -mysql_test_db => $MYSQL_TEST_DB,
#                                              -mysql_initd   => $MYSQL_INITD,
#                                              -mysqld_safe   => $SAFE_MYSQLD,
#                                              );
#
#  my @tested_components = $agent->monitor();
#
#  # Did any of the components fail initially?
#  my %failed =  map { $_->final_status_string => 1} @tested_components;
#
#  $EMAIL_SUBJECT .= (keys %failed > 1) ? ': FAILED' : ': OK';
#
#  $agent->generate_report(-components    => \@tested_components,
#                          -email_report  => $EMAIL_REPORT,
#                          -email_to      => $EMAIL_TO,
#                          -email_from    => $EMAIL_FROM,
#                          -email_subject => $EMAIL_SUBJECT,
#                          -log_report    => $LOG_REPORT,
#                          );
#}

__END__


=pod

=head1 NAME

gmod_update_installation-wormbase.pl

=head1 USAGE

 $ gmod_update_installation-wormbase.pl [options]

This script should be executed with superuser privileges.

=head1 OPTIONS

Available options include (default values in parenthesis):
 Versions and process tasks:
 --version   Update to the provided version (if available on the server!)
 --force     [boolean] Force an update to the provided version (false)

 --exclude       [list...] Files, paths, or patterns to exclude from the rsync update (none)
 --help          Display this message

In order to avoid a ludicrously long incantation, full options for
this script should be stored in a configuration file consisting of
key=value pairs. See the "wormbase_update_defaults.cfg" file that is
included with this distribution for a full description of all options
complete with suitable defaults.

To invoke the script:

 gmod_update_installation-wormbase.pl --config /full/path/to/my.config

=head1 Controlling which update steps are executed

You can broadly control which steps are executed by passing either the
--update_database and/or the --update_software flags.

If you would like more specific control, you can specify specific
steps to run during the update by passing a comma-separated list with
the "--steps" paramater.  Available steps are:

  acedb         Fetch and install the acedb database
  elegans_gff   Fetch and install the C. elegans GFF database
  briggsae_gff  Fetch and install the C. briggsae GFF database
  blast         Fetch and install the blast/blat databases
  software      Rsync the software
  analyze_logs  WormBase logs; requires Analog and ReportMagic
  clear_cache   Clear the wormbase cache at /usr/local/wormbase/cache

The --update_database flag is equivalent to "--steps
acedb,elegans_gff,briggsae_gff,blast,clear_cache" and the --update_software flag
is equivalent "--steps software".

If the --steps option is not specified or the --update_* options are
omitted, the following steps will be executed:

   acedb, elegans_gff, briggsae_gff, blast, software, clear_cache

=head1 Examples

Do an update of both software and databases

  ./gmod_update_installation-wormbase.pl \
           --sync_to live \
           --update_software \
           --update_databases

      Or more simply:

  ./gmod_update_installation-wormbase.pl \
           --sync_to live \

Fetch the most up-to-date version of the code without updating
databases:

  ./gmod_update_installation-wormbase.pl \
           --sync_to live \
           --update_software

Official mirror sites should use a command like:

  ./gmod_update_installation-wormbase.pl \
           --sync_to live \
           --update_databases \
           --update_software \
           --steps analyze_logs

Update databases without updating the software:

  ./gmod_update_installation-wormbase.pl \
           --sync_to live \
           --update_databases

=head1 Excluding files from the syncing process

If you have local files or directories stored in your WormBase
distribution, you can prevent them from being overwritten by the
update process by passing a space separated list of files/directories
with the '--exclude' option.  This options will be passed directly to
rsync.  See the rsync man page for more details.  Note that you do NOT
need to include files that contain local defaults (like localdefs.pm)
as these are exluded by default.

=head1 Running under cron

You may wish to run this script under cron to ensure that your
installation is always up-to-date.

A suggested crontab entry for a simple local installation is:

 0 2,14 * * * gmod_update_intallation.pl --sync_to live --purge 1

A suggested crontab entry for official WormBase mirror sites is:

 0 2,14 * * * gmod_update_intallation.pl --sync_to live \
        --update_databases --update_software \
        --steps analyze_logs

 
Crontab entries like these will check for updates twice a day --
including updating the software. Be sure to include any necessary
options as well, such as the path to your mysql data directory.

=head1 BUGS

None reported.

=head1 SEE ALSO

L<Bio::GMOD>, L<Bio::GMOD::Update>, L<Bio::GMOD::Update::WormBase>,
L<Bio::GMOD::Adaptor>, L<Bio::GMOD::Adaptor::WormBase>

=head1 AUTHOR

Todd W. Harris E<lt>harris@cshl.orgE<gt>.

Copyright (c) 2004-2005 Cold Spring Harbor Laboratory.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut


!NO!SUBS!
close OUT or die "Can't close $file: $!";
chmod 0755, $file or die "Can't reset permissions for $file: $!\n";
exec("$Config{'eunicefix'} $file") if $Config{'eunicefix'} ne ':';
chdir $origdir;
