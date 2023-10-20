package App::TrashUtils;

use 5.010001;
use strict;
use warnings;
use Log::ger;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-08-06'; # DATE
our $DIST = 'App-TrashUtils'; # DIST
our $VERSION = '0.003'; # VERSION

our %SPEC;

sub _complete_trashed_filenames {
    require Complete::Util;
    require File::Trash::FreeDesktop;

    my %args = @_;
    my $word = $args{word} // '';

    my $trash = File::Trash::FreeDesktop->new;
    my @ct = $trash->list_contents;

    if ($word =~ m!/!) {
        # if word contains '/', then we complete with trashed files' paths
        Complete::Util::complete_array_elem(array=>[map { $_->{path} } @ct], word=>$word);
    } else {
        # otherwise we complete with trashed files' filenames
        Complete::Util::complete_array_elem(array=>[map { my $filename = $_->{path}; $filename =~ s!.+/!!; $filename } @ct], word=>$word);
    }
}

$SPEC{trash_list} = {
    v => 1.1,
    summary => 'List contents of trash directories',
    args => {
        detail => {
            schema => 'bool*',
            cmdline_aliases => {l=>{}},
        },
        wildcard => {
            summary => 'Filter path or filename with wildcard pattern',
            description => <<'_',

Will be matched against path if pattern contains `/`, otherwise will be matched
against filename. Supported patterns are jokers (`*` and `?`), character class
(e.g. `[123]`), and globstar (`**`).

When specifying the wildcard on the CLI, remember to quote it to protect from
being interpreted by the shell, e.g. to match files in the current directory.

_
            schema => 'str*',
            pos => 0,
            completion => \&_complete_trashed_filenames,
        },
    },
    examples => [
        {
            summary => 'List all files in trash cans',
            argv => [],
            test => 0,
            'x.doc.show_result' => 0,
        },
        {
            summary => 'List files ending in ".pm" in trash cans, show details',
            argv => ['-l', '*.pm'],
            test => 0,
            'x.doc.show_result' => 0,
        },
        {
            summary => 'List all files under the path "/home/ujang/Documents" in trash cans',
            argv => ['/home/ujang/Documents/**'],
            test => 0,
            'x.doc.show_result' => 0,
        },
    ],
};
sub trash_list {
    require File::Trash::FreeDesktop;

    my %args = @_;

    my %opts;
    if (defined $args{wildcard}) {
        if ($args{wildcard} =~ m!/!) {
            $opts{path_wildcard} = $args{wildcard};
        } else {
            $opts{filename_wildcard} = $args{wildcard};
        }
    }

    my @contents = File::Trash::FreeDesktop->new->list_contents(\%opts);
    if ($args{detail}) {
        [200, "OK", \@contents, {
            'table.fields' => [qw/path deletion_date/],
            'table.field_formats' => [undef, 'iso8601_datetime'],
        }];
    } else {
        [200, "OK", [map {$_->{path}} @contents]];
    }
}

$SPEC{trash_list_trashes} = {
    v => 1.1,
    summary => 'List trash directories',
    args => {
    },
};
sub trash_list_trashes {
    require File::Trash::FreeDesktop;

    my %args = @_;

    my @trashes = File::Trash::FreeDesktop->new->list_trashes;
    [200, "OK", \@trashes];
}

$SPEC{trash_put} = {
    v => 1.1,
    summary => 'Put files into trash',
    args => {
        files => {
            'x.name.is_plural' => 1,
            'x.name.singular' => 'file',
            schema => ['array*', of=>'pathname*'],
            req => 1,
            pos => 0,
            slurpy => 1,
        },
    },
    features => {
        dry_run => 1,
    },
    examples => [
        {
            summary => 'Trash two files',
            argv => ['file1', 'file2.txt'],
            test => 0,
            'x.doc.show_result' => 0,
        },
    ],
};
sub trash_put {
    require File::Trash::FreeDesktop;
    require Perinci::Object::EnvResultMulti;

    my %args = @_;

    my $trash = File::Trash::FreeDesktop->new;
    my $res = Perinci::Object::EnvResultMulti->new;
    for my $file (@{ $args{files} }) {
        my @st = lstat $file;
        if (!(-e _)) {
            $res->add_result(404, "File not found: $file", {item_id=>$file});
            next;
        }
        if ($args{-dry_run}) {
        log_info "[DRY_RUN] Trashing %s ...", $file;
            $res->add_result(200, "Trashed (DRY_RUN)", {item_id=>$file});
            next;
        }
        log_info "Trashing %s ...", $file;
        eval { $trash->trash($file) };
        if ($@) {
            $res->add_result(500, "Can't trash: $file: $@", {item_id=>$file});
            next;
        }
        $res->add_result(200, "Trashed", {item_id=>$file});
    }
    $res->as_struct;
}

$SPEC{trash_rm} = {
    v => 1.1,
    summary => 'Permanently remove files in trash',
    args => {
        files => {
            'x.name.is_plural' => 1,
            'x.name.singular' => 'file',
            summary => 'Wildcard pattern will be interpreted (unless when --no-wildcard option is specified)',
            schema => ['array*', of=>'str*'],
            req => 1,
            pos => 0,
            slurpy => 1,
            element_completion => \&_complete_trashed_filenames,
        },
        no_wildcard => {
            schema => 'true*',
            cmdline_aliases => {W=>{}},
        },
    },
    features => {
        dry_run => 1,
    },
    examples => [
        {
            summary => 'Permanently remove files named "f1" and "f2" in trash',
            argv => ['f1', 'f2'],
            test => 0,
            'x.doc.show_result' => 0,
        },
        {
            summary => 'Permanently remove all .pl and .pm files in trash',
            argv => ['*.pl', '*.pm'],
            test => 0,
            'x.doc.show_result' => 0,
        },
    ],
};
sub trash_rm {
    require File::Trash::FreeDesktop;
    require String::Wildcard::Bash;

    my %args = @_;

    my $trash = File::Trash::FreeDesktop->new;
    for my $file (@{ $args{files} }) {
        my $opts = {};
        if (!$args{no_wildcard} && String::Wildcard::Bash::contains_wildcard($file)) {
            if ($file =~ m!/!) {
                $opts->{path_wildcard} = $file;
            } else {
                $opts->{filename_wildcard} = $file;
            }
        } else {
            if ($file =~ m!/!) {
                $opts->{path} = $file;
            } else {
                $opts->{filename} = $file;
            }
        }

        if ($args{-dry_run}) {
            log_info "Listing files in trash: %s", $opts;
            my @ct = $trash->list_contents($opts);
            for my $e (@ct) {
                log_info "[DRY_RUN] Permanently removing path: %s ...", $e->{path};
            }
        } else {
            log_info "Permanently removing: %s ...", $opts;
            $trash->erase($opts);
        }
    }
    [200, "OK"];
}

$SPEC{trash_restore} = {
    v => 1.1,
    summary => 'Put trashed files back into their original path',
    args => {
        files => {
            'x.name.is_plural' => 1,
            'x.name.singular' => 'file',
            summary => 'Wildcard pattern will be interpreted (unless when --no-wildcard option is specified)',
            schema => ['array*', of=>'str*'],
            req => 1,
            pos => 0,
            slurpy => 1,
            element_completion => \&_complete_trashed_filenames,
        },
        no_wildcard => {
            schema => 'true*',
            cmdline_aliases => {W=>{}},
        },
    },
    features => {
        dry_run => 1,
    },
    examples => [
        {
            summary => 'Restore two files named "f1" and "f2" from trash',
            argv => ['f1', 'f2'],
            test => 0,
            'x.doc.show_result' => 0,
        },
        {
            summary => 'Restore all .pl and .pm files from trash',
            argv => ['*.pl', '*.pm'],
            test => 0,
            'x.doc.show_result' => 0,
        },
    ],
};
sub trash_restore {
    require File::Trash::FreeDesktop;
    require String::Wildcard::Bash;

    my %args = @_;

    my $trash = File::Trash::FreeDesktop->new;
    for my $file (@{ $args{files} }) {
        my $opts = {};
        if (!$args{no_wildcard} && String::Wildcard::Bash::contains_wildcard($file)) {
            if ($file =~ m!/!) {
                $opts->{path_wildcard} = $file;
            } else {
                $opts->{filename_wildcard} = $file;
            }
        } else {
            if ($file =~ m!/!) {
                $opts->{path} = $file;
            } else {
                $opts->{filename} = $file;
            }
        }

        if ($args{-dry_run}) {
            log_info "Listing files in trash: %s", $opts;
            my @ct = $trash->list_contents($opts);
            for my $e (@ct) {
                log_info "[DRY_RUN] Restoring path: %s ...", $e->{path};
            }
        } else {
            log_info "Restoring: %s ...", $opts;
            $trash->recover($opts);
        }
    }
    [200, "OK"];
}

1;
# ABSTRACT: Utilities related to desktop trash

__END__

=pod

=encoding UTF-8

=head1 NAME

App::TrashUtils - Utilities related to desktop trash

=head1 VERSION

This document describes version 0.003 of App::TrashUtils (from Perl distribution App-TrashUtils), released on 2023-08-06.

=head1 DESCRIPTION

This distributions provides the following command-line utilities:

=over

=item * L<trash-list>

=item * L<trash-list-trashes>

=item * L<trash-put>

=item * L<trash-restore>

=item * L<trash-rm>

=back

Prior to C<App::TrashUtils>, there is already C<trash-cli> [1] which is written
in Python. App::TrashUtils aims to scratch some itches and offers some
enhancements:

=over

=item * trash-restore accepts multiple arguments

=item * trash-list accepts files/wildcard patterns

=item * dry-run mode

=item * tab completion

=item * written in Perl

Lastly, App::TrashUtils is written in Perl and is easier to hack for Perl
programmers.

=back

=head1 FUNCTIONS


=head2 trash_list

Usage:

 trash_list(%args) -> [$status_code, $reason, $payload, \%result_meta]

List contents of trash directories.

Examples:

=over

=item * List all files in trash cans:

 trash_list();

=item * List files ending in ".pm" in trash cans, show details:

 trash_list(wildcard => "*.pm", detail => 1);

=item * List all files under the path "E<sol>homeE<sol>ujangE<sol>Documents" in trash cans:

 trash_list(wildcard => "/home/ujang/Documents/**");

=back

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<detail> => I<bool>

(No description)

=item * B<wildcard> => I<str>

Filter path or filename with wildcard pattern.

Will be matched against path if pattern contains C</>, otherwise will be matched
against filename. Supported patterns are jokers (C<*> and C<?>), character class
(e.g. C<[123]>), and globstar (C<**>).

When specifying the wildcard on the CLI, remember to quote it to protect from
being interpreted by the shell, e.g. to match files in the current directory.


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 trash_list_trashes

Usage:

 trash_list_trashes() -> [$status_code, $reason, $payload, \%result_meta]

List trash directories.

This function is not exported.

No arguments.

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 trash_put

Usage:

 trash_put(%args) -> [$status_code, $reason, $payload, \%result_meta]

Put files into trash.

Examples:

=over

=item * Trash two files:

 trash_put(files => ["file1", "file2.txt"]);

=back

This function is not exported.

This function supports dry-run operation.


Arguments ('*' denotes required arguments):

=over 4

=item * B<files>* => I<array[pathname]>

(No description)


=back

Special arguments:

=over 4

=item * B<-dry_run> => I<bool>

Pass -dry_run=E<gt>1 to enable simulation mode.

=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 trash_restore

Usage:

 trash_restore(%args) -> [$status_code, $reason, $payload, \%result_meta]

Put trashed files back into their original path.

Examples:

=over

=item * Restore two files named "f1" and "f2" from trash:

 trash_restore(files => ["f1", "f2"]);

=item * Restore all .pl and .pm files from trash:

 trash_restore(files => ["*.pl", "*.pm"]);

=back

This function is not exported.

This function supports dry-run operation.


Arguments ('*' denotes required arguments):

=over 4

=item * B<files>* => I<array[str]>

Wildcard pattern will be interpreted (unless when --no-wildcard option is specified).

=item * B<no_wildcard> => I<true>

(No description)


=back

Special arguments:

=over 4

=item * B<-dry_run> => I<bool>

Pass -dry_run=E<gt>1 to enable simulation mode.

=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 trash_rm

Usage:

 trash_rm(%args) -> [$status_code, $reason, $payload, \%result_meta]

Permanently remove files in trash.

Examples:

=over

=item * Permanently remove files named "f1" and "f2" in trash:

 trash_rm(files => ["f1", "f2"]);

=item * Permanently remove all .pl and .pm files in trash:

 trash_rm(files => ["*.pl", "*.pm"]);

=back

This function is not exported.

This function supports dry-run operation.


Arguments ('*' denotes required arguments):

=over 4

=item * B<files>* => I<array[str]>

Wildcard pattern will be interpreted (unless when --no-wildcard option is specified).

=item * B<no_wildcard> => I<true>

(No description)


=back

Special arguments:

=over 4

=item * B<-dry_run> => I<bool>

Pass -dry_run=E<gt>1 to enable simulation mode.

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

Please visit the project's homepage at L<https://metacpan.org/release/App-TrashUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-TrashUtils>.

=head1 SEE ALSO

[1] L<https://github.com/andreafrancia/trash-cli>, Python-based CLIs delated to
desktop trash.

L<File::Trash::FreeDesktop>

Alternative CLI's: L<trash-u> (from L<App::trash::u>) which supports undo.

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

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-TrashUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
