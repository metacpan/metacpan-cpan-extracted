package Complete::Zsh;

our $DATE = '2016-10-22'; # DATE
our $VERSION = '0.03'; # VERSION

use 5.010001;
use strict;
use warnings;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(
                       parse_cmdline
                       format_completion
               );

require Complete::Bash;

our %SPEC;

$SPEC{':package'} = {
    v => 1.1,
    summary => 'Completion module for zsh shell',
};

$SPEC{format_completion} = {
    v => 1.1,
    summary => 'Format completion for output (for shell)',
    description => <<'_',

zsh accepts completion reply in the form of one entry per line to STDOUT.
Currently the formatting is done using `Complete::Bash`'s `format_completion`.

_
    args_as => 'array',
    args => {
        completion => {
            summary => 'Completion answer structure',
            description => <<'_',

Either an array or hash, as described in `Complete`.

_
            schema=>['any*' => of => ['hash*', 'array*']],
            req=>1,
            pos=>0,
        },
    },
    result => {
        summary => 'Formatted string (or array, if `as` key is set to `array`)',
        schema => ['any*' => of => ['str*', 'array*']],
    },
    result_naked => 1,
};
sub format_completion {
    Complete::Bash::format_completion(@_);
}

1;
# ABSTRACT: Completion module for zsh shell

__END__

=pod

=encoding UTF-8

=head1 NAME

Complete::Zsh - Completion module for zsh shell

=head1 VERSION

This document describes version 0.03 of Complete::Zsh (from Perl distribution Complete-Zsh), released on 2016-10-22.

=head1 DESCRIPTION

This module provides routines related to doing completion in zsh.

=head1 FUNCTIONS


=head2 format_completion($completion) -> str|array

Format completion for output (for shell).

zsh accepts completion reply in the form of one entry per line to STDOUT.
Currently the formatting is done using C<Complete::Bash>'s C<format_completion>.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<$completion>* => I<hash|array>

Completion answer structure.

Either an array or hash, as described in C<Complete>.

=back

Return value: Formatted string (or array, if `as` key is set to `array`) (str|array)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Complete-Zsh>.

=head1 SOURCE

Source repository is at L<https://github.com/sharyanto/perl-Complete-Zsh>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Complete-Zsh>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Complete>

L<Complete::Bash>, L<Complete::Fish>, L<Complete::Tcsh>.

zshcompctl manual page.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
