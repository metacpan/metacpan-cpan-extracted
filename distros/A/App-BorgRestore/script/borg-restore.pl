#!/usr/bin/perl -T
use warnings;
use strict;

=head1 NAME

borg-restore.pl - Restore paths from borg backups

=head1 SYNOPSIS

borg-restore.pl [options] <path>

 Options:
  --help, -h                 short help message
  --debug                    show debug messages
  --update-cache, -u         update cache files
  --destination, -d <path>   Restore backup to directory <path>
  --time, -t <timespec>      Automatically find newest backup that is at least
                             <time spec> old
  --adhoc                    Do not use the cache, instead provide an
                             unfiltered list of archive to choose from

 Time spec:
  Select the newest backup that is at least <time spec> old.
  Format: <number><unit>
  Units: s (seconds), min (minutes), h (hours), d (days), m (months = 31 days), y (year)

=head1 EXAMPLE USAGE

 > borg-restore.pl bin/backup.sh
   0: Sat. 2016-04-16 17:47:48 +0200 backup-20160430-232909
   1: Mon. 2016-08-15 16:11:29 +0200 backup-20160830-225145
   2: Mon. 2017-02-20 16:01:04 +0100 backup-20170226-145909
   3: Sat. 2017-03-25 14:45:29 +0100 backup-20170325-232957
 Enter ID to restore (Enter to skip): 3
 INFO Restoring home/flo/bin/backup.sh to /home/flo/bin from archive backup-20170325-232957

=head1 DESCRIPTION

borg-restore.pl helps to restore files from borg backups.

It takes one path, looks for its backups, shows a list of distinct versions and
allows to select one to be restored. Versions are based on the modification
time of the file.

It is also possible to specify a time for automatic selection of the backup
that has to be restored. If a time is specified, the script will automatically
select the newest backup that is at least as old as the time value that is
passed and restore it without further user interaction.

B<borg-restore.pl --update-cache> has to be executed regularly, ideally after
creating or removing backups.

L<App::BorgRestore> provides the base features used to implement this script.
It can be used to build your own restoration script.

=cut

=head1 OPTIONS

=over 4

=item B<--help>, B<-h>

Show help message.

=item B<--debug>

Enable debug messages.

=item B<--update-cache>, B<-u>

Update the lookup database. You should run this after creating or removing a backup.

=item B<--destination=>I<path>, B<-d >I<path>

Restore the backup to 'path' instead of its original location. The destination
either has to be a directory or missing in which case it will be created. The
backup will then be restored into the directory with its original file or
directory name.

=item B<--time=>I<timespec>, B<-t >I<timespec>

Automatically find the newest backup that is at least as old as I<timespec>
specifies. I<timespec> is a string of the form "<I<number>><I<unit>>" with I<unit> being one of the following:
s (seconds), min (minutes), h (hours), d (days), m (months = 31 days), y (year). Example: 5.5d

=item B<--adhoc>

Disable usage of the database. In this mode, the list of archives is fetched
directly from borg at run time.  Use this when the cache has not been created
yet and you want to restore a file without having to manually call borg
extract. Using this option will show all archives that borg knows about, even
if they do not contain the file that shall be restored.

=back

=head1 CONFIGURATION

For configuration options please see L<App::BorgRestore::Settings>.

=head1 LICENSE

Copyright (C) 2016-2017  Florian Pritz <bluewind@xinu.at>

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

See LICENSE for the full license text.

=cut

use v5.10;

use App::BorgRestore;
use App::BorgRestore::Borg;
use App::BorgRestore::DB;
use App::BorgRestore::Helper;
use App::BorgRestore::Settings;

use autodie;
use Cwd qw(abs_path);
use File::Basename;
use Function::Parameters;
use Getopt::Long;
use Log::Any qw($log);
use Log::Any::Adapter;
use Log::Log4perl;
use Log::Log4perl::Appender::Screen;
use Log::Log4perl::Appender::ScreenColoredLevels;
use Log::Log4perl::Layout::PatternLayout;
use Log::Log4perl::Level;
use Pod::Usage;

my $app;

fun user_select_archive ($archives) {
	my $selected_archive;

	if (!@$archives) {
		return;
	}

	my $counter = 0;
	for my $archive (@$archives) {
		printf "\e[0;33m%3d: \e[1;33m%s\e[0m %s\n", $counter++, App::BorgRestore::Helper::format_timestamp($archive->{modification_time}), $archive->{archive};
	}

	printf "\e[0;34m%s: \e[0m", "Enter ID to restore (Enter to skip)";
	my $selection = <STDIN>;
	return if !defined($selection);
	chomp $selection;

	return unless ($selection =~ /^\d+$/ && defined(${$archives}[$selection]));
	return ${$archives}[$selection];
}

sub logger_setup {
	my $appender = "Screen";
	$appender = "ScreenColoredLevels" if -t STDERR; ## no critic (InputOutput::ProhibitInteractiveTest)

	my $conf = "
	log4perl.rootLogger = INFO, screenlog

	log4perl.appender.screenlog          = Log::Log4perl::Appender::$appender
	log4perl.appender.screenlog.stderr   = 1
	log4perl.appender.screenlog.layout   = Log::Log4perl::Layout::PatternLayout
	log4perl.appender.screenlog.layout.ConversionPattern = %p %m%n

	log4perl.PatternLayout.cspec.U = sub {my \@c = caller(\$_[4]); \$c[0] =~ s/::/./g; return sprintf('%s:%s', \$c[0], \$c[2]);}
	";
	Log::Log4perl::init( \$conf );
	Log::Any::Adapter->set('Log4perl');

	$SIG{__WARN__} = sub {
		local $Log::Log4perl::caller_depth =
			$Log::Log4perl::caller_depth + 1;
		 Log::Log4perl->get_logger()->warn(@_);
	};

	$SIG{__DIE__} = sub {
		# ignore eval blocks
		return if($^S);
		local $Log::Log4perl::caller_depth =
			$Log::Log4perl::caller_depth + 1;
		 Log::Log4perl->get_logger()->fatal(@_);
		 exit(2);
	};
}

sub main {
	logger_setup();

	my %opts;
	# untaint PATH because we do not expect this to be run across user boundaries
	$ENV{PATH} = App::BorgRestore::Helper::untaint($ENV{PATH}, qr(.*));

	Getopt::Long::Configure ("bundling");
	GetOptions(\%opts, "help|h", "debug", "update-cache|u", "destination|d=s", "time|t=s", "adhoc") or pod2usage(2);
	pod2usage(0) if $opts{help};

	pod2usage(-verbose => 0) if (@ARGV== 0 and !$opts{"update-cache"});

	if ($opts{debug}) {
		my $logger = Log::Log4perl->get_logger('');
		$logger->level($DEBUG);
		Log::Log4perl->appenders()->{"screenlog"}->layout(
			Log::Log4perl::Layout::PatternLayout->new("%d %8r [%-30U] %p %m%n"));
	}

	$app = App::BorgRestore->new();

	if ($opts{"update-cache"}) {
		$app->update_cache();
		return 0;
	}

	my @paths = @ARGV;

	my $path;
	my $timespec;
	my $destination;
	my $archives;

	$path = $ARGV[0];

	if (defined($opts{destination})) {
		$destination = $opts{destination};
	}

	if (defined($opts{time})) {
		$timespec = $opts{time};
	}

	if (@ARGV > 1) {
		die "Too many arguments";
	}

	my $abs_path = $app->resolve_relative_path($path);

	$destination = dirname($abs_path) unless defined($destination);
	my $backup_path = $app->map_path_to_backup_path($abs_path);

	$log->debug("Asked to restore $backup_path to $destination");

	if ($opts{adhoc}) {
		$archives = $app->get_all_archives();
	} else {
		$archives = $app->find_archives($backup_path);
	}

	my $selected_archive;
	if (defined($timespec)) {
		$selected_archive = $app->select_archive_timespec($archives, $timespec);
	} else {
		$selected_archive = user_select_archive($archives);
	}

	if (!defined($selected_archive)) {
		die "No archive selected or selection invalid";
	}

	$app->restore($backup_path, $selected_archive, $destination);

	return 0;
}

exit main();

