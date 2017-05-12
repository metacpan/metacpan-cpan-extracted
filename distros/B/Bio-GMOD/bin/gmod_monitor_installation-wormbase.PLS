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
use Bio::GMOD::Admin::Monitor;

my $USAGE = <<USAGE;
This script provides a convenient mechanism to monitor the status of a
given MOD installation. It should be executed with superuser
privileges.

  % gmod_monitor_installation-wormbase.pl [options]

For a full description of options, see:

  % perldoc gmod_monitor_installation-wormbase.pl

USAGE

my ($HELP,$MYSQLD,$MYSQL_DB,
    $HTTPD,$SITE,
    $INETD,
    $EMAIL_REPORT,$LOG_REPORT,
    $EMAIL_TO_OK,$EMAIL_TO_WARN,$EMAIL_FROM,$EMAIL_SUBJECT);
GetOptions( 'help'        => \$HELP,
            'mysqld=s'    => \$MYSQLD,
            'mysql_db=s'  => \$MYSQL_DB,
            'inetd=s'     => \$INETD,

            # Testing / restarting HTTPD
            'httpd=s'     => \$HTTPD,
            'site=s'      => \$SITE,

            'email_report=s'    => \$EMAIL_REPORT,
            'email_to_ok=s'     => \$EMAIL_TO_OK,
            'email_to_warn=s'   => \$EMAIL_TO_WARN,
            'email_from=s'      => \$EMAIL_FROM,
            'email_subject=s'   => \$EMAIL_SUBJECT,
            'log_report=s'      => \$LOG_REPORT,
);

die $USAGE if ($HELP || !$MOD);

# Suitable defaults for a typical WormBase installation

# Non-init systems
$MYSQLD   ||= '/usr/local/mysql/bin/mysqld_safe';
# $MYSQLD ||= '/usr/bin/safe_mysqld';

# Alternatively, provide path to inetd
# $INETD = '/etc/rc.d/init.d/mysqld';

$HTTPD ||= '/usr/local/apache/bin/apachectl';
$SITE  ||= 'http://www.wormbase.org/';

# EMAIL DEFAULTS
$EMAIL_REPORT  ||= 'all';
$EMAIL_SUBJECT ||= 'WormBase Status Report';
$LOG_REPORT    ||= 'all';


# These values need to be passed to new in order to
# become autoloaded default values of the Adaptor
my $agent  = Bio::GMOD::Admin::Monitor->new(-mod      => $MOD,
                                            -mysqld   => $MYSQLD,
                                            -mysql_db => $MYSQL_DB,
                                            -inetd    => $INETD,
                                            -httpd    => $HTTPD,
                                            -site     => $SITE,
                                            );

my @tested_components = $agent->monitor();

# Did any of the components fail initially?
my %failed =  map { $_->final_status_string => 1} @tested_components;

$EMAIL_SUBJECT .= (keys %failed > 1) ? ': FAILED' : ': OK';

$agent->generate_report(-components    => \@tested_components,
                        -email_report  => $EMAIL_REPORT,
                        -email_to_ok   => $EMAIL_TO_OK,
                        -email_to_warn => ($EMAIL_TO_WARN) ? $EMAIL_TO_WARN : $EMAIL_TO_OK,
                        -email_from    => $EMAIL_FROM,
                        -email_subject => $EMAIL_SUBJECT,
                        -log_report    => $LOG_REPORT,
                        );

__END__


=pod

=head1 NAME

$file - Maintain a MOD installation

=head1 USAGE

This script provides a convenient mechanism to maintain a MOD
installation.  It should be excecuted with super user privileges.

  \$ $file [options]

=head1 OPTIONS

The following options are generically available for any MOD (default
values in parenthesis):

 MOD (one of the following is required)
 --mod       One of WormBase, FlyBase, SGD, etc

 Versions:
 --sync_to   [live || dev] Sync to the current live or development version (live)
 --force     [boolean] Force an update to the live or development version as appropriate (false)
 --version   Update to the provided version (the current live version)

 System paths:
 --tmp       Full path to the temporary directory to hold downloads (/usr/local/gmod/tmp)

 Miscellaneous
 --purge     [boolean] Purge the tmp download folder following upgrade (false)
 --help      Display this message

Due to the wide variety of installation paths and MOD structures, each
MOD may offer specialized options.  These can be provided as
"--option_name OPTION" which will be passed directly to the
Bio::GMOD::Update::"MOD" object's update() method.  For example, a
typical command to maintain a WormBase installation looks like:

 % gmod_update_installation.pl --analyze_logs --mysql_path /usr/local/mysql/data

For a full description of all available system paths and update
options for your particular MOD, see L<Bio::GMOD::Adaptor> and
L<GMOD::Adaptor::your_mod>.

=head1 Running under cron

You may wish to run this script under cron to ensure that your
installation is always up-to-date.  For my personal installation of
WormBase, I use the following settings:

0 2 * * * /usr/local/bin/gmod_update_installation.pl --sync_to dev

This will check for and install a new version if present at 2 AM in
the morning.

I keep my installation in sync with the development version.  You will
want to use the more stable live version, which you can specify using
"--sync_to live" or by simply leaving off the "--sync_to" option
altogether.

A suggested crontab entry for a simple local installation is:

  gmod_update_intallation.pl --sync_to live --purge 1

A suggested crontab entry for official WormBase mirror sites is:

  gmod_update_intallation.pl --sync_to live --purge 1 --analyze_logs 1

=head1 SEE ALSO

L<Bio::GMOD>, L<Bio::GMOD::Update>

=head1 AUTHOR

Todd Harris <harris@cshl.edu>.

Copyright (c) 2004-2005 Cold Spring Harbor Laboratory

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  See DISCLAIMER.txt for
disclaimers of warranty.

=cut


!NO!SUBS!
close OUT or die "Can't close $file: $!";
chmod 0755, $file or die "Can't reset permissions for $file: $!\n";
exec("$Config{'eunicefix'} $file") if $Config{'eunicefix'} ne ':';
chdir $origdir;
