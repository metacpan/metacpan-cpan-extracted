package App::ListOrgAnniversaries;

use 5.010;
use strict;
use warnings;
use Log::ger;

use App::OrgUtils;
use Cwd qw(abs_path);
use DateTime;
use Digest::MD5 qw(md5_hex);
use Exporter 'import';
use Lingua::EN::Numbers::Ordinate;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-07-12'; # DATE
our $DIST = 'App-OrgUtils'; # DIST
our $VERSION = '0.486'; # VERSION

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
            for my $tag (@{ $args->{has_tags} }) {
                return unless grep { $_ eq $tag } @$tags;
            }
        }
        if ($args->{lacks_tags}) {
            for my $tag (@{ $args->{lacks_tags} }) {
                return if grep { $_ eq $tag } @$tags;
            }
        }
    }

    my @annivs; # elem = [$field, $date, $date_reminded]
    $hl->walk(
        sub {
            my ($el) = @_;

            if ($el->isa('Org::Element::Timestamp')) {
                my $field = $el->field_name;
                return unless defined($field) &&
                    $field =~ $args->{field_pattern};
                if ($field =~ $args->{reminded_field_pattern} && @annivs) {
                    $annivs[-1][2] = $el->datetime;
                } else {
                    push @annivs, [$field, $el->datetime];
                }
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
                    if ($k =~ $args->{reminded_field_pattern} && @annivs) {
                        $annivs[-1][2] = $el->datetime;
                    } else {
                        push @annivs, [
                            lc $k,
                            DateTime->new(year=>$1, month=>$2, day=>$3,
                                          time_zone=>$tz),
                        ];
                    }
                    return;
                }
            }
        }
    );

    if (!@annivs) {
        log_debug("Headline doesn't contain anniversary fields, skipped");
        return;
    }

  ANNIV:
    for my $anniv (@annivs) {
        my ($field, $date, $date_reminded) = @$anniv;
        log_debug("Anniversary found: field=%s, date=%s, date reminded=%s",
                     $field, $date->ymd, $date_reminded ? $date_reminded->ymd : undef);
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

          REMINDED: {
                if ($date_reminded) {
                    my $days_reminded;
                    $days_reminded = ($date_reminded < $today ? -1:1) *
                        $date_reminded->delta_days($today)->in_units('days');
                    last REMINDED if defined($args->{due_in}) &&
                        $days_reminded > $args->{due_in};
                    last REMINDED if defined($args->{max_overdue}) &&
                        -$days_reminded > $args->{max_overdue};
                    last REMINDED if !defined($args->{due_in}) &&
                        !defined($args->{max_overdue}) &&
                        DateTime->compare($date_reminded, $today) < 0;
                    #log_debug("Anniversary already reminded, skipped");
                    next DATE;
                }
            }

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
'max_overdue' options (due_in=14 and max_overdue=7 is what I commonly use in my
startup script).

If you have acted on someone's birthday or anniversary, you can add another
field with name: the anniversary field + " reminded" (this is customizable using
the options `reminded_field_pattern`). For example:

    * First last                              :office:friend:
      :PROPERTIES:
      :BIRTHDAY:     1900-06-07
      :BIRTHDAY_REMINDED:  2020-06-08
      :EMAIL:        foo@example.com
      :OTHERFIELD:   ...
      :END:

or:

    * Some name                               :office:
      - birthday   :: [1900-06-07 ]
      - birthday reminded :: [2020-06-09]
      - email      :: foo@example.com
      - otherfield :: ...

and the reminder will not be shown again.

_
    args    => {
        %App::OrgUtils::common_args1,
        field_pattern => {
            summary => 'Regex for fields that specify anniversaries',
            schema  => 're*',
            default => qr/(?:birthday|anniversary)/i,
        },
        reminded_field_pattern => {
            schema => 're*',
            default => qr/reminded/i,
        },
        reminded_suffix => {
            schema => 'str*',
            default => ' reminded',
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
    require Org::Parser;

    my %args = @_;

    my $sort  = $args{sort};
    my $tz    = $args{time_zone} // $ENV{TZ} // "UTC";
    my $files = $args{files};
    $args{field_pattern} //= qr/(?:birthday|anniversary)/i;
    $args{reminded_field_pattern} //= qr/reminded/i;

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

This document describes version 0.486 of App::ListOrgAnniversaries (from Perl distribution App-OrgUtils), released on 2023-07-12.

=head1 SYNOPSIS

 # See list-org-anniversaries script

=head1 FUNCTIONS


=head2 list_org_anniversaries

Usage:

 list_org_anniversaries(%args) -> [$status_code, $reason, $payload, \%result_meta]

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
'max_overdue' options (due_in=14 and max_overdue=7 is what I commonly use in my
startup script).

If you have acted on someone's birthday or anniversary, you can add another
field with name: the anniversary field + " reminded" (this is customizable using
the options C<reminded_field_pattern>). For example:

 * First last                              :office:friend:
   :PROPERTIES:
   :BIRTHDAY:     1900-06-07
   :BIRTHDAY_REMINDED:  2020-06-08
   :EMAIL:        foo@example.com
   :OTHERFIELD:   ...
   :END:

or:

 * Some name                               :office:
   - birthday   :: [1900-06-07 ]
   - birthday reminded :: [2020-06-09]
   - email      :: foo@example.com
   - otherfield :: ...

and the reminder will not be shown again.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<due_in> => I<int>

Only show anniversaries that are due in this number of days.

=item * B<field_pattern> => I<re> (default: qr((?:birthday|anniversary))i)

Regex for fields that specify anniversaries.

=item * B<files>* => I<array[filename]>

(No description)

=item * B<has_tags> => I<array[str]>

Filter headlines that have the specified tags.

=item * B<lacks_tags> => I<array[str]>

Filter headlines that don't have the specified tags.

=item * B<max_overdue> => I<int>

Don't show dates that are overdue more than this number of days.

=item * B<reminded_field_pattern> => I<re> (default: qr(reminded)i)

(No description)

=item * B<reminded_suffix> => I<str> (default: " reminded")

(No description)

=item * B<sort> => I<str|code> (default: "due_date")

Specify sorting.

If string, must be one of 'date', '-date' (descending).

If code, sorting code will get [REC, DUE_DATE] as the items to compare, where
REC is the final record that will be returned as final result (can be a string
or a hash, if 'detail' is enabled), and DUE_DATE is the DateTime object.

=item * B<time_zone> => I<date::tz_name>

Will be passed to parser's options.

If not set, TZ environment variable will be picked as default.

=item * B<today> => I<obj>

Assume today's date.

You can provide Unix timestamp or DateTime object. If you provide a DateTime
object, remember to set the correct time zone.


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

This software is copyright (c) 2023, 2022, 2021, 2020, 2019, 2018, 2017, 2016, 2015, 2014, 2013, 2012, 2011 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-OrgUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
