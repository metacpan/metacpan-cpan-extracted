package App::metasyn;

our $DATE = '2021-02-21'; # DATE
our $VERSION = '0.006'; # VERSION

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

This script is an alternative front-end to <pm:Acme::MetaSyntactic>. Compared to
the official CLI <prog:meta>, this CLI is more oriented towards listing names
instead of giving you one or several random names.

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
            schema => ['bool*', is=>1],
        },
        number => {
            summary => 'Limit only return this number of results',
            schema => 'posint*',
            cmdline_aliases => {n=>{}},
        },
        categories => {
            schema => ['bool*', is=>1],
            cmdline_aliases => {c=>{}},
        },
    },
    examples => [
        {
            summary => 'List all installed themes',
            argv => [qw/-l/],
            'x.doc.max_result_lines' => 10,
        },
        {
            summary => 'List 3 random themes',
            argv => [qw/-l -n3 --shuffle/],
        },
        {
            summary => 'List all installed themes, along with all their categories',
            argv => [qw/-l -c/],
            'x.doc.max_result_lines' => 10,
        },
        {
            summary => 'List all names from a theme',
            argv => [qw/foo/],
            'x.doc.max_result_lines' => 10,
        },
        {
            summary => 'List all names from a theme in random order, return only 3',
            argv => [qw(christmas/elf -n3 --shuffle)],
            'x.doc.max_result_lines' => 10,
        },
        {
            summary => 'List all categories from a theme',
            argv => [qw(christmas -c)],
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

    my $theme = $args{theme};
    return [400, "Please specify theme"] unless $theme;
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

This document describes version 0.006 of App::metasyn (from Perl distribution App-metasyn), released on 2021-02-21.

=head1 SYNOPSIS

Use the included script L<metasyn>.

=head1 FUNCTIONS


=head2 metasyn

Usage:

 metasyn(%args) -> [status, msg, payload, meta]

Alternative front-end to Acme::MetaSyntactic.

Examples:

=over

=item * List all installed themes:

 metasyn( action => "list-themes");

Result:

 [
   200,
   "OK",
   [
     "abba",
     "afke",
     "alice",
     "alphabet",
 # ...snipped 137 lines for brevity...
     "viclones",
     "wales_towns",
     "weekdays",
     "yapc",
     "zodiac",
   ],
   {},
 ]

=item * List 3 random themes:

 metasyn( action => "list-themes", number => 3, shuffle => 1);

Result:

 [
   200,
   "OK",
   ["display_resolution", "loremipsum", "jabberwocky"],
   {},
 ]

=item * List all installed themes, along with all their categories:

 metasyn( action => "list-themes", categories => 1);

Result:

 [
   200,
   "OK",
   [
     "abba",
     "afke",
     "alice",
     "alphabet/en",
 # ...snipped 2209 lines for brevity...
     "zodiac/Chinese",
     "zodiac/Vedic",
     "zodiac/Western",
     "zodiac/Western/Real",
     "zodiac/Western/Traditional",
   ],
   {},
 ]

=item * List all names from a theme:

 metasyn( theme => "foo");

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

=item * List all names from a theme in random order, return only 3:

 metasyn( theme => "christmas/elf", number => 3, shuffle => 1);

Result:

 [200, "OK", ["opneslae", "minstix", "snowball"], {}]

=item * List all categories from a theme:

 metasyn( theme => "christmas", categories => 1);

Result:

 [200, "OK", ["elf", "reindeer", "santa", "snowman"], {}]

=back

This script is an alternative front-end to L<Acme::MetaSyntactic>. Compared to
the official CLI L<meta>, this CLI is more oriented towards listing names
instead of giving you one or several random names.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<action> => I<str> (default: "list-names")

=item * B<categories> => I<bool>

=item * B<number> => I<posint>

Limit only return this number of results.

=item * B<shuffle> => I<bool>

=item * B<theme> => I<str>


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

Please visit the project's homepage at L<https://metacpan.org/release/App-metasyn>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-metasyn>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://github.com/perlancar/perl-App-metasyn/issues>

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
