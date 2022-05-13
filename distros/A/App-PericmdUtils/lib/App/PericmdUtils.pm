package App::PericmdUtils;

use 5.010001;
use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-05-02'; # DATE
our $DIST = 'App-PericmdUtils'; # DIST
our $VERSION = '0.051'; # VERSION

our %SPEC;

$SPEC{list_pericmd_plugins} = {
    v => 1.1,
    summary => "List Perinci::CmdLine plugins",
    description => <<'_',

This utility lists Perl modules in the `Perinci::CmdLine::Plugin::*` namespace.

_
    args => {
        # XXX use common library
        detail => {
            schema => 'bool*',
            cmdline_aliases => {l=>{}},
        },
    },
};
sub list_pericmd_plugins {
    require Module::List::Tiny;
    my %args = @_;

    my $mods = Module::List::Tiny::list_modules(
        "Perinci::CmdLine::Plugin::",
        {list_modules => 1, recurse=>1},
    );

    my @rows;
    for my $mod (sort keys %$mods) {
        my $name = $mod; $name =~ s/^Perinci::CmdLine::Plugin:://;
        my $row = {name => $name};
        if ($args{detail}) {
            require Module::Abstract;
            $row->{abstract} = Module::Abstract::module_abstract($mod);
        }
        push @rows, $row;
    }

    my %resmeta;
    if ($args{detail}) {
        $resmeta{'table.fields'} = ['name', 'abstract'];
    } else {
        @rows = map { $_->{name} } @rows;
    }

    [200, "OK", \@rows, \%resmeta];
}

1;
# ABSTRACT: Some utilities related to Perinci::CmdLine

__END__

=pod

=encoding UTF-8

=head1 NAME

App::PericmdUtils - Some utilities related to Perinci::CmdLine

=head1 VERSION

This document describes version 0.051 of App::PericmdUtils (from Perl distribution App-PericmdUtils), released on 2022-05-02.

=head1 DESCRIPTION

This distribution includes a few utility scripts related to Perinci::CmdLine
modules family.

=over

=item * L<detect-pericmd-script>

=item * L<dump-pericmd-script>

=item * L<gen-pod-for-pericmd-script>

=item * L<list-pericmd-plugins>

=back

=head1 FUNCTIONS


=head2 list_pericmd_plugins

Usage:

 list_pericmd_plugins(%args) -> [$status_code, $reason, $payload, \%result_meta]

List Perinci::CmdLine plugins.

This utility lists Perl modules in the C<Perinci::CmdLine::Plugin::*> namespace.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<detail> => I<bool>


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

Please visit the project's homepage at L<https://metacpan.org/release/App-PericmdUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-PericmdUtils>.

=head1 SEE ALSO

L<Perinci>

L<App::PerinciUtils>

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
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla plugin and/or Pod::Weaver::Plugin. Any additional steps required
beyond that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022, 2021, 2017, 2016, 2015 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-PericmdUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
