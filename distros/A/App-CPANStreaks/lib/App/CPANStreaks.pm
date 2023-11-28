package App::CPANStreaks;

use 5.010001;
use strict;
use warnings;
use Log::ger;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-11-25'; # DATE
our $DIST = 'App-CPANStreaks'; # DIST
our $VERSION = '0.002'; # VERSION

our %SPEC;

our %actions = (
    'calculate' => 'Calculate and display a streak table',
    'list-tables' => 'List available streak tables',
);
our @actions = sort keys %actions;

our %tables = (
    'daily-releases'            => 'CPAN authors that release something everyday',
    'daily-distributions'       => 'CPAN authors that release a (for-them) new distribution everyday',
    'daily-new-distributions'   => 'CPAN authors that release a new distribution everyday',
    'weekly-releases'           => 'CPAN authors that release something every week',
    'weekly-distributions'      => 'CPAN authors that release a (for-them) new distribution every week',
    'weekly-new-distributions'  => 'CPAN authors that release a new distribution every week',
    'monthly-releases'          => 'CPAN authors that release something every month',
    'monthly-distributions'     => 'CPAN authors that release a (for-them) new distribution every month',
    'monthly-new-distributions' => 'CPAN authors that release a new distribution every momth',
);
our @tables = sort keys %tables;

$SPEC{cpan_streaks} = {
    v => 1.1,
    summary => 'Calculate and display CPAN streaks',
    args => {
        action => {
            schema => ['str*', {in=>\@actions, 'x.in.summaries' => [map { $actions{$_} } @actions]}],
            cmdline_aliases => {
                list_tables => {is_flag=>1, code=>sub { $_[0]{action} = 'list-tables' }, summary=>'Shortcut for --action=list-tables'},
            },
            default => 'calculate',
            req => 1,
            pos => 0,
        },
        table => {
            schema => ['str*', {in=>\@tables, 'x.in.summaries'=>[map { $tables{$_} } @tables]}],
            pos => 1,
        },
        author => {
            summary => 'Only calculate streaks for certain authors',
            schema => 'cpan::pause_id*',
        },
        exclude_broken => {
            schema => 'bool*',
            default => 1,
        },
    },
};
sub cpan_streaks {
    my %args = @_;
    my $action = $args{action} or return [400, "Please specify action"];
    my $table = $args{table};

    if ($action eq 'list-tables') {
        return [200, "OK", \%tables];
    } elsif ($action eq 'calculate') {
        require Set::Streak;
        my @period_names = (''); # index=period, value=name

        my $td;
        if ($table =~ /daily/) {
            require TableData::Perl::CPAN::Release::Static::GroupedDaily;
            $td = TableData::Perl::CPAN::Release::Static::GroupedDaily->new;
        } elsif ($table =~ /weekly/) {
            require TableData::Perl::CPAN::Release::Static::GroupedWeekly;
            $td = TableData::Perl::CPAN::Release::Static::GroupedWeekly->new;
        } else {
            require TableData::Perl::CPAN::Release::Static::GroupedMonthly;
            $td = TableData::Perl::CPAN::Release::Static::GroupedMonthly->new;
        }

        log_trace "Creating sets ...";
        my @sets;
        my (%seen_dists, %seen_author_dists);
        $td->each_row_arrayref(
            sub {
                my $row = shift;
                my ($period, $rels) = @$row;
                push @period_names, $period;
                push @sets, [];
                for my $rel (@$rels) {
                    my ($author, $dist) = ($rel->[2], $rel->[7]);
                    if (defined $args{author}) { next unless $author eq $args{author} }
                    if ($table =~ /-new-distributions/) {
                        next if $seen_dists{$author}{$dist}++;
                    } elsif ($table =~ /-distributions/) {
                        next if $seen_author_dists{$author}{$dist}++;
                    }
                    push @{ $sets[-1] }, $author unless grep { $_ eq $author } @{ $sets[-1] };
                }
                1;
            });
        log_trace "Calculating streaks ...";
        my $rows = Set::Streak::gen_longest_streaks_table(
            sets => \@sets,
            exclude_broken => $args{exclude_broken},
        );
        for my $row (@$rows) {
            $row->{start_date} = $period_names[ $row->{start} ];
            if ($row->{status} eq 'broken') {
                my $p = $row->{start} + $row->{len} - 1;
                $row->{end_date} = $period_names[ $p ];
            }
            delete $row->{start};
            $row->{author} = delete $row->{item};
        }
        return [200, "OK", $rows, {'table.fields'=>[qw/author len start_date end_date status/]}];

    } else {

        return [400, "Unknown action '$action'"];

    }
}

1;
# ABSTRACT: Calculate various CPAN streaks

__END__

=pod

=encoding UTF-8

=head1 NAME

App::CPANStreaks - Calculate various CPAN streaks

=head1 VERSION

This document describes version 0.002 of App::CPANStreaks (from Perl distribution App-CPANStreaks), released on 2023-11-25.

=head1 DESCRIPTION

=head1 FUNCTIONS


=head2 cpan_streaks

Usage:

 cpan_streaks(%args) -> [$status_code, $reason, $payload, \%result_meta]

Calculate and display CPAN streaks.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<action>* => I<str> (default: "calculate")

(No description)

=item * B<author> => I<cpan::pause_id>

Only calculate streaks for certain authors.

=item * B<exclude_broken> => I<bool> (default: 1)

(No description)

=item * B<table> => I<str>

(No description)


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

Please visit the project's homepage at L<https://metacpan.org/release/App-CPANStreaks>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-CPANStreaks>.

=head1 SEE ALSO

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTING


To contribute, you can send patches by email/via RT, or send pull requests on
GitHub.

Most of the time, you don't need to build the distribution yourself. You can
simply modify the code, then test via:

 % prove -l

If you want to build the distribution (e.g. to try to install it locally on your
system), you can install L<Dist::Zilla>,
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>,
L<Pod::Weaver::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla- and/or Pod::Weaver plugins. Any additional steps required beyond
that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-CPANStreaks>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
