package App::BorgRestore::Settings;
use v5.10;
use strict;
use warnings;

use App::BorgRestore::Helper;

use File::Path qw(mkpath);
use Sys::Hostname;

=encoding utf-8

=head1 NAME

App::BorgRestore::Settings - Settings package

=head1 DESCRIPTION

App::BorgRestore::Settings searches for configuration files in the following locations in
order. The first file found will be used, any later ones are ignored. If no
files are found, defaults are used.

=over

=item * $XDG_CONFIG_HOME/borg-restore.cfg

=item * /etc/borg-restore.cfg

=back

=head2 Configuration Options

You can set the following options in the config file.

Note that the configuration file is parsed as a perl script. Thus you can also
use any features available in perl itself.

=over

=item C<$borg_repo>

This specifies the URL to the borg repo as used in other borg commands. If you
use the $BORG_REPO environment variable set this to an empty string. Default:
"backup:borg-".hostname;

=item C<$cache_path_base>

This defaults to "C<$XDG_CACHE_HOME>/borg-restore.pl". It contains the lookup database.

=item C<@backup_prefixes>

This is an array of prefixes that need to be added when looking up a file in the
backup archives. If you use filesystem snapshots and the snapshot for /home is
located at /mnt/snapshots/home, you have to add the following:

# In the backup archives, /home has the path /mnt/snapshots/home
{regex => "^/home/", replacement => "mnt/snapshots/home/"},

The regex must always include the leading slash and it is suggested to include
a tailing slash as well to prevent clashes with directories that start with the
same string. The first regex that matches for a given file is used. This
setting only affects lookups, it does not affect the creation of the database
with --update-database.

=item C<$sqlite_cache_size>

Default: 102400

The size of the in-memory cache of sqlite in kibibytes. This should be large
enough to fit the database so that adding new backup data does not need to use
the disk too much.

=back

=head2 Example Configuration

 $borg_repo = "/path/to/repo";
 $cache_path_base = "/mnt/somewhere/borg-restore.pl-cache";
 @backup_prefixes = (
 	{regex => "^/home/", replacement => "mnt/snapshots/home/"},
 	# /boot is not snapshotted
 	{regex => "^/boot", replacement => ""},
 	{regex => "^/", replacement => "mnt/snapshots/root/"},
 );
 $sqlite_cache_size = 2097152;

=head1 LICENSE

Copyright (C) 2016-2017  Florian Pritz E<lt>bluewind@xinu.atE<gt>

Licensed under the GNU General Public License version 3 or later.
See LICENSE for the full license text.

=cut

our $borg_repo = "backup:borg-".hostname;
our $cache_path_base = sprintf("%s/borg-restore.pl", $ENV{XDG_CACHE_HOME} // $ENV{HOME}."/.cache");
our @backup_prefixes = (
	{regex => "^/", replacement => ""},
);
our $sqlite_cache_size = 102400;

my @configfiles = (
	sprintf("%s/borg-restore.cfg", $ENV{XDG_CONFIG_HOME} // $ENV{HOME}."/.config"),
	"/etc/borg-restore.cfg",
);

for my $configfile (@configfiles) {
	$configfile = App::BorgRestore::Helper::untaint($configfile, qr/.*/);
	if (-e $configfile) {
		unless (my $return = do $configfile) {
			die "couldn't parse $configfile: $@" if $@;
			die "couldn't do $configfile: $!"    unless defined $return;
			die "couldn't run $configfile"       unless $return;
		}
	}
}
$cache_path_base = App::BorgRestore::Helper::untaint($cache_path_base, qr/.*/);

# ensure the cache directory exists
mkpath(get_cache_dir(), {mode => oct(700)});

sub get_cache_dir {
	return "$cache_path_base/v2";
}

sub get_cache_path {
	my $item = shift;
	return get_cache_dir()."/$item";
}

sub get_db_path {
	return get_cache_path('archives.db');
}


1;

__END__
