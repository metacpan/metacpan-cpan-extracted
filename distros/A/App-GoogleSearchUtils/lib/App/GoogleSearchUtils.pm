package App::GoogleSearchUtils;

use 5.010001;
use strict;
use warnings;
use Log::ger;

use Perinci::Object 'envresmulti';

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-10-21'; # DATE
our $DIST = 'App-GoogleSearchUtils'; # DIST
our $VERSION = '0.016'; # VERSION

our %SPEC;

sub _fmt_html_link {
    my ($url, $query) = @_;
    require HTML::Entities;
    my $query_htmlesc = HTML::Entities::encode_entities($query // "(query)");
    qq(<a href="$url">$query_htmlesc<</a>);
}

sub _fmt_org_link {
    my ($url, $query) = @_;
    qq([[$url][$query]]);
}

$SPEC{google_search} = {
    v => 1.1,
    summary => '(DEPRECATED) Open google search page in browser',
    description => <<'_',

This utility can save you time when you want to open multiple queries (with
added common prefix/suffix words) or specify some options like time limit. It
will formulate the search URL(s) then open them for you in browser. You can also
specify to print out the URLs instead.

Aside from standard web search, you can also generate/open other searches like
image, video, news, or map.

_
    args => {
        queries => {
            'x.name.is_plural' => 1,
            'x.name.singular' => 'query',
            schema => ['array*', of=>'str*', min_len=>1],
            pos => 0,
            slurpy => 1,
        },
        queries_from => {
            summary => 'Supply queries from lines of text file (specify "-" for stdin)',
            schema => 'filename*',
        },
        delay => {
            summary => 'Delay between opening each query',
            schema => 'duration*',
            description => <<'_',

As an alternative to the `--delay` option, you can also use `--min-delay` and
`--max-delay` to set a random delay between a minimum and maximum value.

_
        },
        min_delay => {
            summary => 'Delay between opening each query',
            schema => 'duration*',
            description => <<'_',

As an alternative to the `--mindelay` and `--max-delay` options, you can also
use `--delay` to set a constant delay between requests.

_
        },
        max_delay => {
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
            schema => ['str*', in=>[qw/
                                          open_url
                                          print_url print_html_link print_org_link
                                          save_html
                                          print_result_link
                                          print_result_html_link
                                          print_result_org_link
                                      /]],
            default => 'open_url',
            cmdline_aliases => {
                open_url               => {is_flag=>1, summary=>'Alias for --action=open_url'       , code=>sub {$_[0]{action}='open_url'       }},
                print_url              => {is_flag=>1, summary=>'Alias for --action=print_url'      , code=>sub {$_[0]{action}='print_url'      }},
                print_html_link        => {is_flag=>1, summary=>'Alias for --action=print_html_link', code=>sub {$_[0]{action}='print_html_link'}},
                print_org_link         => {is_flag=>1, summary=>'Alias for --action=print_org_link' , code=>sub {$_[0]{action}='print_org_link' }},
                save_html              => {is_flag=>1, summary=>'Alias for --action=save_html'      , code=>sub {$_[0]{action}='save_html'      }},
                print_result_link      => {is_flag=>1, summary=>'Alias for --action=extract_links'  , code=>sub {$_[0]{action}='print_result_link'      }},
                print_result_html_link => {is_flag=>1, summary=>'Alias for --action=extract_links'  , code=>sub {$_[0]{action}='print_result_html_link' }},
                print_result_org_link  => {is_flag=>1, summary=>'Alias for --action=extract_links'  , code=>sub {$_[0]{action}='print_result_org_link'  }},
            },
            description => <<'_',

Instead of opening the queries in browser (`open_url`), you can also do other
action instead.

**Printing search URLs**: `print_url` will print the search URL.
`print_html_link` will print the HTML link (the <a> tag). And `print_org_link`
will print the Org-mode link, e.g. `[[url...][query]]`.

**Saving search result HTMLs**: `save_html` will first visit each search URL
(currently using <pm:Firefox::Marionette>) then save each result page to a file
named `<num>-<query>.html` in the current directory. Existing files will not be
overwritten; the utility will save to `*.html.1`, `*.html.2` and so on instead.

**Extracting search result links**: `print_result_link` will first will first
visit each search URL (currently using <pm:Firefox::Marionette>) then extract
result links and print them. `print_result_html_link` and
`print_result_org_link` are similar but will instead format each link as HTML
and Org link, respectively.

Currently the `print_result_*link` actions are not very useful because result
HTML page is now obfuscated by Google. Thus we can only extract all links in
each page instead of selecting (via DOM) only the actual search result entry
links, etc.

If you want to filter the links further by domain, path, etc. you can use
<prog:grep-url>.


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
        'choose_all&' => [
            [qw/time_start time_end/],
            [qw/min_delay max_delay/],
        ],
        'choose_one&' => [
            [qw/delay min_delay/],
            [qw/time_start time_past/],
        ],
        req_one => [qw/queries queries_from/],
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
            summary => 'Open queries from each line of file, add delay 3s after each query (e.g. to avoid getting rate-limited by Google)',
            src => '[[prog]] --queries-from phrases.txt --delay 3s',
            src_plang => 'bash',
            test => 0,
            'x.doc.show_result' => 0,
        },
        {
            summary => 'Open queries from each line of stdin',
            src => 'prog-that-produces-lines-of-phrases | [[prog]] --queries-from -',
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
        {
            summary => 'Prepend prefix words to each query',
            src => '[[prog]] --prepend "imdb " "carrie" "hocus pocus" "raya"',
            src_plang => 'bash',
            test => 0,
            'x.doc.show_result' => 0,
        },
        {
            summary => 'Append suffix words to each query',
            src => '[[prog]] --append " net worth" "lewis capaldi" "beyonce" "lee mack" "mariah carey"',
            src_plang => 'bash',
            test => 0,
            'x.doc.show_result' => 0,
        },
        {
            summary => 'Visit the search URL for each query using Firefox::Marionette then extract and print the links',
            description => <<'_',

Currently not very useful because result HTML page is now obfuscated by Google
so we can just extract all links in each page instead of selecting (via DOM)
only the result links, etc.

If you want to filter the links further by domain, path, etc. you can use
<prog:grep-url>.

_
            src => '[[prog]] "lee mack" --print-result-link',
            src_plang => 'bash',
            test => 0,
            'x.doc.show_result' => 0,
        },
        {
            summary => 'Get the IMDB URL for Lee Mack',
            src => '[[prog]] "lee mack imdb" --print-result-link | grep-url --host-contains imdb.com | head -n1',
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

    my @queries;
    if (defined $args{queries_from}) {
        require File::Slurper::Dash;
        my $content = File::Slurper::Dash::read_text($args{queries_from});
        @queries = map { chomp(my $line = $_); $line } split /^/m, $content;
    } elsif ($args{queries} && @{ $args{queries} }) {
        @queries = @{ $args{queries} };
    } else {
        return [400, "Please specify either queries or queries_from"];
    }

    my @rows;
    my $envres = envresmulti();
    my $i = -1;
    for my $query0 (@queries) {
        $i++;
        if ($i > 0) {
            if ($args{delay}) {
                log_trace "Sleeping %s second(s) ...", $args{delay};
                sleep $args{delay};
            } elsif ($args{min_delay} && $args{max_delay}) {
                my $delay = $args{min_delay} +
                    int(rand($args{max_delay} - $args{min_delay} + 1));
                log_trace "Sleeping between %s and %s second(s): %s second(s) ...",
                    $args{min_delay}, $args{max_delay}, $delay;
                sleep $delay;
            }
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
            return [409, "Can't specify time period for map search"] if length $time_param;
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
            push @rows, _fmt_html_link($url, $query);
        } elsif ($action eq 'print_org_link') {
            push @rows, _fmt_org_link($url, $query);
        } elsif ($action =~ /\A(save_html|(print_result_(|html_|org_)link))\z/) {
            state $ff1 = do {
                require Firefox::Marionette;
                log_trace "Instantiating Firefox::Marionette instance ...";
                Firefox::Marionette->new;
            };
            log_trace "Retrieving URL $url ...";
            my $ff2 = $ff1->go($url);
            if ($action eq 'save_html') {
                require File::Slurper;
                (my $query_save = $query) =~ s/[^A-Za-z0-9_-]+/_/g;
                my $filename0 = sprintf "%d-%s.%s.html", $i+1, $query_save, $type;
                my $filename;
                my $j = -1;
                while (1) {
                    $j++;
                    $filename = $filename0 . ($j ? ".$j" : "");
                    last unless -f $filename;
                }
                log_trace "Saving query[%d] result to %s ...", $i, $filename;
                File::Slurper::write_text($filename, $ff2->html);
            } else {
                # extract links first
                my @links = $ff2->links;
                for my $link (@links) {
                    if ($action =~ /html/) {
                        push @rows, _fmt_html_link($link->url_abs . "", $link->text);
                    } elsif ($action =~ /html/) {
                        push @rows, _fmt_org_link($link->url_abs . "", $link->text);
                    } else {
                        push @rows, $link->url_abs . "";
                    }
                }
            }
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
# ABSTRACT: (DEPRECATED) CLI utilites related to google searching

__END__

=pod

=encoding UTF-8

=head1 NAME

App::GoogleSearchUtils - (DEPRECATED) CLI utilites related to google searching

=head1 VERSION

This document describes version 0.016 of App::GoogleSearchUtils (from Perl distribution App-GoogleSearchUtils), released on 2022-10-21.

=head1 SYNOPSIS

This distribution provides the following utilities:

=over

=item * L<google-search>

=back

=head1 DESCRIPTION

*DEPRECATION NOTICE*: Deprecated in favor of L<App::WebSearchUtils> and
 L<web-search>.

=head1 FUNCTIONS


=head2 google_search

Usage:

 google_search(%args) -> [$status_code, $reason, $payload, \%result_meta]

(DEPRECATED) Open google search page in browser.

This utility can save you time when you want to open multiple queries (with
added common prefix/suffix words) or specify some options like time limit. It
will formulate the search URL(s) then open them for you in browser. You can also
specify to print out the URLs instead.

Aside from standard web search, you can also generate/open other searches like
image, video, news, or map.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<action> => I<str> (default: "open_url")

What to do with the URLs.

Instead of opening the queries in browser (C<open_url>), you can also do other
action instead.

B<Printing search URLs>: C<print_url> will print the search URL.
C<print_html_link> will print the HTML link (the <a> tag). And C<print_org_link>
will print the Org-mode link, e.g. C<[[url...][query]]>.

B<Saving search result HTMLs>: C<save_html> will first visit each search URL
(currently using L<Firefox::Marionette>) then save each result page to a file
named C<< E<lt>numE<gt>-E<lt>queryE<gt>.html >> in the current directory. Existing files will not be
overwritten; the utility will save to C<*.html.1>, C<*.html.2> and so on instead.

B<Extracting search result links>: C<print_result_link> will first will first
visit each search URL (currently using L<Firefox::Marionette>) then extract
result links and print them. C<print_result_html_link> and
C<print_result_org_link> are similar but will instead format each link as HTML
and Org link, respectively.

Currently the C<print_result_*link> actions are not very useful because result
HTML page is now obfuscated by Google. Thus we can only extract all links in
each page instead of selecting (via DOM) only the actual search result entry
links, etc.

If you want to filter the links further by domain, path, etc. you can use
L<grep-url>.

=item * B<append> => I<str>

String to add at the end of each query.

=item * B<delay> => I<duration>

Delay between opening each query.

As an alternative to the C<--delay> option, you can also use C<--min-delay> and
C<--max-delay> to set a random delay between a minimum and maximum value.

=item * B<max_delay> => I<duration>

Delay between opening each query.

=item * B<min_delay> => I<duration>

Delay between opening each query.

As an alternative to the C<--mindelay> and C<--max-delay> options, you can also
use C<--delay> to set a constant delay between requests.

=item * B<num> => I<posint> (default: 100)

Number of results per page.

=item * B<prepend> => I<str>

String to add at the beginning of each query.

=item * B<queries> => I<array[str]>

(No description)

=item * B<queries_from> => I<filename>

Supply queries from lines of text file (specify "-" for stdin).

=item * B<time_end> => I<date>

(No description)

=item * B<time_past> => I<str>

Limit time period to the past hourE<sol>24hourE<sol>weekE<sol>monthE<sol>year.

=item * B<time_start> => I<date>

(No description)

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

L<App::WebSearchUtils>, L<App::DDGSearchUtils>, L<App::BraveSearchUtils>,
L<App::BingSearchUtils> - I'm sick of getting CAPTCHA's with Google (how many
times in a few minutes do I have to prove that I'm human?), so lately been
switching to other search engines when I have to do many searches.


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
