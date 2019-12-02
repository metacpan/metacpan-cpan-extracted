package App::durseq;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2019-11-29'; # DATE
our $DIST = 'App-durseq'; # DIST
our $VERSION = '0.004'; # VERSION

use 5.010001;
use strict;
use warnings;

our %SPEC;

$SPEC{durseq} = {
    v => 1.1,
    summary => 'Generate a sequence of durations',
    description => <<'_',

This utility is similar to Perl script <prog:dateseq>, except that it generates
a sequence of durations instead of dates.

_
    args_rels => {
    },
    args => {
        from => {
            summary => 'Starting duration',
            schema => ['duration*', {
                'x.perl.coerce_to' => 'DateTime::Duration',
                'x.perl.coerce_rules' => ['From_str::iso8601'],
            }],
            pos => 0,
        },
        to => {
            summary => 'Ending duration, if not specified will generate an infinite* stream of durations',
            schema => ['duration*', {
                'x.perl.coerce_to' => 'DateTime::Duration',
                'x.perl.coerce_rules' => ['From_str::iso8601'],
            }],
            pos => 1,
        },
        increment => {
            summary => 'Increment, default is one day (P1D)',
            schema => ['duration*', {
                'x.perl.coerce_to' => 'DateTime::Duration',
                'x.perl.coerce_rules' => ['From_str::iso8601'],
            }],
            cmdline_aliases => {i=>{}},
            pos => 2,
        },
        reverse => {
            summary => 'Decrement instead of increment',
            schema => 'true*',
            cmdline_aliases => {r=>{}},
        },

        #header => {
        #    summary => 'Add a header row',
        #    schema => 'str*',
        #},
        limit => {
            summary => 'Only generate a certain amount of items',
            schema => ['int*', min=>1],
            cmdline_aliases => {n=>{}},
        },

        format_class => {
            summary => 'Use a DateTime::Format::Duration::* class for formatting',
            schema => ['perl::modname'],
            default => 'ISO8601',
            tags => ['category:formatting'],
            completion => sub {
                require Complete::Module;
                my %args = @_;
                Complete::Module::complete_module(
                    word => $args{word}, ns_prefix => 'DateTime::Format::Duration');
            },
            description => <<'_',

By default, "ISO8601" (<pm:DateTime::Format::Duration::ISO8601>) is used.

_
        },
        format_class_attrs => {
            summary => 'Arguments to pass to constructor of DateTime::Format::* class',
            schema => ['hash'],
            tags => ['category:formatting'],
        },
    },
    examples => [
        {
            summary => 'Generate "infinite" durations from zero (then P1D, P2D, ...)',
            src => '[[prog]]',
            src_plang => 'bash',
            test => 0,
            'x.doc.show_result' => 0,
        },
        {
            summary => 'Generate durations from P0D to P10D',
            src => '[[prog]] P0D P10D',
            src_plang => 'bash',
            'x.doc.max_result_lines' => 5,
        },
        {
            summary => 'Generate durations from P0D to P10D, with 12 hours increment',
            src => '[[prog]] P0D P10D -i PT12H',
            src_plang => 'bash',
            'x.doc.max_result_lines' => 5,
        },
        {
            summary => 'Generate durations from P10D to P0D (reverse)',
            src => '[[prog]] P10D P0D -r',
            src_plang => 'bash',
            'x.doc.max_result_lines' => 5,
        },
        {
            summary => 'Generate 10 durations from P1M (increment 1 week)',
            src => '[[prog]] P1M -i P1W -n 10',
            src_plang => 'bash',
            'x.doc.max_result_lines' => 5,
        },
        #{
        #    summary => 'Generate a CSV data',
        #    src => '[[prog]] 2010-01-01 2015-01-31 -f "%Y,%m,%d" --header "year,month,day"',
        #    src_plang => 'bash',
        #    'x.doc.max_result_lines' => 5,
        #},
        #{
        #    summary => 'Use with fsql',
        #    src => q{[[prog]] 2010-01-01 2015-12-01 -f "%Y,%m" -i P1M --header "year,month" | fsql --add-csv - --add-csv data.csv -F YEAR -F MONTH 'SELECT year, month, data1 FROM stdin WHERE YEAR(data.date)=year AND MONTH(data.date)=month'},
        #    src_plang => 'bash',
        #    'x.doc.show_result' => 0,
        #},
    ],
};
sub durseq {
    require DateTime;
    require DateTime::Duration;
    require DateTime::Format::Duration::ISO8601;

    my %args = @_;

    my $base_dt = DateTime->now;

    $args{from} //= DateTime::Duration->new(days=>0);
    $args{increment} //= DateTime::Duration->new(days=>1);
    my $reverse = $args{reverse};

    my $cl = $args{format_class} // "ISO8601";
    $cl = "DateTime::Format::Duration::$cl";
    (my $cl_pm = "$cl.pm") =~ s!::!/!g;
    require $cl_pm;
    my $attrs = $args{format_class_attrs} // {};
    my $formatter = $cl->new(%$attrs);

    if (defined $args{to} || defined $args{limit}) {
        my @res;
        #push @res, $args{header} if $args{header};
        my $dtdur = $args{from}->clone;
        while (1) {
            if (defined $args{to}) {
                last if !$reverse && DateTime::Duration->compare($dtdur, $args{to}, $base_dt) > 0;
                last if  $reverse && DateTime::Duration->compare($dtdur, $args{to}, $base_dt) < 0;
            }
            push @res, $formatter->format_duration($dtdur);
            last if defined($args{limit}) && @res >= $args{limit};
            $dtdur = $reverse ? $dtdur - $args{increment} : $dtdur + $args{increment};
        }
        return [200, "OK", \@res];
    } else {
        # stream
        my $dtdur = $args{from}->clone;
        my $j     = $args{header} ? -1 : 0;
        my $next_dtdur;
        #my $finish;
        my $func0 = sub {
            #return undef if $finish;
            $dtdur = $next_dtdur if $j++ > 0;
            #return $args{header} if $j == 0 && $args{header};
            $next_dtdur = $reverse ?
                $dtdur - $args{increment} : $dtdur + $args{increment};
            #$finish = 1 if ...
            return $dtdur;
        };
        my $func = sub {
            while (1) {
                my $dtdur = $func0->();
                return undef unless defined $dtdur;
                #last if $code_filter->($dt);
                last;
            }
            $formatter->format_duration($dtdur);
        };
        return [200, "OK", $func, {schema=>'str*', stream=>1}];
    }
}

1;
# ABSTRACT: Generate a sequence of durations

__END__

=pod

=encoding UTF-8

=head1 NAME

App::durseq - Generate a sequence of durations

=head1 VERSION

This document describes version 0.004 of App::durseq (from Perl distribution App-durseq), released on 2019-11-29.

=head1 FUNCTIONS


=head2 durseq

Usage:

 durseq(%args) -> [status, msg, payload, meta]

Generate a sequence of durations.

This utility is similar to Perl script L<dateseq>, except that it generates
a sequence of durations instead of dates.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<format_class> => I<perl::modname> (default: "ISO8601")

Use a DateTime::Format::Duration::* class for formatting.

By default, "ISO8601" (L<DateTime::Format::Duration::ISO8601>) is used.

=item * B<format_class_attrs> => I<hash>

Arguments to pass to constructor of DateTime::Format::* class.

=item * B<from> => I<duration>

Starting duration.

=item * B<increment> => I<duration>

Increment, default is one day (P1D).

=item * B<limit> => I<int>

Only generate a certain amount of items.

=item * B<reverse> => I<true>

Decrement instead of increment.

=item * B<to> => I<duration>

Ending duration, if not specified will generate an infinite* stream of durations.

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

Please visit the project's homepage at L<https://metacpan.org/release/App-durseq>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-durseq>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-durseq>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
