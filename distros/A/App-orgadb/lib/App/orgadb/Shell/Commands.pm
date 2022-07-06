package App::orgadb::Shell::Commands;

use 5.010001;
use strict;
use warnings;
use Log::ger;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-07-04'; # DATE
our $DIST = 'App-orgadb'; # DIST
our $VERSION = '0.004'; # VERSION

use App::orgadb::Common;

our %SPEC;

$SPEC{':package'} = {
    v => 1.1,
    summary => 'orgadb shell commands',
};

$SPEC{history} = {
    v => 1.1,
    summary => 'Show shell history',
    args => {
        append => {
            summary    => "Append current session's history to history file",
            schema     => 'bool',
            cmdline_aliases => { a=>{} },
        },
        read => {
            summary    => '(Re-)read history from file',
            schema     => 'bool',
            cmdline_aliases => { r=>{} },
        },
        clear => {
            summary    => 'Clear history',
            schema     => 'bool',
            cmdline_aliases => { c=>{} },
        },
    },
};
sub history {
    my %args = @_;
    my $shell = $args{-shell};

    if ($args{add}) {
        $shell->save_history;
        return [200, "OK"];
    } elsif ($args{read}) {
        $shell->load_history;
        return [200, "OK"];
    } elsif ($args{clear}) {
        $shell->clear_history;
        return [200, "OK"];
    } else {
        my @history;
        if ($shell->{term}->Features->{getHistory}) {
            @history = grep { length } $shell->{term}->GetHistory;
        }
        return [200, "OK", \@history,
                {"x.app.riap.default_format"=>"text-simple"}];
    }
}

$SPEC{select} = {
    v => 1.1,
    summary => 'Select entries/fields/subfields',
    args => {
        %App::orgadb::Common::argspecs_select,
    },
};
sub select {
    my %args = @_;
    my $shell = $args{-shell};

    my $code_parse_files = $args{_code_parse_files};

    # XXX currently when one file changes mtime, all files are reloaded
    my $files = $shell->state('orgadb_args')->{files};
    my $should_reload;
    {
        my $file_mtimes = $shell->state('file_mtimes');
        unless ($file_mtimes) {
            $file_mtimes = [];
            $shell->state('file_mtimes', $file_mtimes);
        }
        for my $i (0 .. $#{$files}) {
            my $file = $files->[$i];
            my $cur_mtime = -M $file;
            my $last_mtime = $file_mtimes->[$i];
            if (!$last_mtime || $cur_mtime != $last_mtime) {
                $should_reload++;
            }
            $file_mtimes->[$i] = $cur_mtime;
        }
    }

    if ($should_reload) {
        my ($trees, $tree_filenames) =
            $shell->state('orgadb_args')->{_code_parse_files}->(@$files);

        $shell->state(trees => $trees);
        $shell->state(tree_filenames => $tree_filenames);
    }

    App::orgadb::_select_addressbook_entries_single(
        %{ $shell->{_state}{orgadb_args} },
        _trees => $shell->state('trees'),
        _tree_filenames => $shell->state('tree_filenames'),
        %args,
    );
}

1;
# ABSTRACT: orgadb shell commands

__END__

=pod

=encoding UTF-8

=head1 NAME

App::orgadb::Shell::Commands - orgadb shell commands

=head1 VERSION

This document describes version 0.004 of App::orgadb::Shell::Commands (from Perl distribution App-orgadb), released on 2022-07-04.

=for Pod::Coverage .+

=head1 FUNCTIONS


=head2 history

Usage:

 history(%args) -> [$status_code, $reason, $payload, \%result_meta]

Show shell history.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<append> => I<bool>

Append current session's history to history file.

=item * B<clear> => I<bool>

Clear history.

=item * B<read> => I<bool>

(Re-)read history from file.


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 select

Usage:

 select(%args) -> [$status_code, $reason, $payload, \%result_meta]

Select entriesE<sol>fieldsE<sol>subfields.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<category> => I<str_or_re>

Find entry by string or regex search against the category title.

=item * B<detail> => I<bool>

=item * B<entry> => I<str_or_re>

Find entry by string or regex search against its title.

=item * B<fields> => I<array[str_or_re]>

Find (sub)fields by string or regex search.

=item * B<hide_category> => I<true>

Do not show category.

=item * B<hide_entry> => I<true>

Do not show entry headline.

=item * B<hide_field_name> => I<true>

Do not show field names, just show field values.


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

Please visit the project's homepage at L<https://metacpan.org/release/App-orgadb>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-orgadb>.

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

This software is copyright (c) 2022 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-orgadb>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
