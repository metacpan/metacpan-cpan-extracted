package Data::Unixish::grep;

use 5.010;
use locale;
use strict;
use syntax 'each_on_array'; # to support perl < 5.12
use warnings;
#use Log::Any '$log';

use Data::Unixish::Util qw(%common_args);

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-09-23'; # DATE
our $DIST = 'Data-Unixish'; # DIST
our $VERSION = '1.573'; # VERSION

our %SPEC;

$SPEC{grep} = {
    v => 1.1,
    summary => 'Perl grep',
    description => <<'_',

Filter each item through a callback.

_
    args => {
        %common_args,
        callback => {
            summary => 'The callback code or regexp to use',
            schema  => ['any*' => of => ['str*', 're*', 'code*']],
            req     => 1,
            pos     => 0,
        },
    },
    tags => [qw/filtering perl unsafe/],
};
sub grep {
    my %args = @_;
    my ($in, $out) = ($args{in}, $args{out});
    my $callback = $args{callback} or die "missing callback for grep";
    if (ref($callback) eq ref(qr{})) {
        my $re = $callback;
        $callback = sub { $_ =~ $re };
    } elsif (ref($callback) ne 'CODE') {
        if ($args{-cmdline}) {
            $callback = eval "no strict; no warnings; sub { $callback }"; ## no critic: BuiltinFunctions::ProhibitStringyEval
            die "invalid code for grep: $@" if $@;
        } else {
            die "Please supply coderef (or regex) for 'callback'";
        }
    }

    local ($., $_);
    while (($., $_) = each @$in) {
        push @$out, $_ if $callback->();
    }

    [200, "OK"];
}

1;
# ABSTRACT: Perl grep

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Unixish::grep - Perl grep

=head1 VERSION

This document describes version 1.573 of Data::Unixish::grep (from Perl distribution Data-Unixish), released on 2023-09-23.

=head1 SYNOPSIS

In Perl:

 use Data::Unixish qw(lduxl);
 my @res = lduxl([grep => {callback => sub { $_ % 2 }}], 1, 2, 3, 4, 5);
 # => (1, 3, 5)

In command-line:

 % echo -e "1\n2\n3\n4\n5" | dux grep '$_ % 2'
 1
 3
 5

=head1 FUNCTIONS


=head2 grep

Usage:

 grep(%args) -> [$status_code, $reason, $payload, \%result_meta]

Perl grep.

Filter each item through a callback.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<callback>* => I<str|re|code>

The callback code or regexp to use.

=item * B<in> => I<array>

Input stream (e.g. array or filehandle).

=item * B<out> => I<any>

Output stream (e.g. array or filehandle).


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

Please visit the project's homepage at L<https://metacpan.org/release/Data-Unixish>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Data-Unixish>.

=head1 SEE ALSO

grep(1)

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

This software is copyright (c) 2023, 2019, 2017, 2016, 2015, 2014, 2013, 2012 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Unixish>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
