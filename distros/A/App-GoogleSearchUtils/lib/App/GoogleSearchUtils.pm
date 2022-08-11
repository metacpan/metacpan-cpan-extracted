package App::GoogleSearchUtils;

use 5.010001;
use strict;
use warnings;
use Log::ger;

use Perinci::Object 'envresmulti';

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-08-11'; # DATE
our $DIST = 'App-GoogleSearchUtils'; # DIST
our $VERSION = '0.008'; # VERSION

our %SPEC;

$SPEC{google_search} = {
    v => 1.1,
    summary => 'Open google search page in browser',
    args => {
        queries => {
            'x.name.is_plural' => 1,
            'x.name.singular' => 'query',
            schema => ['array*', of=>'str*'],
            req => 1,
            pos => 0,
            slurpy => 1,
        },
        delay => {
            summary => 'Delay between opening each query',
            schema => 'duration*',
        },
        prepend => {
            summary => 'String to add at the beginning of each query',
            schema => 'str*',
        },
        append => {
            summary => 'String to add at the end of each query',
            schema => 'str*',
        },
        num => {
            summary => 'Number of results per page',
            schema => 'posint*',
            default => 100,
        },
        time_start => {
            schema => ['date*', 'x.perl.coerce_rules' => ['From_str::natural'], 'x.perl.coerce_to'=>'DateTime'],
            tags => ['category:time-period-criteria'],
        },
        time_end => {
            schema => ['date*', 'x.perl.coerce_rules' => ['From_str::natural'], 'x.perl.coerce_to'=>'DateTime'],
            tags => ['category:time-period-criteria'],
        },
        time_past => {
            summary => 'Limit time period to the past hour/24hour/week/month/year',
            schema => ['str*', in=>[qw/hour 24hour day week month year/]],
            tags => ['category:time-period-criteria'],
        },
        action => {
            summary => 'What to do with the URLs',
            schema => ['str*', in=>[qw/open_url print_url print_html_link print_org_link/]],
            default => 'open_url',
            cmdline_aliases => {
                open_url        => {is_flag=>1, summary=>'Alias for --action=open_url'       , code=>sub {$_[0]{action}='open_url'       }},
                print_url       => {is_flag=>1, summary=>'Alias for --action=print_url'      , code=>sub {$_[0]{action}='print_url'      }},
                print_html_link => {is_flag=>1, summary=>'Alias for --action=print_html_link', code=>sub {$_[0]{action}='print_html_link'}},
                print_org_link  => {is_flag=>1, summary=>'Alias for --action=print_org_link' , code=>sub {$_[0]{action}='print_org_link' }},
            },
            description => <<'_',

Instead of opening the queries in browser, you can also do other action instead.
For example, `print_url` will print the search URL. `print_html_link` will print
the HTML link (the <a> tag). And `print_org_link` will print the Org-mode link,
e.g. `[[url...][query]]`.

_
        },
        type => {
            summary => 'Search type',
            schema => ['str*', in=>[qw/web image video news map/]],
            default => 'web',
            cmdline_aliases => {
                web   => {is_flag=>1, summary=>'Alias for --type=web'  , code=>sub {$_[0]{type}='web'  }},
                image => {is_flag=>1, summary=>'Alias for --type=image', code=>sub {$_[0]{type}='image'}},
                video => {is_flag=>1, summary=>'Alias for --type=video', code=>sub {$_[0]{type}='video'}},
                news  => {is_flag=>1, summary=>'Alias for --type=news' , code=>sub {$_[0]{type}='news' }},
                map   => {is_flag=>1, summary=>'Alias for --type=map'  , code=>sub {$_[0]{type}='map'  }},
            },
        },
    },
    args_rels => {
        choose_all => [qw/time_start time_end/],
        choose_one => [qw/time_start time_past/],
    },
    examples => [
        {
            summary => 'Open a single query, show 100 results',
            src => '[[prog]] "a query" -n 100',
            src_plang => 'bash',
            test => 0,
            'x.doc.show_result' => 0,
        },
        {
            summary => 'Open several queries, limit time period all search to the past month',
            src => '[[prog]] "query one" query2 "query number three" --time-past month',
            src_plang => 'bash',
            test => 0,
            'x.doc.show_result' => 0,
        },
        {
            summary => 'Use a custom browser',
            src => 'BROWSER=lynx [[prog]] "a query"',
            src_plang => 'bash',
            test => 0,
            'x.doc.show_result' => 0,
        },
        {
            summary => 'Use with firefox-container',
            src => 'BROWSER="firefox-container mycontainer" [[prog]] "query one" query2',
            src_plang => 'bash',
            test => 0,
            'x.doc.show_result' => 0,
        },
        {
            summary => 'Show image search URLs instead of opening them in browser',
            src => '[[prog]] --image --print-url "query one" query2',
            src_plang => 'bash',
            test => 0,
            'x.doc.show_result' => 0,
        },
        {
            summary => 'Print map search URLs as Org links',
            src => '[[prog]] --map --print-org-link "jakarta selatan" "kebun raya bogor"',
            src_plang => 'bash',
            test => 0,
            'x.doc.show_result' => 0,
        },
    ],
    links => [
        {url=>'prog:firefox-container'},
        {url=>'pm:App::FirefoxMultiAccountContainersUtils'},
    ],
};
sub google_search {
    require Browser::Open;
    require URI::Escape;

    my %args = @_;
    # XXX schema
    my $num = defined($args{num}) ? $args{num} + 0 : 100;
    my $action = $args{action} // 'web';
    my $type = $args{type} // 'web';

    my @rows;
    my $envres = envresmulti();
    my $i = -1;
    for my $query0 (@{ $args{queries} }) {
        $i++;
        if ($i > 0 && $args{delay}) {
            log_trace "Sleeping %s second(s) ...", $args{delay};
            sleep $args{delay};
        }
        my $query = join(
            "",
            defined($args{prepend}) ? $args{prepend} : "",
            $query0,
            defined($args{append}) ? $args{append} : "",
        );
        my $query_esc = URI::Escape::uri_escape($query);

        my $time_param = '';
        if (my $p = $args{time_past}) {
            if ($p eq 'h' || $p eq 'hour') {
                $time_param = 'tbs=qdr:h';
            } elsif ($p eq '24hour' || $p eq 'day') {
                $time_param = 'tbs=qdr:d';
            } elsif ($p eq 'w' || $p eq 'week') {
                $time_param = 'tbs=qdr:w';
            } elsif ($p eq 'm' || $p eq 'month') {
                $time_param = 'tbs=qdr:m';
            } elsif ($p eq 'y' || $p eq 'year') {
                $time_param = 'tbs=qdr:y';
            } else {
                return [400, "Invalid time_past value '$p'"];
            }
        } elsif ($args{time_start} && $args{time_end}) {
            my ($t1, $t2) = ($args{time_start}, $args{time_end});
            $time_param = "tbs=".URI::Escape::uri_escape(
                "cdr:1,cd_min:".
                ($args{time_start}->strftime("%m/%d/%Y")).
                ",cd_max:".($args{time_end}->strftime("%m/%d/%Y"))
            );
        }

        my $url;
        if ($type eq 'web') {
            $url = "https://www.google.com/search?num=$num&q=$query_esc" .
                ($time_param ? "&$time_param" : "");
        } elsif ($type eq 'image') {
            $url = "https://www.google.com/search?num=$num&q=$query_esc&tbm=isch" .
                ($time_param ? "&$time_param" : "");
        } elsif ($type eq 'video') {
            $url = "https://www.google.com/search?num=$num&q=$query_esc&tbm=isch" .
                ($time_param ? "&$time_param" : "");
        } elsif ($type eq 'news') {
            $url = "https://www.google.com/search?num=$num&q=$query_esc&tbm=nws" .
                ($time_param ? "&$time_param" : "");
        } elsif ($type eq 'map') {
            return [409, "Can't specify time period for map search"];
            $url = "https://www.google.com/maps/search/$query_esc/";
        } else {
            return [400, "Unknown type '$type'"];
        }

        if ($action eq 'open_url') {
            my $res = Browser::Open::open_browser($url);
            $envres->add_result(
                ($res ? (500, "Failed") : (200, "OK")), {item_id=>$i});
        } elsif ($action eq 'print_url') {
            push @rows, $url;
        } elsif ($action eq 'print_html_link') {
            require HTML::Entities;
            my $query_htmlesc = HTML::Entities::encode_entities($query);
            push @rows, qq(<a href="$url">$query_htmlesc<</a>);
        } elsif ($action eq 'print_org_link') {
            push @rows, qq([[$url][$query]]);
        } else {
            return [400, "Unknown action '$action'"];
        }
    }
    if ($action eq 'open_url') {
        return $envres->as_struct;
    } else {
        return [200, "OK", \@rows];
    }
}

1;
# ABSTRACT: CLI utilites related to google searching

__END__

=pod

=encoding UTF-8

=head1 NAME

App::GoogleSearchUtils - CLI utilites related to google searching

=head1 VERSION

This document describes version 0.008 of App::GoogleSearchUtils (from Perl distribution App-GoogleSearchUtils), released on 2022-08-11.

=head1 SYNOPSIS

This distribution provides the following utilities:

=over

=item * L<google-search>

=back

=head1 FUNCTIONS


=head2 google_search

Usage:

 google_search(%args) -> [$status_code, $reason, $payload, \%result_meta]

Open google search page in browser.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<action> => I<str> (default: "open_url")

What to do with the URLs.

Instead of opening the queries in browser, you can also do other action instead.
For example, C<print_url> will print the search URL. C<print_html_link> will print
the HTML link (the <a> tag). And C<print_org_link> will print the Org-mode link,
e.g. C<[[url...][query]]>.

=item * B<append> => I<str>

String to add at the end of each query.

=item * B<delay> => I<duration>

Delay between opening each query.

=item * B<num> => I<posint> (default: 100)

Number of results per page.

=item * B<prepend> => I<str>

String to add at the beginning of each query.

=item * B<queries>* => I<array[str]>

=item * B<time_end> => I<date>

=item * B<time_past> => I<str>

Limit time period to the past hourE<sol>24hourE<sol>weekE<sol>monthE<sol>year.

=item * B<time_start> => I<date>

=item * B<type> => I<str> (default: "web")

Search type.


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

Please visit the project's homepage at L<https://metacpan.org/release/App-GoogleSearchUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-GoogleSearchUtils>.

=head1 SEE ALSO


L<App::FirefoxMultiAccountContainersUtils>.

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

This software is copyright (c) 2022, 2020, 2018 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-GoogleSearchUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
