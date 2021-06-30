package App::metasyn;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-06-26'; # DATE
our $DIST = 'App-metasyn'; # DIST
our $VERSION = '0.008'; # VERSION

use 5.010001;
use strict;
use warnings;

our %SPEC;

sub _shuffle_and_limit {
    my ($res, $args) = @_;
    if ($args->{shuffle}) {
        require List::Util;
        $res = [List::Util::shuffle(@$res)];
    }
    if (defined $args->{number} && $args->{number} > 0 && @$res > $args->{number}) {
        $res = [@{$res}[0 .. $args->{number}-1]];
    }
    $res;
}

$SPEC{metasyn} = {
    v => 1.1,
    summary => 'Alternative front-end to Acme::MetaSyntactic',
    description => <<'_',

This script is an alternative front-end for <pm:Acme::MetaSyntactic>. Compared
to the official CLI <prog:meta>, this CLI currently does not retrieve
themes/names remotely but:

* provides shell completion (but see <pm:App::ShellCompleter::meta> to add tab
  completion for the official CLI);
* provides an option to shuffle list of themes/categories/names returned;
* makes it easy to print all names in a theme;
* makes it easy to print all (or some) categories in a theme.

This CLI is more geared towards listing all themes/names/categories instead of
picking random ones.

_
    args => {
        action => {
            schema => ['str*', in=>[qw/list-themes list-names/]],
            default => 'list-names',
            cmdline_aliases => {
                l => { summary => 'List installed themes', is_flag => 1, code => sub { $_[0]{action} = 'list-themes' } },
            },
        },
        theme => {
            schema => 'str*',
            pos => 0,
            completion => sub {
                require Complete::Acme::MetaSyntactic;
                Complete::Acme::MetaSyntactic::complete_meta_theme_and_category(@_);
            },
        },
        shuffle => {
            schema => 'true*',
            cmdline_aliases => {R=>{}},
        },
        random_theme => {
            schema => 'true*',
            cmdline_aliases => {T=>{}},
        },
        number => {
            summary => 'Limit only return this number of results',
            schema => 'posint*',
            cmdline_aliases => {n=>{}},
        },
        categories => {
            schema => 'true*',
            cmdline_aliases => {c=>{}},
        },
    },
    examples => [
        # listing names
        {
            summary => 'List all names from the default theme, foo',
            argv => [qw//],
            'x.doc.max_result_lines' => 10,
        },
        {
            summary => 'Return a single random name from the default theme (equivalent to: "meta")',
            argv => [qw/-n1 -R/],
        },
        {
            summary => 'List all names from a theme',
            argv => [qw/christmas/],
            'x.doc.max_result_lines' => 10,
        },
        {
            summary => 'List all names from a category of a theme in random order, return only 3 (equivalent to: "meta christmas/elf 3")',
            argv => [qw(christmas/elf -n3 -R)],
        },
        {
            summary => 'Return a single random name from a theme (equivalent to: "meta christmas")',
            argv => [qw(christmas -n1 -R)],
        },
        {
            summary => 'Return a single random name from a random theme',
            argv => [qw(-T -n1 -R)],
        },

        # listing themes
        {
            summary => 'List all installed themes (equivalent to: "meta --themes")',
            argv => [qw/-l/],
            'x.doc.max_result_lines' => 10,
        },
        {
            summary => 'List 3 random themes (equivalent to: "meta --themes | shuf | head -n3")',
            argv => [qw/-l -n3 -R/],
        },
        {
            summary => 'List all installed themes, along with all their categories',
            argv => [qw/-l -c/],
            'x.doc.max_result_lines' => 10,
        },

        # listing categories
        {
            summary => 'List all categories from a theme',
            argv => [qw(christmas -c)],
            'x.doc.max_result_lines' => 10,
        },
        {
            summary => 'List 2 categories from a theme, in random order',
            argv => [qw(christmas -c -n2 -R)],
            'x.doc.max_result_lines' => 10,
        },
    ],
    links => [
        {url=>'prog:meta'},
    ],
};
sub metasyn {
    no strict 'refs';
    require Acme::MetaSyntactic;

    my %args = @_;

    my $action = $args{action};

    if ($action eq 'list-themes') {
        my @res;
        for my $th (Acme::MetaSyntactic->new->themes) {
            if ($args{categories}) {
                my $pkg = "Acme::MetaSyntactic::$th";
                (my $pkg_pm = "$pkg.pm") =~ s!::!/!g;
                return [500, "Can't load $pkg: $@"]
                    unless (eval { require $pkg_pm; 1 });
                my @cats;
                @cats = $pkg->categories if $pkg->can("categories");
                if (@cats) {
                    push @res, "$th/$_" for sort @cats;
                } else {
                    push @res, $th;
                }
            } else {
                push @res, $th;
            }
        }
        return [200, "OK", _shuffle_and_limit(\@res, \%args)];
    }

    my $theme;
    if ($args{theme}) {
        $theme = $args{theme};
    } elsif ($args{random_theme}) {
        my @themes = Acme::MetaSyntactic->new->themes;
        $theme = $themes[rand @themes];
    } else {
        $theme = 'foo';
    }
    my $cat = $theme =~ s{/(.+)\z}{} ? $1 : undef;

    my $pkg = "Acme::MetaSyntactic::$theme";
    (my $pkg_pm = "$pkg.pm") =~ s!::!/!g;
    return [500, "Can't load $pkg: $@"] unless (eval { require $pkg_pm; 1 });

    if ($args{categories}) {
        my @res;
        eval { @res = sort $pkg->categories };
        #warn if $@;
        return [200, "OK", _shuffle_and_limit(\@res, \%args)];
    }
    #my $meta = Acme::MetaSyntactic->new($theme);
    my @names;
    if (defined $cat) {
        @names = @{ ${"$pkg\::MultiList"}{$cat} // [] };
    } else {
        @names = @{"$pkg\::List"};
        unless (@names) {
            @names = map { @{ ${"$pkg\::MultiList"}{$_} } }
                sort keys %{"$pkg\::MultiList"};
        }
    }
    return [200, "OK", _shuffle_and_limit(\@names, \%args)];
}

1;
# ABSTRACT: Alternative front-end to Acme::MetaSyntactic

__END__

=pod

=encoding UTF-8

=head1 NAME

App::metasyn - Alternative front-end to Acme::MetaSyntactic

=head1 VERSION

This document describes version 0.008 of App::metasyn (from Perl distribution App-metasyn), released on 2021-06-26.

=head1 SYNOPSIS

Use the included script L<metasyn>.

=head1 FUNCTIONS


=head2 metasyn

Usage:

 metasyn(%args) -> [$status_code, $reason, $payload, \%result_meta]

Alternative front-end to Acme::MetaSyntactic.

Examples:

=over

=item * List all names from the default theme, foo:

 metasyn();

Result:

 [
   200,
   "OK",
   [
     "foo",
     "bar",
     "baz",
     "foobar",
 # ...snipped 37 lines for brevity...
     "weide",
     "does",
     "hok",
     "duif",
     "schapen",
   ],
   {},
 ]

=item * Return a single random name from the default theme (equivalent to: "meta"):

 metasyn(number => 1, shuffle => 1); # -> [200, "OK", ["mies"], {}]

=item * List all names from a theme:

 metasyn(theme => "christmas");

Result:

 [
   200,
   "OK",
   [
     "bushy",
     "evergreen",
     "shinny",
     "upatree",
 # ...snipped 59 lines for brevity...
     "mcsnowballs",
     "mcicicles",
     "mcblizzard",
     "mcsparkles",
     "mcsnowflakes",
   ],
   {},
 ]

=item * List all names from a category of a theme in random order, return only 3 (equivalent to: "meta christmasE<sol>elf 3"):

 metasyn(theme => "christmas/elf", number => 3, shuffle => 1);

Result:

 [200, "OK", ["bushy", "pepper", "sugarplum"], {}]

=item * Return a single random name from a theme (equivalent to: "meta christmas"):

 metasyn(theme => "christmas", number => 1, shuffle => 1); # -> [200, "OK", ["twinkle"], {}]

=item * Return a single random name from a random theme:

 metasyn(number => 1, random_theme => 1, shuffle => 1); # -> [200, "OK", ["sxga"], {}]

=item * List all installed themes (equivalent to: "meta --themes"):

 metasyn(action => "list-themes");

Result:

 [
   200,
   "OK",
   [
     "abba",
     "afke",
     "alice",
     "alphabet",
 # ...snipped 136 lines for brevity...
     "viclones",
     "wales_towns",
     "weekdays",
     "yapc",
     "zodiac",
   ],
   {},
 ]

=item * List 3 random themes (equivalent to: "meta --themes E<verbar> shuf E<verbar> head -n3"):

 metasyn(action => "list-themes", number => 3, shuffle => 1);

Result:

 [200, "OK", ["foo", "christmas", "simpsons"], {}]

=item * List all installed themes, along with all their categories:

 metasyn(action => "list-themes", categories => 1);

Result:

 [
   200,
   "OK",
   [
     "abba",
     "afke",
     "alice",
     "alphabet/en",
 # ...snipped 2221 lines for brevity...
     "zodiac/Chinese",
     "zodiac/Vedic",
     "zodiac/Western",
     "zodiac/Western/Real",
     "zodiac/Western/Traditional",
   ],
   {},
 ]

=item * List all categories from a theme:

 metasyn(theme => "christmas", categories => 1);

Result:

 [200, "OK", ["elf", "reindeer", "santa", "snowman"], {}]

=item * List 2 categories from a theme, in random order:

 metasyn(theme => "christmas", categories => 1, number => 2, shuffle => 1);

Result:

 [200, "OK", ["reindeer", "snowman"], {}]

=back

This script is an alternative front-end for L<Acme::MetaSyntactic>. Compared
to the official CLI L<meta>, this CLI currently does not retrieve
themes/names remotely but:

=over

=item * provides shell completion (but see L<App::ShellCompleter::meta> to add tab
completion for the official CLI);

=item * provides an option to shuffle list of themes/categories/names returned;

=item * makes it easy to print all names in a theme;

=item * makes it easy to print all (or some) categories in a theme.

=back

This CLI is more geared towards listing all themes/names/categories instead of
picking random ones.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<action> => I<str> (default: "list-names")

=item * B<categories> => I<true>

=item * B<number> => I<posint>

Limit only return this number of results.

=item * B<random_theme> => I<true>

=item * B<shuffle> => I<true>

=item * B<theme> => I<str>


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

Please visit the project's homepage at L<https://metacpan.org/release/App-metasyn>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-metasyn>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-metasyn>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2019, 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
