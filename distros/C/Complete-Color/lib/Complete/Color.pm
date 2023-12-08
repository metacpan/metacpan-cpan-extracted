package Complete::Color;

use 5.010001;
use strict;
use warnings;
use Log::ger;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-12-01'; # DATE
our $DIST = 'Complete-Color'; # DIST
our $VERSION = '0.003'; # VERSION

use Complete::Common qw(:all);
use Exporter qw(import);

our @EXPORT_OK = qw(
                       complete_color_name
                       complete_color_rgb24_hexcode
               );

our %SPEC;

$SPEC{':package'} = {
    v => 1.1,
    summary => 'Completion routines related to colors',
};

$SPEC{'complete_color_name'} = {
    v => 1.1,
    summary => 'Complete from color names',
    description => <<'MARKDOWN',

Currently color names are taken from `Graphics::ColorNamesLite::*` modules.

MARKDOWN
    args => {
        %arg_word,
        lang => {
            schema => ['str*', match=>qr/\A[A-Z][A-Z]\z/],
        },
    },
    result_naked => 1,
    result => {
        schema => 'array',
    },
};
sub complete_color_name {
    my %args = @_;

    my $lang = $args{lang};

    my $mod;
    if ($lang) {
        return [400, "Invalid syntax for lang, must be two uppercase digits"] unless $lang =~ /\A[A-Z][A-Z]\z/;
        $mod = $lang;
    } else {
        $mod = "All";
    }
    $mod = "Graphics::ColorNamesLite::$mod";
    (my $mod_pm = "$mod.pm") =~ s!::!/!g;
    require $mod_pm;

    require Complete::Util;
    no strict 'refs'; ## no critic: TestingAndDebugging::ProhibitNoStrict
    my %summaries;
    for (keys %{${"$mod\::NAMES_RGB_TABLE"}}) { $summaries{$_} = "code #".${"$mod\::NAMES_RGB_TABLE"}->{$_}.", ".${"$mod\::NAMES_SUMMARIES_TABLE"}->{$_} }
    Complete::Util::complete_hash_key(hash => ${"$mod\::NAMES_RGB_TABLE"}, word=>$args{word}, summaries=>\%summaries);
}

$SPEC{'complete_color_rgb24_hexcode'} = {
    v => 1.1,
    summary => 'Complete from color names',
    description => <<'MARKDOWN',

Currently color names are taken from `Graphics::ColorNamesLite::*` modules.

MARKDOWN
    args => {
        %arg_word,
        lang => {
            schema => ['str*', match=>qr/\A[A-Z][A-Z]\z/],
        },
        case => {
            schema => ['str*', in=>['upper','lower']],
            default => 'lower',
        },
    },
    result_naked => 1,
    result => {
        schema => 'array',
    },
};
sub complete_color_rgb24_hexcode {
    my %args = @_;

    my $lang = $args{lang};
    my $word = $args{word} // '';

    my $mod;
    if ($lang) {
        return [400, "Invalid syntax for lang, must be two uppercase digits"] unless $lang =~ /\A[A-Z][A-Z]\z/;
        $mod = $lang;
    } else {
        $mod = "All";
    }
    $mod = "Graphics::ColorNamesLite::$mod";
    (my $mod_pm = "$mod.pm") =~ s!::!/!g;
    require $mod_pm;

    $word = lc($word);
    $word =~ s/\s+//g;
    my $prefix = $word =~ s/\A(#?)// ? $1 : ''; # strip prefix first

    require Complete::Util;
    no strict 'refs'; ## no critic: TestingAndDebugging::ProhibitNoStrict
    my $res = Complete::Util::complete_hash_value(hash => ${"$mod\::NAMES_RGB_TABLE"}, word=>$word, summaries_from_hash_keys=>1);
    if (length $prefix) { for (@$res) { $_->{word} = "$prefix$_->{word}" } } # re-add prefix from inputted word
    $res;
}

1;
# ABSTRACT: Completion routines related to colors

__END__

=pod

=encoding UTF-8

=head1 NAME

Complete::Color - Completion routines related to colors

=head1 VERSION

This document describes version 0.003 of Complete::Color (from Perl distribution Complete-Color), released on 2023-12-01.

=for Pod::Coverage .+

=head1 FUNCTIONS


=head2 complete_color_name

Usage:

 complete_color_name(%args) -> array

Complete from color names.

Currently color names are taken from C<Graphics::ColorNamesLite::*> modules.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<lang> => I<str>

(No description)

=item * B<word>* => I<str> (default: "")

Word to complete.


=back

Return value:  (array)



=head2 complete_color_rgb24_hexcode

Usage:

 complete_color_rgb24_hexcode(%args) -> array

Complete from color names.

Currently color names are taken from C<Graphics::ColorNamesLite::*> modules.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<case> => I<str> (default: "lower")

(No description)

=item * B<lang> => I<str>

(No description)

=item * B<word>* => I<str> (default: "")

Word to complete.


=back

Return value:  (array)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Complete-Color>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Complete-Color>.

=head1 SEE ALSO

L<Complete>

Other C<Complete::*> modules.

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

This software is copyright (c) 2023 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Complete-Color>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
