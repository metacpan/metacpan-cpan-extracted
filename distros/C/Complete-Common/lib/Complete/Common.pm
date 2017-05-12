package Complete::Common;

our $DATE = '2016-01-07'; # DATE
our $VERSION = '0.22'; # VERSION

use 5.010001;
use strict;
use warnings;

use Exporter qw(import);
our @EXPORT_OK = qw(
                       %arg_word
               );

our %EXPORT_TAGS = (
    all => \@EXPORT_OK
);

our %arg_word = (
    word => {
        summary => 'Word to complete',
        schema => ['str', default=>''],
        pos=>0,
        req=>1,
    },
);

our $OPT_CI          = ($ENV{COMPLETE_OPT_CI}          // 1) ? 1:0;
our $OPT_WORD_MODE   = ($ENV{COMPLETE_OPT_WORD_MODE}   // 1) ? 1:0;
our $OPT_CHAR_MODE   = ($ENV{COMPLETE_OPT_CHAR_MODE}   // 1) ? 1:0;
our $OPT_FUZZY       = ($ENV{COMPLETE_OPT_FUZZY}       // 1)+0;
our $OPT_MAP_CASE    = ($ENV{COMPLETE_OPT_MAP_CASE}    // 1) ? 1:0;
our $OPT_EXP_IM_PATH = ($ENV{COMPLETE_OPT_EXP_IM_PATH} // 1) ? 1:0;
our $OPT_DIG_LEAF    = ($ENV{COMPLETE_OPT_DIG_LEAF}    // 1) ? 1:0;

1;
# ABSTRACT: Common stuffs for completion routines

__END__

=pod

=encoding UTF-8

=head1 NAME

Complete::Common - Common stuffs for completion routines

=head1 VERSION

This document describes version 0.22 of Complete::Common (from Perl distribution Complete-Common), released on 2016-01-07.

=head1 DESCRIPTION

This module defines some common arguments and settings. C<Complete::*> modules
should use the default from these settings, to make it convenient for users to
change some behaviors globally.

The defaults are optimized for convenience and laziness for user typing and
might change from release to release.

=head2 C<$Complete::Common::OPT_CI> => bool (default: from COMPLETE_OPT_CI or 1)

If set to 1, matching is done case-insensitively.

In bash/readline, this is akin to setting C<completion-ignore-case>.

=head2 C<$Complete::Common::OPT_WORD_MODE> => bool (default: from COMPLETE_OPT_WORD_MODE or 1)

If set to 1, enable word-mode matching.

Word mode matching is normally only done when exact matching fails to return any
candidate. To give you an idea of how word-mode matching works, you can run
Emacs and try its completion of filenames (C<C-x C-f>) or function names
(C<M-x>). Basically, each string is split into words and matching is tried for
all available word even non-adjacent ones. For example, if you have C<dua-d> and
the choices are (C<dua-tiga>, C<dua-empat>, C<dua-lima-delapan>) then
C<dua-lima-delapan> will match because C<d> matches C<delapan> even though the
word is not adjacent. This is convenient when you have strings that are several
or many words long: you can just type the starting letters of some of the words
instead of just the starting letters of the whole string (which might need to be
quite long before producing a unique match).

=head2 C<$Complete::Common::OPT_CHAR_MODE> => bool (default: from COMPLETE_OPT_CHAR_MODE or 1)

If set to 1, enable character-mode matching.

This mode is like word-mode matching, except it works on a
character-by-character basis. Basically, it will match if a word contains any
letters of the string in the correct order. For example, C<ap> will match C<ap>,
C<amp>, C<slap>, or C<cramp> (but will not match C<pa> or C<pram>).

Character-mode matching is normally only done when exact matching and word-mode
fail to return any candidate.

=head2 C<$Complete::Common::OPT_FUZZY> => int (default: from COMPLETE_OPT_FUZZY or 1)

Enable fuzzy matching (matching even though there are some spelling mistakes).
The greater the number, the greater the tolerance. To disable fuzzy matching,
set to 0.

Fuzzy matching is normally only done when exact matching, word-mode, and
char-mode matching fail to return any candidate.

=head2 C<$Complete::Common::OPT_MAP_CASE> => bool (default: from COMPLETE_OPT_MAP_CASE or 1)

This is exactly like C<completion-map-case> in readline/bash to treat C<_> and
C<-> as the same when matching.

All L<Complete::Path>-based modules (like L<Complete::File>,
L<Complete::Module>, or L<Complete::Riap>) respect this setting.

=head2 C<$Complete::Common::OPT_EXP_IM_PATH> => bool (default: from COMPLETE_OPT_EXP_IM_PATH or 1)

Whether to "expand intermediate paths". What is meant by this is something like
zsh: when you type something like C<cd /h/u/b/myscript> it can be completed to
C<cd /home/ujang/bin/myscript>.

All L<Complete::Path>-based modules (like L<Complete::File>,
L<Complete::Module>, or L<Complete::Riap>) respect this setting.

=head2 C<$Complete::Common::OPT_DIG_LEAF> => bool (default: from COMPLETE_OPT_DIG_LEAF or 1)

(Experimental) When enabled, this option mimics what's seen on GitHub. If a
directory entry only contains a single subentry, it will directly show the
subentry (and subsubentry and so on) to save a number of tab presses.

Suppose you have files like this:

 a
 b/c/d/e
 c

If you complete for C<b> you will directly get C<b/c/d/e> (the leaf).

This is currently experimental because if you want to complete only directories,
you won't get b or b/c or b/c/d. Need to think how to solve this.

=head1 ENVIRONMENT

=head2 COMPLETE_OPT_CI => bool

Set default for C<$Complete::Common::OPT_CI>.

=head2 COMPLETE_OPT_FUZZY => int

Set default for C<$Complete::Common::OPT_FUZZY>.

=head2 COMPLETE_OPT_WORD_MODE => bool

Set default for C<$Complete::Common::OPT_WORD_MODE>.

=head2 COMPLETE_OPT_MAP_CASE => bool

Set default for C<$Complete::Common::OPT_MAP_CASE>.

=head2 COMPLETE_OPT_EXP_IM_PATH => bool

Set default for C<$Complete::Common::OPT_EXP_IM_PATH>.

=head2 COMPLETE_OPT_DIG_LEAF => bool

Set default for C<$Complete::Common::OPT_DIG_LEAF>.

=head1 SEE ALSO

L<Complete>

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Complete-Common>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Complete-Common>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Complete-Common>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
