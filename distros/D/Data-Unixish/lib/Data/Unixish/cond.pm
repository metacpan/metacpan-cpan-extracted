package Data::Unixish::cond;

use 5.010;
use locale;
use strict;
use syntax 'each_on_array'; # to support perl < 5.12
use warnings;
#use Log::Any '$log';

require Data::Unixish; # for siduxs
use Data::Unixish::Util qw(%common_args);

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2025-02-24'; # DATE
our $DIST = 'Data-Unixish'; # DIST
our $VERSION = '1.574'; # VERSION

our %SPEC;

$SPEC{cond} = {
    v => 1.1,
    summary => 'Apply dux function conditionally',
    description => <<'MARKDOWN',

This dux function takes a condition (a Perl code/expression) and one or two
other dux functions (A and B). Condition will be evaluated for each item (where
`$_` will be set to the current item). If condition evaluates to true, then A is
applied to the item, else B. All the dux functions must be itemfunc.

MARKDOWN
    args => {
        %common_args,
        if => {
            summary => 'Perl code that specifies the condition',
            schema  => ['any*' => of => ['str*', 'code*']],
            req     => 1,
            pos     => 0,
        },
        then => {
            summary => 'dux function to be applied if condition is true',
            schema  => ['any*' => of => ['str*', 'array*']], # XXX dux
            req     => 1,
            pos     => 1,
        },
        else => {
            summary => 'dux function to be applied if condition is false',
            schema  => ['any*' => of => ['str*', 'array*']], # XXX dux
            pos     => 2,
        },
    },
    tags => [qw/perl unsafe itemfunc/],
    "x.app.dux.is_stream_output" => 1,
};
sub cond {
    my %args = @_;
    my ($in, $out) = ($args{in}, $args{out});

    _cond_begin(\%args);
    local $.;
    my $item;
    while (($., $item) = each @$in) {
        push @$out, _cond_item->($item, \%args);
    }

    [200, "OK"];
}

sub _cond_begin {
    my $args = shift;

    if (ref($args->{if}) ne 'CODE') {
        if ($args->{-cmdline}) {
            $args->{if} = eval "no strict; no warnings; sub { $args->{if} }"; ## no critic: BuiltinFunctions::ProhibitStringyEval
            die "invalid Perl code for if: $@" if $@;
        } else {
            die "Please supply coderef for 'if'";
        }
    }
    $args->{then} //= 'cat';
    $args->{else} //= 'cat';
}

sub _cond_item {
    my ($item, $args) = @_;

    local $_ = $item;

    # XXX to be more efficient, skip siduxs and do it ourselves
    if ($args->{if}->()) {
        return Data::Unixish::siduxs($args->{then}, $item);
    } else {
        return Data::Unixish::siduxs($args->{else}, $item);
    }
}

1;
# ABSTRACT: Apply dux function conditionally

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Unixish::cond - Apply dux function conditionally

=head1 VERSION

This document describes version 1.574 of Data::Unixish::cond (from Perl distribution Data-Unixish), released on 2025-02-24.

=head1 SYNOPSIS

In Perl:

 use Data::Unixish qw(lduxl);
 my @res = lduxl([cond => {if => sub { $. % 2 }, then=>'uc', else=>'lc'}], "i", "love", "perl", "and", "c");
 # => ("i", "LOVE", "perl", "AND", "c")

In command-line:

 % echo -e "i\nlove\nperl\nand\nc" | dux cond --if '$. % 2' --then uc --else lc
 i
 LOVE
 perl
 AND
 c

=head1 FUNCTIONS


=head2 cond

Usage:

 cond(%args) -> [$status_code, $reason, $payload, \%result_meta]

Apply dux function conditionally.

This dux function takes a condition (a Perl code/expression) and one or two
other dux functions (A and B). Condition will be evaluated for each item (where
C<$_> will be set to the current item). If condition evaluates to true, then A is
applied to the item, else B. All the dux functions must be itemfunc.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<else> => I<str|array>

dux function to be applied if condition is false.

=item * B<if>* => I<str|code>

Perl code that specifies the condition.

=item * B<in> => I<array>

Input stream (e.g. array or filehandle).

=item * B<out> => I<any>

Output stream (e.g. array or filehandle).

=item * B<then>* => I<str|array>

dux function to be applied if condition is true.


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

This software is copyright (c) 2025 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Unixish>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
