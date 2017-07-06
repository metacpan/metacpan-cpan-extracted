# NAME

borg-restore.pl - Restore paths from borg backups

# SYNOPSIS

borg-restore.pl \[options\] &lt;path>

    Options:
     --help, -h                 short help message
     --debug                    show debug messages
     --update-cache, -u         update cache files
     --destination, -d <path>   Restore backup to directory <path>
     --time, -t <timespec>      Automatically find newest backup that is at least
                                <time spec> old
     --adhoc                    Do not use the cache, instead provide an
                                unfiltered list of archive to choose from
     --version                  display the version of the program

    Time spec:
     Select the newest backup that is at least <time spec> old.
     Format: <number><unit>
     Units: s (seconds), min (minutes), h (hours), d (days), m (months = 31 days), y (year)

# EXAMPLE USAGE

    > borg-restore.pl bin/backup.sh
      0: Sat. 2016-04-16 17:47:48 +0200 backup-20160430-232909
      1: Mon. 2016-08-15 16:11:29 +0200 backup-20160830-225145
      2: Mon. 2017-02-20 16:01:04 +0100 backup-20170226-145909
      3: Sat. 2017-03-25 14:45:29 +0100 backup-20170325-232957
    Enter ID to restore (Enter to skip): 3
    INFO Restoring home/flo/bin/backup.sh to /home/flo/bin from archive backup-20170325-232957

# DESCRIPTION

borg-restore.pl helps to restore files from borg backups.

It takes one path, looks for its backups, shows a list of distinct versions and
allows to select one to be restored. Versions are based on the modification
time of the file.

It is also possible to specify a time for automatic selection of the backup
that has to be restored. If a time is specified, the script will automatically
select the newest backup that is at least as old as the time value that is
passed and restore it without further user interaction.

**borg-restore.pl --update-cache** has to be executed regularly, ideally after
creating or removing backups.

[App::BorgRestore](https://metacpan.org/pod/App::BorgRestore) provides the base features used to implement this script.
It can be used to build your own restoration script.

# OPTIONS

- **--help**, **-h**

    Show help message.

- **--debug**

    Enable debug messages.

- **--update-cache**, **-u**

    Update the lookup database. You should run this after creating or removing a backup.

- **--destination=**_path_, **-d **_path_

    Restore the backup to 'path' instead of its original location. The destination
    either has to be a directory or missing in which case it will be created. The
    backup will then be restored into the directory with its original file or
    directory name.

- **--time=**_timespec_, **-t **_timespec_

    Automatically find the newest backup that is at least as old as _timespec_
    specifies. _timespec_ is a string of the form "<_number_><_unit_>" with _unit_ being one of the following:
    s (seconds), min (minutes), h (hours), d (days), m (months = 31 days), y (year). Example: 5.5d

- **--adhoc**

    Disable usage of the database. In this mode, the list of archives is fetched
    directly from borg at run time.  Use this when the cache has not been created
    yet and you want to restore a file without having to manually call borg
    extract. Using this option will show all archives that borg knows about, even
    if they do not contain the file that shall be restored.

- **--version**

    Output the program version.

# CONFIGURATION

For configuration options please see [App::BorgRestore::Settings](https://metacpan.org/pod/App::BorgRestore::Settings).

# LICENSE

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
along with this program.  If not, see &lt;http://www.gnu.org/licenses/>.

See LICENSE for the full license text.
