package App::ListOrgHeadlines;

use 5.010001;
use strict;
use warnings;
use experimental 'smartmatch';
use Log::ger;

use App::OrgUtils;
use Cwd qw(abs_path);
use DateTime;
use Digest::MD5 qw(md5_hex);
use Exporter 'import';
use List::MoreUtils qw(uniq);

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-10-11'; # DATE
our $DIST = 'App-OrgUtils'; # DIST
our $VERSION = '0.483'; # VERSION

our @EXPORT_OK = qw(list_org_headlines);

our %SPEC;

my $today;
my $yest;

sub _process_hl {
    my ($file, $hl, $args, $res) = @_;

    return if $args->{from_level} && $hl->level < $args->{from_level};
    return if $args->{to_level}   && $hl->level > $args->{to_level};
    if (defined $args->{todo}) {
        return if $args->{todo} xor $hl->is_todo;
    }
    if (defined $args->{done}) {
        return if $args->{done} xor $hl->is_done;
    }
    if (defined $args->{state}) {
        return unless $hl->is_todo &&
            $hl->todo_state eq $args->{state};
    }
    if ($args->{has_tags} || $args->{lacks_tags}) {
        my $tags = [$hl->get_tags];
        if ($args->{has_tags}) {
            for (@{ $args->{has_tags} }) {
                return unless $_ ~~ @$tags;
            }
        }
        if ($args->{lacks_tags}) {
            for (@{ $args->{lacks_tags} }) {
                return if $_ ~~ @$tags;
            }
        }
    }
    if (defined $args->{priority}) {
        my $p = $hl->todo_priority;
        return unless defined($p) && $args->{priority} eq $p;
    }
    if (defined $args->{minimum_priority}) {
        my $p = $hl->todo_priority;

        if (defined $p) {
            my $cmp = $hl->document->cmp_priorities(
                $p, $args->{minimum_priority});
            return if defined($cmp) && $cmp > 0;
            return if !defined($cmp) && !$args->{with_unknown_priority};
        } else {
            return unless $args->{with_unknown_priority};
        }
    }
    if (defined $args->{maximum_priority}) {
        my $p = $hl->todo_priority;

        if (defined $p) {
            my $cmp = $hl->document->cmp_priorities(
                $p, $args->{maximum_priority});
            return if defined($cmp) && $cmp < 0;
            return if !defined($cmp) && !$args->{with_unknown_priority};
        } else {
            return unless $args->{with_unknown_priority};
        }
    }

    my $ats = $hl->get_active_timestamp;
    my $days;
    $days = ($ats->datetime < $today ? -1:1) * $ats->datetime->delta_days($today)->in_units('days')
        if $ats;
    if (exists $args->{due_in}) {
        return unless $ats;
        my $met;
        if (defined $args->{due_in}) {
            $met = $days <= $args->{due_in};
        }
        if (!$met && $ats->_warning_period) {
            # try the warning period
            my $dt = $ats->datetime->clone;
            my $wp = $ats->_warning_period;
            $wp =~ s/(\w)$//;
            my $unit = $1;
            $wp = abs($wp);
            if ($unit eq 'd') {
                $dt->subtract(days => $wp);
            } elsif ($unit eq 'w') {
                $dt->subtract(weeks => $wp);
            } elsif ($unit eq 'm') {
                $dt->subtract(months => $wp);
            } elsif ($unit eq 'y') {
                $dt->subtract(years => $wp);
            } else {
                die "Can't understand unit '$unit' in timestamp's ".
                    "warning period: " . $ats->as_string;
            }
            $met++ if DateTime->compare($dt, $today) <= 0;
        }
        if (!$met && !$ats->_warning_period && !defined($args->{due_in})) {
            # try the default 14 days
            $met = $days <= 14;
        }
        return unless $met;
    }

    my $r;
    my $date;
    if ($args->{detail}) {
        $r               = {};
        $r->{file}       = $file;
        $r->{title}      = $hl->title->as_string;
        $r->{due_date}   = $ats ? $ats->datetime : undef;
        $r->{priority}   = $hl->todo_priority;
        $r->{tags}       = [$hl->get_tags];
        $r->{is_todo}    = $hl->is_todo;
        $r->{is_done}    = $hl->is_done;
        $r->{todo_state} = $hl->todo_state;
        $r->{progress}   = $hl->progress;
        $r->{level}      = $hl->level;
        $date = $r->{due_date};
    } else {
        if ($ats) {
            my $pl = abs($days) > 1 ? "s" : "";
            $r = sprintf("%s (%s): %s (%s)",
                         $days == 0 ? "today" :
                             $days < 0 ? abs($days)." day$pl ago" :
                                 "in $days day$pl",
                         $ats->datetime->strftime("%a"),
                         $hl->title->as_string,
                         $ats->datetime->ymd);
            $date = $ats->datetime;
        } else {
            $r = $hl->title->as_string;
        }
    }
    push @$res, [$r, $date, $hl];
}

$SPEC{list_org_headlines} = {
    v       => 1.1,
    summary => 'List all headlines in all Org files',
    args    => {
        %App::OrgUtils::common_args1,
        todo => {
            schema => ['bool'],
            summary => 'Only show headlines that are todos',
            tags => ['filter'],
        },
        done => {
            schema  => ['bool'],
            summary => 'Only show todo items that are done',
            tags => ['filter'],
        },
        due_in => {
            schema => ['int'],
            summary => 'Only show todo items that are (nearing|passed) due',
            description => <<'_',

If value is not set, then will use todo item's warning period (or, if todo item
does not have due date or warning period in its due date, will use the default
14 days).

If value is set to something smaller than the warning period, the todo item will
still be considered nearing due when the warning period is passed. For example,
if today is 2011-06-30 and due_in is set to 7, then todo item with due date
<2011-07-10 > won't pass the filter (it's still 10 days in the future, larger
than 7) but <2011-07-10 Sun +1y -14d> will (warning period 14 days is already
passed by that time).

_
            tags => ['filter'],
        },
        from_level => {
            schema => [int => {default=>1, min=>1}],
            summary => 'Only show headlines having this level as the minimum',
            tags => ['filter'],
        },
        to_level => {
            schema => ['int' => {min=>1}],
            summary => 'Only show headlines having this level as the maximum',
            tags => ['filter'],
        },
        state => {
            schema => ['str'],
            summary => 'Only show todo items that have this state',
            tags => ['filter'],
            completion => $App::OrgUtils::_complete_state,
        },
        detail => {
            schema => [bool => default => 0],
            summary => 'Show details instead of just titles',
            tags => ['format'],
        },
        has_tags => {
            'x.name.is_plural' => 1,
            'x.name.singular' => 'has_tag',
            schema => ['array', of=>'str*'],
            summary => 'Only show headlines that have the specified tags',
            tags => ['filter'],
            element_completion => $App::OrgUtils::_complete_tags,
        },
        lacks_tags => {
            'x.name.is_plural' => 1,
            'x.name.singular' => 'lacks_tag',
            schema => ['array', of=>'str*'],
            summary=> 'Only show headlines that don\'t have the specified tags',
            tags => ['filter'],
            element_completion => $App::OrgUtils::_complete_tags,
        },
        group_by_tags => {
            schema => [bool => default => 0],
            summary => 'Whether to group result by tags',
            description => <<'_',

If set to true, instead of returning a list, this function will return a hash of
lists, keyed by tag: {tag1: [hl1, hl2, ...], tag2: [...]}. Note that a headline
that has several tags will only be listed under its first tag, unless when
`allow_duplicates` is set to true, in which case the headline will be listed
under each of its tag.

_
            tags => ['format'],
        },
        allow_duplicates => {
            schema => ['bool'],
            summary => 'Whether to allow headline to be listed more than once',
            description => <<'_',

This is only relevant when `group_by_tags` is on. Normally when a headline has
several tags, it will only be listed under its first tag. But when this option
is turned on, the headline will be listed under each of its tag (which mean a
single headline will be listed several times).

_
            tags => ['format'],
        },
        priority => {
            schema => ['str'],
            summary => 'Only show todo items that have this priority',
            tags => ['filter'],
            completion => $App::OrgUtils::_complete_priority,
        },
        minimum_priority => {
            schema => ['str'],
            summary => 'Only show todo items that have at least this priority',
            tags => ['filter'],
            description => <<'_',

Note that the default priority list is [A, B, C] (A being the highest) and it
can be customized using the `#+PRIORITIES` setting.

_
            links => ['maximum_priority'],
            completion => $App::OrgUtils::_complete_priority,
        },
        maximum_priority => {
            schema => ['str'],
            summary => 'Only show todo items that have at most this priority',
            tags => ['filter'],
            description => <<'_',

Note that the default priority list is [A, B, C] (A being the highest) and it
can be customized using the `#+PRIORITIES` setting.

_
            links => ['minimum_priority'],
            completion => $App::OrgUtils::_complete_priority,
        },
        with_unknown_priority => {
            schema => ['bool'],
            summary => 'Also show items with no/unknown priority',
            tags => ['filter'],
            description => <<'_',

Relevant only when used with `minimum_priority` and/or `maximum_priority`.

If this option is turned on, todo items that does not have any priority or have
unknown priorities will *still* be included. Otherwise they will not be
included.

_
            links => ['minimum_priority', 'maximum_priority'],
        },
        today => {
            schema => [obj => isa=>'DateTime'],
            summary => 'Assume today\'s date',
            description => <<'_',

You can provide Unix timestamp or DateTime object. If you provide a DateTime
object, remember to set the correct time zone.

_
        },
        sort => {
            schema => [any => {
                of => [
                    ['str*' => {in=>['due_date', '-due_date']}],
                    'code*',
                ],
                default => 'due_date',
            }],
            summary => 'Specify sorting',
            description => <<'_',

If string, must be one of 'due_date', '-due_date' (descending).

If code, sorting code will get [REC, DUE_DATE, HL] as the items to compare,
where REC is the final record that will be returned as final result (can be a
string or a hash, if 'detail' is enabled), DUE_DATE is the DateTime object (if
any), and HL is the Org::Headline object.

_
            tags => ['format'],
        },
    },
};
sub list_org_headlines {
    my %args = @_;

    my $sort  = $args{sort};
    my $tz    = $args{time_zone} // $ENV{TZ} // "UTC";
    my $files = $args{files};

    $today = $args{today} // DateTime->today(time_zone => $tz);

    $yest  = $today->clone->add(days => -1);

    my @res;

    my %docs = App::OrgUtils::_load_org_files(
        $files, {time_zone=>$tz});
    for my $file (keys %docs) {
        my $doc = $docs{$file};
        $doc->walk(
            sub {
                my ($el) = @_;
                return unless $el->isa('Org::Element::Headline');
                _process_hl($file, $el, \%args, \@res)
            });
    }

    if ($sort) {
        if (ref($sort) eq 'CODE') {
            @res = sort $sort @res;
        } elsif ($sort =~ /^-?due_date$/) {
            @res = sort {
                my $dt1 = $a->[1];
                my $dt2 = $b->[1];
                my $comp;
                if ($dt1 && !$dt2) {
                    $comp = -1;
                } elsif (!$dt1 && $dt2) {
                    $comp = 1;
                } elsif (!$dt1 && !$dt2) {
                    $comp = 0;
                } else {
                    $comp = DateTime->compare($dt1, $dt2);
                }
                ($sort =~ /^-/ ? -1 : 1) * $comp;
            } @res;
        }
    }

    my $res;
    if ($args{group_by_tags}) {
        my %seen;

        # cache tags in each @res element's [3] element
        for (@res) { $_->[3] = [$_->[2]->get_tags] }
        my @tags = sort(uniq(map {@{$_->[3]}} @res));
        $res = {};
        for my $tag ('', @tags) {
            $res->{$tag} = [];
            for (@res) {
                if ($tag eq '') {
                    next if @{$_->[3]};
                } else {
                    next unless $tag ~~ @{$_->[3]};
                }
                next if !$args{allow_duplicates} && $seen{$_->[0]}++;
                push @{ $res->{$tag} }, $_->[0];
            }
        }
    } else {
        $res = [map {$_->[0]} @res];
    }

    [200, "OK", $res];
}

1;
# ABSTRACT: List all headlines in all Org files

__END__

=pod

=encoding UTF-8

=head1 NAME

App::ListOrgHeadlines - List all headlines in all Org files

=head1 VERSION

This document describes version 0.483 of App::ListOrgHeadlines (from Perl distribution App-OrgUtils), released on 2022-10-11.

=head1 SYNOPSIS

 # See list-org-headlines script

=head1 DESCRIPTION

=head1 FUNCTIONS


=head2 list_org_headlines

Usage:

 list_org_headlines(%args) -> [$status_code, $reason, $payload, \%result_meta]

List all headlines in all Org files.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<allow_duplicates> => I<bool>

Whether to allow headline to be listed more than once.

This is only relevant when C<group_by_tags> is on. Normally when a headline has
several tags, it will only be listed under its first tag. But when this option
is turned on, the headline will be listed under each of its tag (which mean a
single headline will be listed several times).

=item * B<detail> => I<bool> (default: 0)

Show details instead of just titles.

=item * B<done> => I<bool>

Only show todo items that are done.

=item * B<due_in> => I<int>

Only show todo items that are (nearingE<verbar>passed) due.

If value is not set, then will use todo item's warning period (or, if todo item
does not have due date or warning period in its due date, will use the default
14 days).

If value is set to something smaller than the warning period, the todo item will
still be considered nearing due when the warning period is passed. For example,
if today is 2011-06-30 and due_in is set to 7, then todo item with due date
<2011-07-10 > won't pass the filter (it's still 10 days in the future, larger
than 7) but <2011-07-10 Sun +1y -14d> will (warning period 14 days is already
passed by that time).

=item * B<files>* => I<array[filename]>

=item * B<from_level> => I<int> (default: 1)

Only show headlines having this level as the minimum.

=item * B<group_by_tags> => I<bool> (default: 0)

Whether to group result by tags.

If set to true, instead of returning a list, this function will return a hash of
lists, keyed by tag: {tag1: [hl1, hl2, ...], tag2: [...]}. Note that a headline
that has several tags will only be listed under its first tag, unless when
C<allow_duplicates> is set to true, in which case the headline will be listed
under each of its tag.

=item * B<has_tags> => I<array[str]>

Only show headlines that have the specified tags.

=item * B<lacks_tags> => I<array[str]>

Only show headlines that don't have the specified tags.

=item * B<maximum_priority> => I<str>

Only show todo items that have at most this priority.

Note that the default priority list is [A, B, C] (A being the highest) and it
can be customized using the C<#+PRIORITIES> setting.

=item * B<minimum_priority> => I<str>

Only show todo items that have at least this priority.

Note that the default priority list is [A, B, C] (A being the highest) and it
can be customized using the C<#+PRIORITIES> setting.

=item * B<priority> => I<str>

Only show todo items that have this priority.

=item * B<sort> => I<str|code> (default: "due_date")

Specify sorting.

If string, must be one of 'due_date', '-due_date' (descending).

If code, sorting code will get [REC, DUE_DATE, HL] as the items to compare,
where REC is the final record that will be returned as final result (can be a
string or a hash, if 'detail' is enabled), DUE_DATE is the DateTime object (if
any), and HL is the Org::Headline object.

=item * B<state> => I<str>

Only show todo items that have this state.

=item * B<time_zone> => I<date::tz_name>

Will be passed to parser's options.

If not set, TZ environment variable will be picked as default.

=item * B<to_level> => I<int>

Only show headlines having this level as the maximum.

=item * B<today> => I<obj>

Assume today's date.

You can provide Unix timestamp or DateTime object. If you provide a DateTime
object, remember to set the correct time zone.

=item * B<todo> => I<bool>

Only show headlines that are todos.

=item * B<with_unknown_priority> => I<bool>

Also show items with noE<sol>unknown priority.

Relevant only when used with C<minimum_priority> and/or C<maximum_priority>.

If this option is turned on, todo items that does not have any priority or have
unknown priorities will I<still> be included. Otherwise they will not be
included.


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

Please visit the project's homepage at L<https://metacpan.org/release/App-OrgUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-OrgUtils>.

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

This software is copyright (c) 2022, 2021, 2020, 2019, 2018, 2017, 2016, 2015, 2014, 2013, 2012, 2011 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-OrgUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
