# Check-supervisorctl

Calls 'supervisorctl status' and by default alerts for anything not
starting or running.

Optionally then checks under the conf.d dir for supervisor and to
check to see what is there matches what is running, wanting each item
running to have it's own config and ensure everything present is
running, ensure that the config and current status is in sync. This
operates under the assumption that each item has it's own config and
the name of the two matches post removing /\.conf$/ from the name of
the file.

# Usage

## SYNOPSIS

check_supervisorctl [B<-f> <config_dir>] [B<-c>] [B<-d> <ignore_config>]  [B<-i> <ignore>] [B<-s> <status mapping>]

check_supervisorctl -h/--help

check_supervisorctl -v/--version

## FLAGS

### -c

Check configs as well.

### -f config_dir

The directory to look for configs under if -c is set.

Only items matching /\.conf$/ are checked.

Default: /usr/local/etc/supervisor/conf.d

Linux: /etc/supervisor/conf.d

### -d ignore_config

A config entry to ignore.

May be used more than once.

### -i ignore

A item from status to ignore.

May be used more than once.

### -s status=mapping

Maps a status to to a exit value.

May be used more than once to define more than one mapping.

For supervisorctl it is as below.

    stopped  = 2
    starting = 0
    running  = 0
    backoff  = 2
    stopping = 2
    exited   = 2
    fatal    = 2
    unknown  = 2

For config checking it is as below.

    config_missing         = 2
    config_dir_missing     = 3
    config_dir_nonreadable = 3

# INSTALLATION

## FreeBSD

```
pkg install p5-File-Slurp p5-App-cpanminus
cpanm Check::supervisorctl
```

##

```
apt-get install libfile-slurp-perl cpanminus
cpanm Check::supervisorctl
```

## Source

To install this module, run the following commands:

```
perl Makefile.PL
make
make test
make install
```

# SUPPORT AND DOCUMENTATION

After installing, you can find documentation for this module with the
perldoc command.

    perldoc Check::supervisorctl

You can also look for information at:

    RT, CPAN's request tracker (report bugs here)
        https://rt.cpan.org/NoAuth/Bugs.html?Dist=Check-supervisorctl

    Github issue tracker (report bugs here)
        https://github.com/VVelox/Check-supervisorctl/issues

    CPAN Ratings
        https://cpanratings.perl.org/d/Check-supervisorctl

    Search CPAN
        https://metacpan.org/release/Check-supervisorctl


LICENSE AND COPYRIGHT

This software is Copyright (c) 2025 by Zane C. Bowers-Hadley.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

