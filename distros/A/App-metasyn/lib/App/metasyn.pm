package App::metasyn;

our $DATE = '2017-02-27'; # DATE
our $VERSION = '0.004'; # VERSION

use 5.010001;
use strict;
use warnings;

our %SPEC;

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
                Complete::Acme::MetaSyntactic::complete_meta_themes_and_categories(@_);
            },
        },
        shuffle => {
            schema => ['bool*', is=>1],
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
            summary => 'List all names from a theme in random order',
            argv => [qw(christmas/elf --shuffle)],
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
                    push @res, "$th/$_" for @cats;
                } else {
                    push @res, $th;
                }
            } else {
                push @res, $th;
            }
        }
        return [200, "OK", \@res];
    }

    my $theme = $args{theme};
    return [400, "Please specify theme"] unless $theme;
    my $cat = $theme =~ s{/(.+)\z}{} ? $1 : undef;

    my $pkg = "Acme::MetaSyntactic::$theme";
    (my $pkg_pm = "$pkg.pm") =~ s!::!/!g;
    return [500, "Can't load $pkg: $@"] unless (eval { require $pkg_pm; 1 });

    if ($args{categories}) {
        my @res;
        eval { @res = $pkg->categories };
        #warn if $@;
        return [200, "OK", \@res];
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
    if ($args{shuffle}) {
        require List::Util;
        @names = List::Util::shuffle(@names);
    }
    return [200, "OK", \@names];
}

1;
# ABSTRACT: Alternative front-end to Acme::MetaSyntactic

__END__

=pod

=encoding UTF-8

=head1 NAME

App::metasyn - Alternative front-end to Acme::MetaSyntactic

=head1 VERSION

This document describes version 0.004 of App::metasyn (from Perl distribution App-metasyn), released on 2017-02-27.

=head1 SYNOPSIS

Use the included script L<metasyn>.

=head1 FUNCTIONS


=head2 metasyn

Usage:

 metasyn(%args) -> [status, msg, result, meta]

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
 # ...snipped 130 lines for brevity...
     "viclones",
     "wales_towns",
     "weekdays",
     "yapc",
     "zodiac",
   ],
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
     "alphabet/la",
 # ...snipped 2148 lines for brevity...
     "zodiac/Vedic",
     "zodiac/Western",
     "zodiac/Western/Traditional",
     "zodiac/Chinese",
     "zodiac/Western/Real",
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

=item * List all names from a theme in random order:

 metasyn( theme => "christmas/elf", shuffle => 1);

Result:

 [
   200,
   "OK",
   [
     "upatree",
     "opneslae",
     "sugarplum",
     "bushy",
 # ...snipped 3 lines for brevity...
     "shinny",
     "minstix",
     "wunorse",
     "mary",
     "pepper",
   ],
   {},
 ]

=item * List all categories from a theme:

 metasyn( theme => "christmas", categories => 1);

Result:

 [200, "OK", ["reindeer", "santa", "snowman", "elf"], {}]

=back

This script is an alternative front-end to L<Acme::MetaSyntactic>. Compared to
the official CLI L<meta>, this CLI is more oriented towards listing names
instead of giving you one or several random names.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<action> => I<str> (default: "list-names")

=item * B<categories> => I<bool>

=item * B<shuffle> => I<bool>

=item * B<theme> => I<str>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

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

=head1 SEE ALSO


L<meta>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
