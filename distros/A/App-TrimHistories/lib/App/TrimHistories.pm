package App::TrimHistories;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2019-11-29'; # DATE
our $DIST = 'App-TrimHistories'; # DIST
our $VERSION = '0.006'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

our %SPEC;

$SPEC{trim_histories} = {
    v => 1.1,
    summary => 'Keep only a certain number of sets of file histories, '.
        'delete the rest',
    description => <<'_',

This script can be used to delete old backup or log files. The files must be
named with timestamps, e.g. `mydb-2017-06-14.sql.gz`. By default, it keeps only
7 daily, 4 weekly, and 6 monthly histories. The rest will be deleted.

_
    args => {
        files => {
            'x.name.is_plural' => 1,
            'x.name.singular' => 'file',
            schema => ['array*', of=>'filename*'],
            summary => 'Each file name must be unique and contain date, '.
                'e.g. `backup-2017-06-14.tar.gz`',
            req => 1,
            pos => 0,
            greedy => 1,
        },
        sets => {
            summary => 'History sets to keep',
            schema => ['array*', of=>'str*', min_len=>2, 'x.perl.coerce_rules' => ['From_str::comma_sep']],
            default => [daily => 7, weekly => 4, monthly => 6],
            description => <<'_',

Expressed as a list of (period, num-to-keep) pairs. Period can be number of
seconds or either `hourly`, `daily`, `weekly`, `monthly`, `yearly`. The default
is:

    ['daily', 7, 'weekly', 4, 'monthly', 6]

which means to keep 7 daily, 4 weekly, and 6 monthly histories. It is equivalent
to:

    [86400, 7, 7*86400, 4, 30*86400, 6]

_
        },
        discard_old_histories => {
            schema => 'bool*',
        },
        discard_young_histories => {
            schema => 'bool*',
        },
    },
    examples => [
        {
            summary => 'By default keeps 7 daily, 4 weekly, 6 monthly '.
                'histories, but older files are kept to fill the sets',
            src => '[[prog]] *',
            src_plang => 'bash',
            test => 0,
            'x.doc.show_result' => 0,
        },
        {
            summary => 'Like previous, but older and younger files are deleted',
            src => '[[prog]] --discard-old --discard-young *',
            src_plang => 'bash',
            test => 0,
            'x.doc.show_result' => 0,
        },
        {
            summary => 'Only keep 5 daily, 2 weekly histories',
            src => q([[prog]] --sets daily,5,weekly,2 *),
            src_plang => 'bash',
            test => 0,
            'x.doc.show_result' => 0,
        },
    ],
    features => {
        dry_run => 1,
    },
};
sub trim_histories {
    require Date::Extract::PERLANCAR;
    require Algorithm::History::Levels;

    my %args = @_;

    my $parser = Date::Extract::PERLANCAR->new(format => 'epoch');

    my $files = $args{files};
    my $histories = [];
    for my $file (@$files) {
        -f $file or return [412, "$file: does not exist or not a file"];
        my $time = $parser->extract($file)
            or return [412, "$file: Can't extract date from name"];
        push @$histories, [$file, $time];
    }

    my $sets = $args{sets} // [86400, 7, 7*86400, 4, 30*86400, 6];
    @$sets > 0 && @$sets % 2 == 0
        or return [400, "Please specify an even number of elements in 'sets'"];
    my $levels = [];
    while (my ($period, $num) = splice @$sets, 0, 2) {
        if ($period eq 'hourly') {
            $period = 3600;
        } elsif ($period eq 'daily') {
            $period = 86400;
        } elsif ($period eq 'weekly') {
            $period = 7*86400;
        } elsif ($period eq 'monthly') {
            $period = 30*86400;
        } elsif ($period eq 'yearly') {
            $period = 365*86400;
        } elsif ($period !~ /\A\d+(\.\d*)?\z/) {
            return [400, "period must be a positive number, not '$period'"];
        }
        push @$levels, [$period, $num];
    }

    my $res = Algorithm::History::Levels::group_histories_into_levels(
        histories => $histories,
        levels => $levels,
        discard_young_histories => $args{discard_young_histories},
        discard_old_histories => $args{discard_old_histories},
    );

    for my $f (@{ $res->{discard} }) {
        my @log_args = ("%sDeleting %s ...", $args{-dry_run} ? "[DRY-RUN] " : "", $f);
        if ($args{-dry_run}) {
            log_warn @log_args;
        } else {
            log_info @log_args;
        }
        unless ($args{-dry_run}) {
            unlink $f or warn "Can't delete $f: $!\n";
        }
    }

    [200, "OK"];
}

1;
# ABSTRACT: Keep only a certain number of sets of file histories, delete the rest

__END__

=pod

=encoding UTF-8

=head1 NAME

App::TrimHistories - Keep only a certain number of sets of file histories, delete the rest

=head1 VERSION

This document describes version 0.006 of App::TrimHistories (from Perl distribution App-TrimHistories), released on 2019-11-29.

=head1 SYNOPSIS

See the included script L<trim-histories>.

=head1 FUNCTIONS


=head2 trim_histories

Usage:

 trim_histories(%args) -> [status, msg, payload, meta]

Keep only a certain number of sets of file histories, delete the rest.

This script can be used to delete old backup or log files. The files must be
named with timestamps, e.g. C<mydb-2017-06-14.sql.gz>. By default, it keeps only
7 daily, 4 weekly, and 6 monthly histories. The rest will be deleted.

This function is not exported.

This function supports dry-run operation.


Arguments ('*' denotes required arguments):

=over 4

=item * B<discard_old_histories> => I<bool>

=item * B<discard_young_histories> => I<bool>

=item * B<files>* => I<array[filename]>

Each file name must be unique and contain date, e.g. `backup-2017-06-14.tar.gz`.

=item * B<sets> => I<array[str]> (default: ["daily",7,"weekly",4,"monthly",6])

History sets to keep.

Expressed as a list of (period, num-to-keep) pairs. Period can be number of
seconds or either C<hourly>, C<daily>, C<weekly>, C<monthly>, C<yearly>. The default
is:

 ['daily', 7, 'weekly', 4, 'monthly', 6]

which means to keep 7 daily, 4 weekly, and 6 monthly histories. It is equivalent
to:

 [86400, 7, 7*86400, 4, 30*86400, 6]

=back

Special arguments:

=over 4

=item * B<-dry_run> => I<bool>

Pass -dry_run=>1 to enable simulation mode.

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

Please visit the project's homepage at L<https://metacpan.org/release/App-TrimHistories>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-TrimHistories>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-TrimHistories>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019, 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
