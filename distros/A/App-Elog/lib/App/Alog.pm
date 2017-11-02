package App::Alog;

use 5.006;
use strict;
use warnings;

1;

__END__

=head1 NAME

App::Alog - An Apache access log viewer

=head1 SYNOPSIS

    alog [<options>] [<name>]

=head1 OPTIONS

    -a[<n>]    show last n accesses with info spread vertically
    -d=<file>  default log when one isn't found for cwd
    -f         tail -f the log
    -g         graph requests at hourly intervals
    -gd        graph requests at daily intervals
    -h         displays this help text
    -i         info and statistics
    -l         list available logs
    -ll        list available logs verbosely
    -p         print log path
    -r<n>      rotation number
    -v         vim the log

    <name>     name of the log you are trying to access (regexp),
               if name contains a "/", name is treated as a file name,
               default is the access log for the cwd.

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
log, use `alog -ll`.

To specify an older rotation of an access log, use the -r option.
For example `alog -r2`, might show the /var/log/httpd/foo.access_log.2.gz
file.

The way it determines which access log to show is by parsing Apache
config files in either /etc/httpd or /etc/apache2. A CustomLog line
tells where the access log is, a DocRoot line tells which directory
that access log is for, a LogFormat line tells what format the
access log uses.

The -p option will show the path the selected access log file.

The -f option will open the log in `tail -f`.

The -v option will open the log in `vim`.

The -i option will show statistics about the access log file such
as how many requests there were, their time frame, and most active
uris.

The -a option will show the data fields of the access log entry on
their own line, so you don't have to scroll right to see the part
you are interested in.

The -g option will show a graph of the number of requests in an hourly
interval.

The -gd option will show a graph of the number of requests in a daily
interval.

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

