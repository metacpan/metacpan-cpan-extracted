package Data::Unixish::chain;

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

$SPEC{chain} = {
    v => 1.1,
    summary => 'Chain several dux functions together',
    description => <<'_',

Currently works for itemfunc only.

See also the <pm:Data::Unixish::Apply> function, which is related.

_
    args => {
        %common_args,
        functions => {
            summary => 'The functions to chain',
            schema  => ['array*' => of => ['any*', of => [
                'str*',
                ['array*', min_len=>1, elems=>['str*','hash*']],
            ]]],
            description => <<'_',

Each element must either be function name (like `date`) or a 2-element array
containing the function name and its arguments (like `[bool, {style: dot}]`).

_
            req     => 1,
            pos     => 0,
            greedy  => 1,
            cmdline_aliases => {f => {}},
        },
    },
    tags => [qw/itemfunc func/],
};
sub chain {
    my %args = @_;
    my ($in, $out) = ($args{in}, $args{out});

    _chain_begin(\%args);
    local ($., $_);
    while (($., $_) = each @$in) {
        push @$out, _chain_item($_, \%args);
    }

    [200, "OK"];
}

sub _chain_begin {
    no strict 'refs'; ## no critic: TestingAndDebugging::ProhibitNoStrict

    my $args = shift;
    my $ff = [];
    for my $f (@{ $args->{functions} }) {
        my ($fn, $args);
        if (ref($f) eq 'ARRAY') {
            $fn = $f->[0];;
            $args = $f->[1];
        } else {
            $fn = $f;
            $args = {};
        }
        unless ($fn =~
                    /\A[A-Za-z_][A-Za-z0-9_]*(::[A-Za-z_][A-Za-z0-9_]*)*\z/) {
            die "Invalid function name $fn, please use letter+alphanums only";
        }
        my $mod = "Data::Unixish::$fn";
        unless (eval "require $mod") { ## no critic: BuiltinFunctions::ProhibitStringyEval
            die "Can't load dux function $fn: $@";
        }
        my $fnleaf = $fn; $fnleaf =~ s/.+:://;
        if (defined &{"$mod\::_${fnleaf}_begin"}) {
            my $begin = \&{"$mod\::_${fnleaf}_begin"};
            $begin->($args);
        }
        push @$ff, [$mod, $fn, $fnleaf, \&{"$mod\::_${fnleaf}_item"}, $args];
    }
    # abuse to store state
    $args->{-functions} = $ff;
}

sub _chain_item {
    my ($item, $args) = @_;
    local $_ = $item;
    for my $f (@{ $args->{-functions} }) {
        $item = $f->[3]->($item, $f->[4]);
    }
    $item;
}

sub _chain_end {
    no strict 'refs'; ## no critic: TestingAndDebugging::ProhibitNoStrict

    my $args = shift;
    for my $f (@{ $args->{-functions} }) {
        my $mod    = $f->[0];
        my $fnleaf = $f->[2];
        my $args   = $f->[4];
        if (defined &{"$mod\::_${fnleaf}_end"}) {
            my $end = \&{"$mod\::_${fnleaf}_end"};
            $end->($args);
        }
    }
}

1;
# ABSTRACT: Chain several dux functions together

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Unixish::chain - Chain several dux functions together

=head1 VERSION

This document describes version 1.573 of Data::Unixish::chain (from Perl distribution Data-Unixish), released on 2023-09-23.

=head1 SYNOPSIS

In Perl:

 use Data::Unixish qw(lduxl);
 my @res = lduxl([chain => {functions => ['date', ["ANSI::color" => {color=>"yellow"}]]}], 1000, 2000);

In command-line:

 % echo -e "1000\n2000" | dux chain --functions-json '["date", ["ANSI::color",{"color":"yellow"}]]'
 2
 3
 4

=head1 FUNCTIONS


=head2 chain

Usage:

 chain(%args) -> [$status_code, $reason, $payload, \%result_meta]

Chain several dux functions together.

Currently works for itemfunc only.

See also the L<Data::Unixish::Apply> function, which is related.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<functions>* => I<array[str|array]>

The functions to chain.

Each element must either be function name (like C<date>) or a 2-element array
containing the function name and its arguments (like C<[bool, {style: dot}]>).

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
