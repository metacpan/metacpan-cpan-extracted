package App::lcpan::Cmd::deps_all;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-06-01'; # DATE
our $DIST = 'App-lcpan-CmdBundle-deps'; # DIST
our $VERSION = '0.010'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

use Clone::Util qw(modclone);

require App::lcpan;

our %SPEC;

$SPEC{handle_cmd} = {
    v => 1.1,
    summary => 'List all (indexed) dependencies',
    description => <<'_',

This subcommand lists dependencies. It does not require you to specify a
distribution name, so you can view all dependencies in the `dep` table. Only
"indexed dependencies" are listed though, meaning modules that are currently
indexed by `02packages.details.txt.gz` and are listed in the `module` table.
Distributions will sometimes also specify dependencies to modules that are
(currently) unindexed. To list those, use the `deps-unindexed` subcommand.

_
    args => {
        %{( modclone {
            delete $_->{phase}{schema}[1]{match};
            $_->{phase}{summary} = 'Phase (can contain % for SQL LIKE query)';
        } \%App::lcpan::rdeps_phase_args )},
        %{( modclone {
            delete $_->{rel}{schema}[1]{match};
            $_->{rel}{summary} = 'Relationship (can contain % for SQL LIKE query)';
        } \%App::lcpan::rdeps_rel_args )},
        module => {
            summary => 'Module name that is depended upon (can contain % for SQL LIKE query)',
            schema => 'str*',
            tags => ['category:filtering'],
        },
        dist => {
            summary => 'Distribution name that specifies the dependency (can contain % for SQL LIKE query)',
            schema => 'str*',
            tags => ['category:filtering'],
        },
        module_author => {
            summary => 'The ID of author that releases the module that is depended upon',
            schema => 'str*',
            completion => \&App::lcpan::_complete_cpanid,
            tags => ['category:filtering'],
        },
        dist_author => {
            summary => 'The ID of author that releases the distribution that specifies the distribution',
            schema => 'str*',
            completion => \&App::lcpan::_complete_cpanid,
            tags => ['category:filtering'],
        },
    },
};
sub handle_cmd {
    my %args = @_;

    my $state = App::lcpan::_init(\%args, 'ro');
    my $dbh = $state->{dbh};

    my @wheres = ();
    my @binds  = ();

    if ($args{module}) {
        if ($args{module} =~ /%/) {
            push @wheres, "m.name LIKE ?";
        } else {
            push @wheres, "m.name=?";
        }
        push @binds, $args{module};
    }
    if ($args{module_author}) {
        push @wheres, "m.cpanid=?";
        push @binds, uc $args{module_author};
    }
    if ($args{dist}) {
        if ($args{dist} =~ /%/) {
            push @wheres, "df.dist_name LIKE ?";
        } else {
            push @wheres, "df.dist_name=?";
        }
        push @binds, $args{dist};
    }
    if ($args{dist_author}) {
        push @wheres, "df.cpanid=?";
        push @binds, uc $args{dist_author};
    }
    if ($args{phase} && $args{phase} ne 'ALL') {
        if ($args{phase} =~ /%/) {
            push @wheres, "phase LIKE ?";
        } else {
            push @wheres, "phase=?";
        }
        push @binds, $args{phase};
    }
    if ($args{rel} && $args{rel} ne 'ALL') {
        if ($args{rel} =~ /%/) {
            push @wheres, "rel LIKE ?";
        } else {
            push @wheres, "rel=?";
        }
        push @binds, $args{rel};
    }

    my @columns = qw(module module_author dist dist_author phase rel);
    my $sth = $dbh->prepare("SELECT
  m.name module,
  m.cpanid module_author,
  df.dist_name dist,
  df.cpanid dist_author,
  phase,
  rel
FROM dep
LEFT JOIN module m ON module_id=m.id
LEFT JOIN file df ON dep.file_id=df.id
".
    (@wheres ? "WHERE ".join(" AND ", @wheres) : ""),
                        );
    $sth->execute(@binds);

    my @res;
    while (my $row = $sth->fetchrow_hashref) {
        push @res, $row;
    }

    [200, "OK", \@res, {'table.fields'=>\@columns}];
}

1;
# ABSTRACT: List all (indexed) dependencies

__END__

=pod

=encoding UTF-8

=head1 NAME

App::lcpan::Cmd::deps_all - List all (indexed) dependencies

=head1 VERSION

This document describes version 0.010 of App::lcpan::Cmd::deps_all (from Perl distribution App-lcpan-CmdBundle-deps), released on 2021-06-01.

=head1 DESCRIPTION

This module handles the L<lcpan> subcommand C<deps-all>.

=head1 FUNCTIONS


=head2 handle_cmd

Usage:

 handle_cmd(%args) -> [$status_code, $reason, $payload, \%result_meta]

List all (indexed) dependencies.

This subcommand lists dependencies. It does not require you to specify a
distribution name, so you can view all dependencies in the C<dep> table. Only
"indexed dependencies" are listed though, meaning modules that are currently
indexed by C<02packages.details.txt.gz> and are listed in the C<module> table.
Distributions will sometimes also specify dependencies to modules that are
(currently) unindexed. To list those, use the C<deps-unindexed> subcommand.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<dist> => I<str>

Distribution name that specifies the dependency (can contain % for SQL LIKE query).

=item * B<dist_author> => I<str>

The ID of author that releases the distribution that specifies the distribution.

=item * B<module> => I<str>

Module name that is depended upon (can contain % for SQL LIKE query).

=item * B<module_author> => I<str>

The ID of author that releases the module that is depended upon.

=item * B<phase> => I<str> (default: "ALL")

Phase (can contain % for SQL LIKE query).

=item * B<rel> => I<str> (default: "ALL")

Relationship (can contain % for SQL LIKE query).


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-lcpan-CmdBundle-deps>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-lcpan-CmdBundle-deps>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-lcpan-CmdBundle-deps>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2017, 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
