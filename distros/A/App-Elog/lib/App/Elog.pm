package App::Elog;

use 5.006;
use strict;
use warnings;

our $VERSION = "0.07";

1;

__END__

=head1 NAME

App::Elog - An Apache error log viewer

=head1 SYNOPSIS

    elog [<options>] [<name>]

=head1 OPTIONS

    -a[<n>]    show last n errors on own line, info preceeding
    -d=<file>  default log when one isn't found for cwd
    -f         tail -f the log
    -g         graph errors at hourly intervals
    -gd        graph errors at daily intervals
    -h         displays this help text
    -i         info and statistics
    -l         list available logs
    -ll        list available logs verbosely
    -p         print log path
    -r<n>      rotation number
    -v         vim the log

    <name>     name of the log you are trying to access (regexp),
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
log, use `elog -ll`.

To specify an older rotation of an error log, use the -r option.
For example `elog -r2`, might show the /var/log/httpd/foo.error_log.2.gz
file.

The way it determines which error log to show is by parsing Apache
config files in either /etc/httpd or /etc/apache2. An ErrorLog line
tells where the error log is, a DocRoot line tells which directory
that error log is for.

The -p option will show the path the selected error log file.

The -f option will open the log in `tail -f`.

The -v option will open the log in `vim`.

The -i option will show statistics about the error log file such
as how many errors there were and what time frame.

The -a option will show the message of the error on it's own line,
with extra info such as date and ip address on a line beforehand.
When multiple lines of the error log relate to the same error, they
are grouped.

The -g option will show a graph of the number of errors in an hourly
interval.

The -gd option will show a graph of the number of errors in a daily
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

