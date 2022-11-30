package App::FontUtils;

use 5.010001;
use strict;
use warnings;
use Log::ger;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-08-30'; # DATE
our $DIST = 'App-FontUtils'; # DIST
our $VERSION = '0.002'; # VERSION

our %SPEC;

my %argspec0_ttf_file = (
    ttf_file => {
        schema => ['filename*'],
        'x.completion' => ['filename', {file_ext_filter=>['ttf','TTF']}],
        req => 1,
        pos => 0,
    },
);

my %argspec0_otf_file = (
    otf_file => {
        schema => ['filename*'],
        'x.completion' => ['filename', {file_ext_filter=>['otf','OTF']}],
        req => 1,
        pos => 0,
    },
);

my %argspec1opt_ttf_file = (
    ttf_file => {
        schema => ['filename*'],
        'x.completion' => ['filename', {file_ext_filter=>['ttf','TTF']}],
        pos => 1,
    },
);

my %argspec1opt_otf_file = (
    otf_file => {
        schema => ['filename*'],
        'x.completion' => ['filename', {file_ext_filter=>['otf','OTF']}],
        pos => 1,
    },
);

our %argspecopt_overwrite = (
    overwrite => {
        schema => 'bool*',
        cmdline_aliases => {O=>{}},
    },
);

$SPEC{ttf2otf} = {
    v => 1.1,
    summary => 'Convert TTF to OTF',
    description => <<'_',

This program is a shortcut wrapper for <prog:fontforge>. This command:

    % ttf2otf foo.ttf

is equivalent to:

    % fontforge -lang=ff -c 'Open($1); Generate($2); Close();' foo.ttf foo.otf

_
    args => {
        %argspec0_ttf_file,
        %argspec1opt_otf_file,
        %argspecopt_overwrite,
    },
    deps => {
        prog => 'fontforge',
    },
    links => [
        {url => 'prog:otf2ttf'},
    ],
};
sub ttf2otf {
    require IPC::System::Options;

    my %args = @_;

    my $ttf_file = $args{ttf_file};
    -f $ttf_file or return [500, "File '$ttf_file' does not exist or not a file"];

    my $otf_file = $args{otf_file};
    unless (defined $otf_file) {
        ($otf_file = $ttf_file) =~ s/\.ttf\z/.otf/i;
    }
    $otf_file eq $ttf_file and return [412, "Please specify a different name for the output OTF file"];
    ((-f $otf_file) && !$args{overwrite}) and return [412, "OTF file '$otf_file' already exists, please specify another output name or use --overwrite"];

    IPC::System::Options::system(
        {log=>1, die=>1},
        "fontforge", "-lang=ff", "-c", 'Open($1); Generate($2); Close();', $ttf_file, $otf_file,
    );
    [200];
}

$SPEC{otf2ttf} = {
    v => 1.1,
    summary => 'Convert OTF to TTF',
    description => <<'_',

This program is a shortcut wrapper for <prog:fontforge>. This command:

    % otf2ttf foo.otf

is equivalent to:

    % fontforge -lang=ff -c 'Open($1); Generate($2); Close();' foo.otf foo.ttf

_
    args => {
        %argspec0_otf_file,
        %argspec1opt_ttf_file,
        %argspecopt_overwrite,
    },
    deps => {
        prog => 'fontforge',
    },
    links => [
        {url => 'prog:ttf2otf'},
    ],
};
sub otf2ttf {
    require IPC::System::Options;

    my %args = @_;

    my $otf_file = $args{otf_file};
    -f $otf_file or return [500, "File '$otf_file' does not exist or not a file"];

    my $ttf_file = $args{ttf_file};
    unless (defined $ttf_file) {
        ($ttf_file = $otf_file) =~ s/\.otf\z/.ttf/i;
    }
    $ttf_file eq $otf_file and return [412, "Please specify a different name for the output TTF file"];
    ((-f $ttf_file) && !$args{overwrite}) and return [412, "TTF file '$ttf_file' already exists, please specify another output name or use --overwrite"];

    IPC::System::Options::system(
        {log=>1, die=>1},
        "fontforge", "-lang=ff", "-c", 'Open($1); Generate($2); Close();', $otf_file, $ttf_file,
    );
    [200];
}

1;
# ABSTRACT: Command-line utilities related to fonts and font files

__END__

=pod

=encoding UTF-8

=head1 NAME

App::FontUtils - Command-line utilities related to fonts and font files

=head1 VERSION

This document describes version 0.002 of App::FontUtils (from Perl distribution App-FontUtils), released on 2022-08-30.

=head1 SYNOPSIS

This distribution provides tha following command-line utilities related to fonts
and font files:

=over

=item * L<otf2ttf>

=item * L<ttf2otf>

=back

=head1 FUNCTIONS


=head2 otf2ttf

Usage:

 otf2ttf(%args) -> [$status_code, $reason, $payload, \%result_meta]

Convert OTF to TTF.

This program is a shortcut wrapper for L<fontforge>. This command:

 % otf2ttf foo.otf

is equivalent to:

 % fontforge -lang=ff -c 'Open($1); Generate($2); Close();' foo.otf foo.ttf

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<otf_file>* => I<filename>

=item * B<overwrite> => I<bool>

=item * B<ttf_file> => I<filename>


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 ttf2otf

Usage:

 ttf2otf(%args) -> [$status_code, $reason, $payload, \%result_meta]

Convert TTF to OTF.

This program is a shortcut wrapper for L<fontforge>. This command:

 % ttf2otf foo.ttf

is equivalent to:

 % fontforge -lang=ff -c 'Open($1); Generate($2); Close();' foo.ttf foo.otf

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<otf_file> => I<filename>

=item * B<overwrite> => I<bool>

=item * B<ttf_file>* => I<filename>


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)

=head1 TODO

C<list-fonts> to list installed fonts on the system (in a cross-platform way).
Tab completion. Filtering OTF/TTF, etc.

C<< show-fonts <font names> [text] >> to show how fonts look. Allow specifying
wildcards. Allow specifying filename for source of text. Tab completion.

C<< install-font <font files> >> and C<< uninstall-font <font names> >> to
install and uninstall fonts (in a cross-platform way). Allow specifying
regex/wildcard in uninstall. Tab completion.

C<<search-font>>

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-FontUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-FontUtils>.

=head1 SEE ALSO

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

This software is copyright (c) 2022 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-FontUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
