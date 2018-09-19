package App::BorgRestore::Settings;
use v5.14;
use strictures 2;

use App::BorgRestore::Helper;

use autodie;
use Function::Parameters;
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

Also note that it is important that the last statement of the file is positive
because it is used to check that running the config went well. You can simply
use "1;" on the last line as shown in the example config.

=over

=item C<$borg_repo>

This specifies the URL to the borg repo as used in other borg commands. If you
use the $BORG_REPO environment variable set this to an empty string. Default:
"backup:borg-".hostname;

=item C<$cache_path_base>

This defaults to "C<$XDG_CACHE_HOME>/borg-restore.pl". It contains the lookup database.

=item C<@backup_prefixes>

This is an array of prefixes that need to be added or removed when looking up a
file in the backup archives. If you use filesystem snapshots and the snapshot
for /home is located at /mnt/snapshots/home, you have to add the following:

# In the backup archives, /home has the path /mnt/snapshots/home
{regex => "^/home/", replacement => "mnt/snapshots/home/"},

The regex must always include the leading slash and it is suggested to include
a tailing slash as well to prevent clashes with directories that start with the
same string. The first regex that matches for a given file is used. This
setting only affects lookups, it does not affect the creation of the database
with --update-database.

If you create a backup of /home/user only, you will need to use the following:

# In the backup archives, /home/user/foo has the path foo
{regex => "^/home/user", replacement => ""},

=item C<$sqlite_cache_size>

Default: 102400

The size of the in-memory cache of sqlite in kibibytes. Increasing this may
reduce disk IO and improve performance on certain systems when updating the
cache.

=item C<$prepare_data_in_memory>

Default: 0

When new archives are added to the cache, the modification time of each parent
directory for a file's path are updated. If this setting is set to 1, these
updates are done in memory before data is written to the database. If it is set
to 0, any changes are written directly to the database. Many values are updated
multiple time, thus writing directly to the database is slower, but preparing
the data in memory may require a substaintial amount of memory.

New in version 3.2.0. Deprecated in v3.2.0 for future removal possibly in v4.0.0.

=back

=head2 Example Configuration

 $borg_repo = "/path/to/repo";
 $cache_path_base = "/mnt/somewhere/borg-restore.pl-cache";
 @backup_prefixes = (
 	{regex => "^/home/", replacement => "mnt/snapshots/home/"},
 	# /boot is not snapshotted
 	{regex => "^/boot/", replacement => "boot"},
 	{regex => "^/", replacement => "mnt/snapshots/root/"},
 );
 $sqlite_cache_size = 2097152;
 $prepare_data_in_memory = 0;

 1; #ensure positive return value

=head1 LICENSE

Copyright (C) 2016-2018  Florian Pritz E<lt>bluewind@xinu.atE<gt>

Licensed under the GNU General Public License version 3 or later.
See LICENSE for the full license text.

=cut

method new($class: $deps = {}) {
	return $class->new_no_defaults($deps);
}

our $borg_repo = "backup:borg-".hostname;
our $cache_path_base;
our @backup_prefixes = (
	{regex => "^/", replacement => ""},
);
our $sqlite_cache_size = 102400;
our $prepare_data_in_memory = 0;

method new_no_defaults($class: $deps = {}) {
	my $self = {};
	bless $self, $class;
	$self->{deps} = $deps;


	if (defined $ENV{XDG_CACHE_HOME} or defined $ENV{HOME}) {
		$cache_path_base = sprintf("%s/borg-restore.pl", $ENV{XDG_CACHE_HOME} // $ENV{HOME} ."/.cache");
	}

	load_config_files();

	if (not defined $cache_path_base) {
		die "Error: \$cache_path_base is not defined. This is most likely because the\n"
		."environment variables \$HOME and \$XDG_CACHE_HOME are not set. Consider setting\n"
		."the path in the config file or ensure that the variables are set.";
	}

	$cache_path_base = App::BorgRestore::Helper::untaint($cache_path_base, qr/.*/);

	return $self;
}

method get_config() {
	return {
		borg => {
			repo => $borg_repo,
			path_prefixes => [@backup_prefixes],
		},
		cache => {
			base_path => $cache_path_base,
			database_path => "$cache_path_base/v3/archives.db",
			prepare_data_in_memory => $prepare_data_in_memory,
			sqlite_memory_cache_size => $sqlite_cache_size,
		}
	};
}

fun load_config_files() {
	my @configfiles;

	if (defined $ENV{XDG_CONFIG_HOME} or defined $ENV{HOME}) {
		push @configfiles, sprintf("%s/borg-restore.cfg", $ENV{XDG_CONFIG_HOME} // $ENV{HOME}."/.config");
	}
	push @configfiles, "/etc/borg-restore.cfg";

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
}

method get_cache_base_dir_path($path) {
	return "$cache_path_base/$path";
}

1;

__END__
