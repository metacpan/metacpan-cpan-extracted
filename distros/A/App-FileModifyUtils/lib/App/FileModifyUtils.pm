package App::FileModifyUtils;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-08-02'; # DATE
our $DIST = 'App-FileModifyUtils'; # DIST
our $VERSION = '0.002'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

use Exporter 'import';
our @EXPORT_OK = qw(add_line_to_file remove_line_from_file);

our %SPEC;

$SPEC{add_line_to_file} = {
    v => 1.1,
    summary => 'Add line to file',
    description => <<'_',

Uses <pm:Setup::File::Line> which supports undo, but the undo feature is not
used. See <pm:App::FileModifyUtils::Undoable> for file-modifying CLIs which
support undo.

_
    args => {
        file => {
            schema => 'filename*',
            req => 1,
            pos => 0,
        },
        line => {
            schema => 'str*',
            req => 1,
            pos => 1,
        },
        top_style => {
            schema => 'bool*',
            cmdline_aliases => {t=>{}},
        },
    },
    examples => [
        {
            summary => 'Add .DS_Store to .gitignore for several repositories',
            src => 'for repo in perl-*;do cd $repo; add-line-to-file .gitignore .DS_Store && git commit -m "Add .DS_Store to .gitignore" .gitignore; cd ..; done',
            src_plang => 'bash',
            test => 0,
            'x.doc.show_result' => 0,
        },
    ],
};
sub add_line_to_file {
    require Setup::File::Line;
    my %args = @_;
    Setup::File::Line::setup_file_line(
        -tx_action => 'fix_state',
        -tx_action_id => rand(),
        path => $args{file},
        line_content => $args{line},
        top_style => $args{top_style},
    );
}

$SPEC{remove_line_from_file} = {
    v => 1.1,
    summary => 'Remove all occurrences of a line from file',
    description => <<'_',

Uses <pm:Setup::File::Line> which supports undo, but the undo feature is not
used. See <pm:App::FileModifyUtils::Undoable> for file-modifying CLIs which
support undo.

_
    args => {
        file => {
            schema => 'filename*',
            req => 1,
            pos => 0,
        },
        line => {
            schema => 'str*',
            req => 1,
            pos => 1,
        },
        case_insensitive => {
            schema => 'bool*',
        },
    },
};
sub remove_line_from_file {
    require Setup::File::Line;
    my %args = @_;
    Setup::File::Line::setup_file_line(
        -tx_action => 'fix_state',
        -tx_action_id => rand(),
        should_exist => 0,
        path => $args{file},
        line_content => $args{line},
        case_insensitive => $args{case_insensitive},
    );
}

1;
# ABSTRACT: Utilities related to modifying files

__END__

=pod

=encoding UTF-8

=head1 NAME

App::FileModifyUtils - Utilities related to modifying files

=head1 VERSION

This document describes version 0.002 of App::FileModifyUtils (from Perl distribution App-FileModifyUtils), released on 2021-08-02.

=head1 DESCRIPTION

This distribution provides the following command-line utilities:

=over

=item * L<add-line-to-file>

=item * L<remove-line-from-file>

=back

=head1 FUNCTIONS


=head2 add_line_to_file

Usage:

 add_line_to_file(%args) -> [$status_code, $reason, $payload, \%result_meta]

Add line to file.

Uses L<Setup::File::Line> which supports undo, but the undo feature is not
used. See L<App::FileModifyUtils::Undoable> for file-modifying CLIs which
support undo.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<file>* => I<filename>

=item * B<line>* => I<str>

=item * B<top_style> => I<bool>


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 remove_line_from_file

Usage:

 remove_line_from_file(%args) -> [$status_code, $reason, $payload, \%result_meta]

Remove all occurrences of a line from file.

Uses L<Setup::File::Line> which supports undo, but the undo feature is not
used. See L<App::FileModifyUtils::Undoable> for file-modifying CLIs which
support undo.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<case_insensitive> => I<bool>

=item * B<file>* => I<filename>

=item * B<line>* => I<str>


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

Please visit the project's homepage at L<https://metacpan.org/release/App-FileModifyUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-FileModifyUtils>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-FileModifyUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

Other similar distributions: L<App::FileRenameUtils>,
L<App::FileRemoveUtilities>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
