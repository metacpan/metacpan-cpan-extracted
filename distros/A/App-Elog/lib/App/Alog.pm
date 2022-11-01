package App::Alog;

use 5.006;
use strict;
use warnings;

1;

__END__

=head1 NAME

alog - An Apache access log viewer

=head1 SYNOPSIS

    alog [<options>] [<name>]

=head1 OPTIONS

    -f <regex>        filter based on regex
    -g [<interval>]   graph errors
    -h                show this help text
    -i                show info spread vertically
    -I                show info verbosely
    -l                list available logs
    -L                list available logs with details
    -m <n>            process a maximum of n accesses, starting from the end
    -o <n>            process accesses starting at an offset from the end
    -p                print log path
    -r <n>            rotation number
    -s                show statistics

    <name>            name of the log you are trying to access (regex),
                      if name contains a "/", name is treated as a file name,
                      default is the access log for the cwd.

By default, this command will open the log in \$PAGER or less(1)

=head1 DESCRIPTION

This program will show the Apache access log associated with the
directory you are currently inside of.

Many people set up web servers with each website inside their own
directory in $HOME or /var/www. While working on these sites, for
example /var/www/coolsite.com/, you can run `alog` with no arguments
and it will show the access log for that site inside of less(1).

If you define the $PAGER environment variable, `alog` will use that
program instead of less(1).

If you want to view another site's access log, provide `alog` with an
expression that partially matches the name of that website's log
after the `alog` command. For example, `alog foo`.

To see a list of all the access logs on the server use `alog -l`.
More detailed information, such as what rotations exist for each
log, use `alog -L`.

To specify an older rotation of an access log, use the -r option.
For example `alog -r 2`, might show the /var/log/httpd/foo.access_log.2.gz
file. If that rotation doesn't exist, it will choose the 2nd in the list
shown when you use the -L option.

The way it determines which access log to show is by parsing Apache
config files in either /etc/httpd or /etc/apache2. A CustomLog line
tells where the access log is, a DocRoot line tells which directory
that access log is for, a LogFormat line tells what format the
access log uses.

The -p option will show the path the selected access log file.

The -f option will filter based on a given regex for the -i, -s, or -g option.

The -s option will show statistics about the access log file such
as how many requests there were, their time frame, and most active
URIs.

The -i option will show the data fields of the access log entry on
their own line, so you don't have to scroll right to see the part
you are interested in.

The -I option will show all the fields we have for the entry on it's
own line.

The -m option limits the maximum number of accesses shown with the -i, -s, or the
-g option, starting from the end of the log (most recent).

The -o option sets an offset to the accesses shown with the -i option, so
"elog -i -m 1" shows the last access, "elog -i -m 1 -o 1" shows the second
to last access.

The -g option will show a graph of the number of accesses in hourly
intervals. If provided an argument, it can be h for hourly, d for daily,
or a number of seconds.

=head1 METACPAN

L<https://metacpan.org/pod/App::Elog>

=head1 AUTHOR

Jacob Gelbman E<lt>gelbman@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2017 by Jacob Gelbman

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.18.2 or,
at your option, any later version of Perl 5 you may have available.

=cut

