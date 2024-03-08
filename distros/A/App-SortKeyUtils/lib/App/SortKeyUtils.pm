package App::SortKeyUtils;

use 5.010001;
use strict 'subs', 'vars';
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-01-24'; # DATE
our $DIST = 'App-SortKeyUtils'; # DIST
our $VERSION = '0.001'; # VERSION

our %SPEC;

$SPEC{list_sortkey_modules} = {
    v => 1.1,
    args => {
        detail => {
            schema => 'bool*',
            cmdline_aliases => {l=>{}},
        },
    },
};
sub list_sortkey_modules {
    require Module::List::Tiny;

    my %args = @_;

    my $mods = Module::List::Tiny::list_modules(
        "SortKey::", {list_modules=>1, recurse=>1});
    my @rows;
    for my $mod (sort keys %$mods) {
        (my $name = $mod) =~ s/^SortKey:://;
        if ($args{detail}) {
            (my $mod_pm = "$mod.pm") =~ s!::!/!g;
            require $mod_pm;
            my $meta = {};
            eval {
                $meta = &{"$mod\::meta"};
            };
            push @rows, {
                name => $name,
                summary => $meta->{summary},
            };
        } else {
            push @rows, $name;
        }
    }
    [200, "OK", \@rows];
}

1;
# ABSTRACT: CLIs related to SortKey

__END__

=pod

=encoding UTF-8

=head1 NAME

App::SortKeyUtils - CLIs related to SortKey

=head1 VERSION

This document describes version 0.001 of App::SortKeyUtils (from Perl distribution App-SortKeyUtils), released on 2024-01-24.

=head1 SYNOPSIS

=head1 DESCRIPTION

This distribution contains the following CLIs related to L<SortKey>:

=over

=item * L<list-sortkey-modules>

=back

=head1 FUNCTIONS


=head2 list_sortkey_modules

Usage:

 list_sortkey_modules(%args) -> [$status_code, $reason, $payload, \%result_meta]

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<detail> => I<bool>

(No description)


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

Please visit the project's homepage at L<https://metacpan.org/release/App-SortKeyUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-SortKeyUtils>.

=head1 SEE ALSO

L<SortKey>

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

This software is copyright (c) 2024 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-SortKeyUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
