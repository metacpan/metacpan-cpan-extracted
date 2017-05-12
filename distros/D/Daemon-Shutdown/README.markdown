# sdd is Shut Down Daemon

It is a Linux service to shut down a server down as soon as it can (to save power).
Restarting the server (wakeonlan etc.) is not covered in this document.

# TYPICAL USAGE

A home NAS which is turned on when needed, manually or by wakeonlan
but should shut down automatically when no users are using it any more.

# WHO

who shows any users currently logged in to the system.

# HDPARM

hdparm is a very useful tool under Linux with which hard drives can be
configured and monitored.

Set hard disk spindown with hdparm:

```
hdparm -S <Int>
```

or with `/etc/hdparm.conf`

```
  /dev/sdb {
    spindown_time = 240
  }
```

See man page for hdparm for details of spindown_time.

See example config.yml file for configuration options, or application help:

```
sdd --help
```


INSTALLATION

To install this module, run the following commands:

```
perl Makefile.PL
make
make test
make install
```

For Debian/Ubuntu:
Copy `examples/etc/sdd.conf` to your `/etc` directory and modify it for your system
Copy `examples/init.d/sdd` to your `/etc/init.d` directory and run

```
update-rc.d sdd defaults
```
        
# SUPPORT AND DOCUMENTATION

https://github.com/robin13/sdd

# LICENSE AND COPYRIGHT

Copyright (C) 2015 Robin Clarke

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

