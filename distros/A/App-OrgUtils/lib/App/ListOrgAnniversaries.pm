package App::ListOrgAnniversaries;

our $DATE = '2020-02-06'; # DATE
our $VERSION = '0.472'; # VERSION

use 5.010;
use strict;
use warnings;
use experimental 'smartmatch';
use Log::ger;

use App::OrgUtils;
use Cwd qw(abs_path);
use DateTime;
use Digest::MD5 qw(md5_hex);
use Lingua::EN::Numbers::Ordinate;

require Exporter;
our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(list_org_anniversaries);

our %SPEC;

my $today;
my $yest;

sub _process_hl {
    my ($file, $hl, $args, $res, $tz) = @_;

    return unless $hl->is_leaf;

    log_trace("Processing %s ...", $hl->title->as_string);

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

    my @annivs;
    $hl->walk(
        sub {
            my ($el) = @_;

            if ($el->isa('Org::Element::Timestamp')) {
                my $field = $el->field_name;
                return unless defined($field) &&
                    $field =~ $args->{field_pattern};
                push @annivs, [$field, $el->datetime];
                return;
            }
            if ($el->isa('Org::Element::Drawer') && $el->name eq 'PROPERTIES') {
                my $props = $el->properties;
                for my $k (keys %$props) {
                    next unless $k =~ $args->{field_pattern};
                    my $v = $props->{$k};
                    unless ($v =~ /^\s*(\d{4})-(\d{2})-(\d{2})\s*$/) {
                        log_warn("Invalid date format $v, ".
                                       "must be YYYY-MM-DD");
                        next;
                    }
                    push @annivs,
                        [$k, DateTime->new(year=>$1, month=>$2, day=>$3,
                                       time_zone=>$tz)];
                    return;
                }
            }
        }
    );

    if (!@annivs) {
        log_debug("Node doesn't contain anniversary fields, skipped");
        return;
    }
    log_trace("annivs = ", \@annivs);
    for my $anniv (@annivs) {
        my ($field, $date) = @$anniv;
        log_debug("Anniversary found: field=%s, date=%s",
                     $field, $date->ymd);
        my $y = $today->year - $date->year;
        my $date_ly = $date->clone; $date_ly->add(years => $y-1);
        my $date_ty = $date->clone; $date_ty->add(years => $y  );
        my $date_ny = $date->clone; $date_ny->add(years => $y+1);
      DATE:
        for my $d ($date_ly, $date_ty, $date_ny) {
            my $days = ($d < $today ? -1:1) * $d->delta_days($today)->in_units('days');
            next if defined($args->{due_in}) &&
                $days > $args->{due_in};
            next if defined($args->{max_overdue}) &&
                -$days > $args->{max_overdue};
            next if !defined($args->{due_in}) &&
                !defined($args->{max_overdue}) &&
                    DateTime->compare($d, $today) < 0;
            my $pl = abs($days) > 1 ? "s" : "";
            my $hide_age = $date->year == 1900;
            my $msg = sprintf(
                "%s (%s): %s of %s (%s)",
                $days == 0 ? "today" :
                    $days < 0 ? abs($days)." day$pl ago" :
                        "in $days day$pl",
                $d->strftime("%a"),
                $hide_age ? $field :
                    ordinate($d->year - $date->year)." $field",
                $hl->title->as_string,
                $hide_age ? $d->ymd : $date->ymd . " - " . $d->ymd);
            log_debug("Added this anniversary to result: %s", $msg);
            push @$res, [$msg, $d];
            last DATE;
        }
    } # for @annivs
}

$SPEC{list_org_anniversaries} = {
    v => 1.1,
    summary => 'List all anniversaries in Org files',
    description => <<'_',
This function expects contacts in the following format:

    * First last                              :office:friend:
      :PROPERTIES:
      :BIRTHDAY:     1900-06-07
      :EMAIL:        foo@example.com
      :OTHERFIELD:   ...
      :END:

or:

    * Some name                               :office:
      - birthday   :: [1900-06-07 ]
      - email      :: foo@example.com
      - otherfield :: ...

Using PROPERTIES, dates currently must be specified in "YYYY-MM-DD" format.
Other format will be supported in the future. Using description list, dates can
be specified using normal Org timestamps (repeaters and warning periods will be
ignored).

By convention, if year is '1900' it is assumed to mean year is not specified.

By default, all contacts' anniversaries will be listed. You can filter contacts
using tags ('has_tags' and 'lacks_tags' options), or by 'due_in' and
'max_overdue' options (due_in=14 and max_overdue=2 is what I commonly use in my
startup script).

_
    args    => {
        %App::OrgUtils::common_args1,
        field_pattern => {
            summary => 'Field regex that specifies anniversaries',
            schema  => [str => {
                default => '(?:birthday|anniversary)',
            }],
        },
        has_tags => {
            summary => 'Filter headlines that have the specified tags',
            schema  => [array => {of => 'str*'}],
            element_completion => $App::OrgUtils::_complete_tags,
        },
        lacks_tags => {
            summary => 'Filter headlines that don\'t have the specified tags',
            schema  => [array => {of => 'str*'}],
            element_completion => $App::OrgUtils::_complete_tags,
        },
        due_in => {
            summary => 'Only show anniversaries that are due '.
                'in this number of days',
            schema  => ['int'],
        },
        max_overdue => {
            summary => 'Don\'t show dates that are overdue '.
                'more than this number of days',
            schema  => ['int'],
        },
        today => {
            summary => 'Assume today\'s date',
            schema  => [obj => isa=>'DateTime'],
            description => <<'_',

You can provide Unix timestamp or DateTime object. If you provide a DateTime
object, remember to set the correct time zone.

_
        },
        sort => {
            summary => 'Specify sorting',
            schema  => [any => {
                of => [
                    ['str*' => {in=>['due_date', '-due_date']}],
                    'code*',
                ],
                default => 'due_date',
            }],
            description => <<'_',

If string, must be one of 'date', '-date' (descending).

If code, sorting code will get [REC, DUE_DATE] as the items to compare, where
REC is the final record that will be returned as final result (can be a string
or a hash, if 'detail' is enabled), and DUE_DATE is the DateTime object.

_
        },
    },
};
sub list_org_anniversaries {
    my %args = @_;

    my $sort  = $args{sort};
    my $tz    = $args{time_zone} // $ENV{TZ} // "UTC";
    my $files = $args{files};
    my $f     = $args{field_pattern} // '';
    return [400, "Invalid field_pattern: $@"] unless eval { $f = qr/$f/i };
    $args{field_pattern} = $f;

    $today = $args{today} // DateTime->today(time_zone => $tz);

    $yest  = $today->clone->add(days => -1);

    my $orgp = Org::Parser->new;
    my @res;

    my %docs = App::OrgUtils::_load_org_files(
        $files, {time_zone=>$tz});
    for my $file (keys %docs) {
        my $doc = $docs{$file};
        $doc->walk(
            sub {
                my ($el) = @_;
                return unless $el->isa('Org::Element::Headline');
                _process_hl($file, $el, \%args, \@res, $tz);
            });
    }

    if ($sort) {
        if (ref($sort) eq 'CODE') {
            @res = sort $sort @res;
        } elsif ($sort =~ /^-?due_date$/) {
            @res = sort {
                my $dt1 = $a->[1];
                my $dt2 = $b->[1];
                my $comp = DateTime->compare($dt1, $dt2);
                ($sort =~ /^-/ ? -1 : 1) * $comp;
            } @res;
        }
    }

    [200, "OK", [map {$_->[0]} @res],
     {result_format_opts=>{list_max_columns=>1}}];
}

1;
# ABSTRACT: List all anniversaries in Org files

__END__

=pod

=encoding UTF-8

=head1 NAME

App::ListOrgAnniversaries - List all anniversaries in Org files

=head1 VERSION

This document describes version 0.472 of App::ListOrgAnniversaries (from Perl distribution App-OrgUtils), released on 2020-02-06.

=head1 SYNOPSIS

 # See list-org-anniversaries script

=head1 FUNCTIONS


=head2 list_org_anniversaries

Usage:

 list_org_anniversaries(%args) -> [status, msg, payload, meta]

List all anniversaries in Org files.

This function expects contacts in the following format:

 * First last                              :office:friend:
   :PROPERTIES:
   :BIRTHDAY:     1900-06-07
   :EMAIL:        foo@example.com
   :OTHERFIELD:   ...
   :END:

or:

 * Some name                               :office:
   - birthday   :: [1900-06-07 ]
   - email      :: foo@example.com
   - otherfield :: ...

Using PROPERTIES, dates currently must be specified in "YYYY-MM-DD" format.
Other format will be supported in the future. Using description list, dates can
be specified using normal Org timestamps (repeaters and warning periods will be
ignored).

By convention, if year is '1900' it is assumed to mean year is not specified.

By default, all contacts' anniversaries will be listed. You can filter contacts
using tags ('has_tags' and 'lacks_tags' options), or by 'due_in' and
'max_overdue' options (due_in=14 and max_overdue=2 is what I commonly use in my
startup script).

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<due_in> => I<int>

Only show anniversaries that are due in this number of days.

=item * B<field_pattern> => I<str> (default: "(?:birthday|anniversary)")

Field regex that specifies anniversaries.

=item * B<files>* => I<array[str]>

=item * B<has_tags> => I<array[str]>

Filter headlines that have the specified tags.

=item * B<lacks_tags> => I<array[str]>

Filter headlines that don't have the specified tags.

=item * B<max_overdue> => I<int>

Don't show dates that are overdue more than this number of days.

=item * B<sort> => I<str|code> (default: "due_date")

Specify sorting.

If string, must be one of 'date', '-date' (descending).

If code, sorting code will get [REC, DUE_DATE] as the items to compare, where
REC is the final record that will be returned as final result (can be a string
or a hash, if 'detail' is enabled), and DUE_DATE is the DateTime object.

=item * B<time_zone> => I<str>

Will be passed to parser's options.

If not set, TZ environment variable will be picked as default.

=item * B<today> => I<obj>

Assume today's date.

You can provide Unix timestamp or DateTime object. If you provide a DateTime
object, remember to set the correct time zone.


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

Please visit the project's homepage at L<https://metacpan.org/release/App-OrgUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-OrgUtils>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-OrgUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020, 2019, 2018, 2017, 2016, 2015, 2014, 2013, 2012, 2011 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
