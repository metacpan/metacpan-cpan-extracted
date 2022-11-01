package App::Elog;

use 5.006;
use strict;
use warnings;

our $VERSION = "0.08";

1;

__END__

=head1 NAME

elog - An Apache error log viewer

=head1 SYNOPSIS

    elog [<options>] [<name>]

=head1 OPTIONS

    -f <regex>        filter based on regex
    -g [<interval>]   graph errors
    -h                show this help text
    -i                show info spread vertically
    -l                list available logs
    -L                list available logs with details
    -m <n>            process a maximum of n errors, starting from the end
    -o <n>            process errors starting at an offset from the end
    -p                print log path
    -r <n>            rotation number
    -s                show statistics

    <name>            name of the log you are trying to access (regex),
                      if name contains a "/", name is treated as a file name,
                      default is the error log for the cwd.

=head1 DESCRIPTION

This program will show the Apache error log associated with the
directory you are currently inside of.

Many people set up web servers with each website inside their own
directory in $HOME or /var/www. While working on these sites, for
example /var/www/coolsite.com/, you can run `elog` with no arguments
and it will show the error log for that site inside of less(1).

If you define the $PAGER environment variable, `elog` will use that
program instead of less(1).

If you want to view another site's error log, provide `elog` with an
expression that partially matches the name of that website's log
after the `elog` command. For example, `elog foo`.

To see a list of all the error logs on the server use `elog -l`.
More detailed information, such as what rotations exist for each
log, use `elog -L`.

To specify an older rotation of an error log, use the -r option.
For example `elog -r 2`, might show the /var/log/httpd/foo.error_log.2.gz
file. If that rotation doesn't exist, it will choose the 2nd in the list
shown when you use the -L option.

The way it determines which error log to show is by parsing Apache
config files in either /etc/httpd or /etc/apache2. An ErrorLog line
tells where the error log is, a DocRoot line tells which directory
that error log is for.

The -p option will show the path the selected error log file.

The -f option will filter based on a given regex for the -i, -s, or -g option.

The -s option will show statistics about the error log file such
as how many errors there were, and their time frame.

The -i option will show each error on a line by itself with extra info (time, ip,
etc) on the line before.

The -m option limits the maximum number of errors shown with the -i, -s, or
the -g option, starting from the end of the log (most recent).

The -o option sets an offset to the errors shown with the -i option, so
"elog -i -m 1" shows the last error, "elog -i -m 1 -o 1" shows the second
to last error.

The -g option will show a graph of the number of errors in hourly intervals. If provided an argument, it can be h for hourly, d for daily, or a number of seconds.

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

