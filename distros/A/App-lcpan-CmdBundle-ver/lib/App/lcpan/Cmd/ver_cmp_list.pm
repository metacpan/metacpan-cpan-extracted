package App::lcpan::Cmd::ver_cmp_list;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-05-06'; # DATE
our $DIST = 'App-lcpan-CmdBundle-ver'; # DIST
our $VERSION = '0.050'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

require App::lcpan;

our %SPEC;

$SPEC{handle_cmd} = {
    v => 1.1,
    summary => 'Compare a list of module names+versions against database',
    args => {
        %App::lcpan::common_args,
        list => {
            summary => 'List of module names and versions, one per line',
            description => <<'_',

Each line should be in the form of:

    MODNAME VERSION

_
            schema => 'str*',
            req => 1,
            cmdline_src => 'stdin_or_files',
        },
        show => {
            schema => ['str*', in=>[
                'unknown-in-db',
                'newer-than-db',
                'older-than-db',
                'same-as-db',
                'all',
            ]],
            default => 'older-than-db',
            cmdline_aliases => {
                'unknown_in_db' => {
                    is_flag=>1,
                    summary => 'Shortcut for --show unknown-in-db',
                    code=>sub { $_[0]{show} = 'unknown-in-db' },
                },
            },
            cmdline_aliases => {
                'unknown_in_db' => {
                    is_flag=>1,
                    summary => 'Shortcut for --show unknown-in-db',
                    code=>sub { $_[0]{show} = 'unknown-in-db' },
                },
                'newer-than-db' => {
                    is_flag=>1,
                    summary => 'Shortcut for --show newer-than-db',
                    code=>sub { $_[0]{show} = 'newer-than-db' },
                },
                'older-than-db' => {
                    is_flag=>1,
                    summary => 'Shortcut for --show older-than-db',
                    code=>sub { $_[0]{show} = 'older-than-db' },
                },
                'same-as-db' => {
                    is_flag=>1,
                    summary => 'Shortcut for --show same-as-db',
                    code=>sub { $_[0]{show} = 'same-as-db' },
                },
                'all' => {
                    is_flag=>1,
                    summary => 'Shortcut for --show same-as-db',
                    code=>sub { $_[0]{show} = 'all' },
                },
            },
        },
    },
};
sub handle_cmd {
    my %args = @_;

    my $state = App::lcpan::_init(\%args, 'ro');
    my $dbh = $state->{dbh};

    my $show = $args{show};

    my %mods_from_list; # key=name, val=version
    my $i = 0;
    for my $line (split /^/, $args{list}) {
        $i++;
        unless ($line =~ /^\s*(\w+(?:::\w+)*)(?:\s+([0-9][0-9._]*))?/) {
            log_error("Syntax error in list line %d: %s, skipped",
                         $i, $line);
            next;
        }
        $mods_from_list{$1} = $2 // 0;
    }

    my %mods_from_db;
    {
        last unless %mods_from_list;
        my $sth = $dbh->prepare(
            "SELECT name, version FROM module WHERE name IN (".
                join(",", map {$dbh->quote($_)} keys %mods_from_list).")");
        $sth->execute;
        while (my $row = $sth->fetchrow_hashref) {
            $mods_from_db{$row->{name}} = $row->{version};
        }
    }

    my @res;
    my $resmeta = {};
    if ($show eq 'unknown-in-db') {
        for (sort keys %mods_from_list) {
            push @res, $_ unless exists $mods_from_db{$_};
        }
    } else {
        for (sort keys %mods_from_list) {
            next unless exists $mods_from_db{$_};
            my $cmp = version->parse($mods_from_list{$_}) <=>
                version->parse($mods_from_db{$_});
            if ($show eq 'newer-than-db') {
                next unless $cmp == 1;
                $resmeta->{'table.fields'} = [qw/module input_version db_version/] unless @res;
                push @res, {module=>$_, db_version=>$mods_from_db{$_}, input_version=>$mods_from_list{$_}};
            } elsif ($show eq 'older-than-db') {
                next unless $cmp == -1;
                $resmeta->{'table.fields'} = [qw/module input_version db_version/] unless @res;
                push @res, {module=>$_, db_version=>$mods_from_db{$_}, input_version=>$mods_from_list{$_}};
            } elsif ($show eq 'same-as-db') {
                next unless $cmp == 0;
                $resmeta->{'table.fields'} = [qw/module version/] unless @res;
                push @res, {module=>$_, version=>$mods_from_db{$_}};
            } else {
                $resmeta->{'table.fields'} = [qw/module input_version db_version/] unless @res;
                push @res, {module=>$_, db_version=>$mods_from_db{$_}, input_version=>$mods_from_list{$_}};
            }
        }
    }

    [200, "OK", \@res, $resmeta];
}

1;
# ABSTRACT: Compare a list of module names+versions against database

__END__

=pod

=encoding UTF-8

=head1 NAME

App::lcpan::Cmd::ver_cmp_list - Compare a list of module names+versions against database

=head1 VERSION

This document describes version 0.050 of App::lcpan::Cmd::ver_cmp_list (from Perl distribution App-lcpan-CmdBundle-ver), released on 2020-05-06.

=head1 DESCRIPTION

This module handles the L<lcpan> subcommand C<ver-cmp-list>.

=head1 FUNCTIONS


=head2 handle_cmd

Usage:

 handle_cmd(%args) -> [status, msg, payload, meta]

Compare a list of module names+versions against database.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<cpan> => I<dirname>

Location of your local CPAN mirror, e.g. E<sol>pathE<sol>toE<sol>cpan.

Defaults to C<~/cpan>.

=item * B<index_name> => I<filename> (default: "index.db")

Filename of index.

If C<index_name> is a filename without any path, e.g. C<index.db> then index will
be located in the top-level of C<cpan>. If C<index_name> contains a path, e.g.
C<./index.db> or C</home/ujang/lcpan.db> then the index will be located solely
using the C<index_name>.

=item * B<list>* => I<str>

List of module names and versions, one per line.

Each line should be in the form of:

 MODNAME VERSION

=item * B<show> => I<str> (default: "older-than-db")

=item * B<use_bootstrap> => I<bool> (default: 1)

Whether to use bootstrap database from App-lcpan-Bootstrap.

If you are indexing your private CPAN-like repository, you want to turn this
off.


=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-lcpan-CmdBundle-ver>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-lcpan-CmdBundle-ver>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-lcpan-CmdBundle-ver>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020, 2017, 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
