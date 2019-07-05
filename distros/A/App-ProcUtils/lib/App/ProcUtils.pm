package App::ProcUtils;

our $DATE = '2019-07-04'; # DATE
our $VERSION = '0.032'; # VERSION

use 5.010001;
use strict;
use warnings;

our %SPEC;

$SPEC{list_parents} = {
    v => 1.1,
    summary => 'List all the parents of the current process',
};
sub list_parents {
    require Proc::Find::Parents;
    [200, "OK", Proc::Find::Parents::get_parent_processes(
        $$, {method=>'proctable'})];
}

$SPEC{table} = {
    v => 1.1,
    summary => 'Run Proc::ProcessTable and display the result',
};
sub table {
    require Proc::ProcessTable;

    my $t = Proc::ProcessTable->new;

    my @res;
    my $resmeta = {
        'table.fields' => [
            # follows the order of 'ps aux'
            "uid",
            "pid",
            "pctcpu",
            "pctmem",
            "size",
            "rss",
            "ttydev",
            "ttynum",
            "state",
            "start",
            "time",
            "cmndline",

            "cmajflt",
            "cminflt",
            "cstime",
            "ctime",
            "cutime",
            "cwd",
            "egid",
            "euid",
            "exec",
            "fgid",
            "flags",
            "fname",
            "fuid",
            "gid",
            "majflt",
            "minflt",
            "pgrp",
            "ppid",
            "priority",
            "sess",
            "sgid",
            "stime",
            "suid",
            "utime",
            "wchan",
        ],
    };

    for my $p (@{ $t->table }) {
        push @res, {%$p};
    }

    [200, "OK", \@res, $resmeta];
}

1;
# ABSTRACT: Command line utilities related to processes

__END__

=pod

=encoding UTF-8

=head1 NAME

App::ProcUtils - Command line utilities related to processes

=head1 VERSION

This document describes version 0.032 of App::ProcUtils (from Perl distribution App-ProcUtils), released on 2019-07-04.

=head1 SYNOPSIS

This distribution provides the following command-line utilities:

=over

=item * L<proc-list-parents>

=item * L<proc-table>

=back

=head1 FUNCTIONS


=head2 list_parents

Usage:

 list_parents() -> [status, msg, payload, meta]

List all the parents of the current process.

This function is not exported.

No arguments.

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 table

Usage:

 table() -> [status, msg, payload, meta]

Run Proc::ProcessTable and display the result.

This function is not exported.

No arguments.

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-ProcUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-ProcUtils>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-ProcUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019, 2018, 2016, 2015 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
