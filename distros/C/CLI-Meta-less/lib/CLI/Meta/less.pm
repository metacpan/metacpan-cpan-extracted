package CLI::Meta::less;

use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-09-27'; # DATE
our $DIST = 'CLI-Meta-less'; # DIST
our $VERSION = '0.002'; # VERSION

our $META = {
    opts => {
        'search-skip-screen|a' => undef,
        'SEARCH-SKIP-SCREEN|A' => undef,
        'buffers|b=i' => {completion=>sub { require Complete::Number; my %args = @_; Complete::Number::complete_int(word=>$args{word}, min=>1) } },
        'auto-buffers|B' => undef,
        'clear-screen|c' => undef,
        'CLEAR-SCREEN|C' => undef,
        'd|dumb' => undef,
        'color|D=s' => {
            completion=>sub {
                require Complete::Sequence;
                my %args = @_;
                Complete::Sequence::complete_sequence(
                    sequence => [
                        [qw/n s d u k/],
                        [0..15],
                        ['.'],
                        [0..15],
                    ],
                    word => $args{word},
                );
            },
        },
        'quit-at-eof|e' => undef,
        'QUIT-AT-EOF|E' => undef,
        'force|f' => undef,
        'quit-if-one-screen|F' => undef,
        'hilite-search|g' => undef,
        'HILITE-SEARCH|G' => undef,
        'max-back-scroll|h=i' => {completion=>sub { require Complete::Number; my %args = @_; Complete::Number::complete_int(word=>$args{word}, min=>0) } },
        'ignore-case|i' => undef,
        'IGNORE-CASE|I' => undef,
        'jump-target|j=i' => {completion=>sub { require Complete::Number; my %args = @_; Complete::Number::complete_int(word=>$args{word}) } },
        'status-column|j' => undef,
        'lesskey-file|k=s' => {
            completion=>sub {
                require Complete::File;
                my %args = @_;
                Complete::File::complete_file(word=>$args{word}, filter=>'f');
            },
        },
        'quit-on-intr|K' => undef,
        'no-lessopen|L' => undef,
        'long-prompt|m' => undef,
        'LONG-PROMPT|M' => undef,
        'line-numbers|n' => undef,
        'log-file|o=s' => {
            completion=>sub {
                require Complete::File;
                my %args = @_;
                Complete::File::complete_file(word=>$args{word}, filter=>'f');
            },
        },
        'LOG-FILE|O=s' => {
            completion=>sub {
                require Complete::File;
                my %args = @_;
                Complete::File::complete_file(word=>$args{word}, filter=>'f');
            },
        },
        'pattern|p=s' => undef,
        'prompt|P=s' => undef,
        'quiet|silent|q' => undef,
        'QUIET|SILENT|Q' => undef,
        'raw-control-chars|r' => undef,
        'RAW-CONTROL-CHARS|R' => undef,
        'squeeze-blank-lines|s' => undef,
        'chop-blank-lines|S' => undef,
        'tag|t=s' => undef,
        'tag-file|T=s' => {
            completion=>sub {
                require Complete::File;
                my %args = @_;
                Complete::File::complete_file(word=>$args{word}, filter=>'f');
            },
        },
        'underline-special|u' => undef,
        'UNDERLINE-SPECIAL|U' => undef,
        'hilite-unread|w' => undef,
        'HILITE-UNREAD|W' => undef,
        'tabs|x=i' => {completion=>sub { require Complete::Number; my %args = @_; Complete::Number::complete_int(word=>$args{word}, min=>0) } },
        'no-init|X' => undef,
        'max-forw-scroll|y=i' => {completion=>sub { require Complete::Number; my %args = @_; Complete::Number::complete_int(word=>$args{word}, min=>0) } },
        'window|z=s' => undef,

        #'quotes|"=s' => undef, # problematic with Getopt::Long option?
        'quotes=s' => undef,
        #'tilde|~=s' => undef, # problematic with Getopt::Long option?
        'tilde=s' => undef,
        #'shift|#=s' => undef, # problematic with Getopt::Long option?
        'tilde=s' => undef,
        'follow-name' => undef,
        'no-keypad' => undef,
        'no-bakslash' => undef,

        'help|?' => undef,
        'V|version' => undef,
    },
};

1;
# ABSTRACT: Metadata for 'cp' Unix commnd

__END__

=pod

=encoding UTF-8

=head1 NAME

CLI::Meta::less - Metadata for 'cp' Unix commnd

=head1 VERSION

This document describes version 0.002 of CLI::Meta::less (from Perl distribution CLI-Meta-less), released on 2024-09-27.

=head1 SYNOPSIS

=head1 DESCRIPTION

Based on cp from GNU coreutils 8.30.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/CLI-Meta-less>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-CLI-Meta-less>.

=head1 SEE ALSO

L<CLI::Meta::mv>

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

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=CLI-Meta-less>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
