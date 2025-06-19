package App::orgadb::Select::Shell::Commands;

use 5.010001;
use strict;
use warnings;
use Log::ger;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2025-06-19'; # DATE
our $DIST = 'App-orgadb'; # DIST
our $VERSION = '0.020'; # VERSION

use App::orgadb::Common;

our %SPEC;

$SPEC{':package'} = {
    v => 1.1,
    summary => 'orgadb-sel shell commands',
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
    my $files = $shell->state('main_args')->{files};
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
            $shell->state('main_args')->{_code_parse_files}->(@$files);

        $shell->state(trees => $trees);
        $shell->state(tree_filenames => $tree_filenames);
    }

    App::orgadb::_select_single(
        %{ $shell->{_state}{main_args} },
        _trees => $shell->state('trees'),
        _tree_filenames => $shell->state('tree_filenames'),
        %args,
    );
}

1;
# ABSTRACT: orgadb-sel shell commands

__END__

=pod

=encoding UTF-8

=head1 NAME

App::orgadb::Select::Shell::Commands - orgadb-sel shell commands

=head1 VERSION

This document describes version 0.020 of App::orgadb::Select::Shell::Commands (from Perl distribution App-orgadb), released on 2025-06-19.

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

=item * B<clipboard> => I<str>

Whether to copy matching field values to clipboard.

If set to C<tee>, then will display matching fields to terminal as well as copy
matching field values to clipboard.

If set to C<only>, then will not display matching fields to terminal and will
only copy matching field values to clipboard.

Mnemonic for short option C<-y> and C<-Y>: I<y>ank as in Emacs (C<C-y>).

=item * B<count> => I<true>

Return just the number of matching entries instead of showing them.

=item * B<detail> => I<bool>

Instead of showing matching field values, display the whole entry.

Mnemonic for shortcut option C<-l>: the option C<-l> is usually used for the short
version of C<--detail>, as in I<ls> Unix command.

=item * B<entry> => I<str_or_re>

Find entry by string or regex search against its title.

=item * B<entry_match_mode> => I<str> (default: "default")

How entry should be matched.

The default matching mode is as follow:

 str       Substring matching
 /re/      Regular expression matching

If matching mode is set to C<exact>, then matching will be done by string
equality test. This mode is basically a shorter alternative to having to
specify:

 /^\Qre\E$/

Matching mode C<exact-ci> is like C<exact> except case-insensitive. It is
equivalent to:

 /^\Qre\E$/i

=item * B<field_match_mode> => I<str> (default: "default")

How entry should be matched.

The default matching mode is as follow:

 str       Substring matching
 /re/      Regular expression matching

If matching mode is set to C<exact>, then matching will be done by string
equality test. This mode is basically a shorter alternative to having to
specify:

 /^\Qre\E$/

Matching mode C<exact-ci> is like C<exact> except case-insensitive. It is
equivalent to:

 /^\Qre\E$/i

=item * B<field_value_formatter_rules> => I<array[hash]>

Specify field value formatters to use when conditions are met, specified as an
array of hashes. Each element is a rule that is as a hash containing condition
keys and formatters keys. If all conditions are met then the formatters will be
applied. The rules will be tested when each field is about to be outputted.
Multiple rules can match and the matching rules' formatters are all applied in
succession.

Note that this option will be overridden by the C<--field-value-formatter>
(C<-fvfmt>) or the C<--no-field-value-formatters> (C<-F>) option.

The rules are best specified in the configuration as opposed to on the
command-line option. An example (the lines below are writen in configuration
file in IOD syntax, as rows of JSON hashes):

 ; remove all comments in field values when 'hide_field_name' option is set
 ; (which usually means we want to copy paste things)
 
 field_value_formatter_rules={"hide_field_name":true, "formatters":[ ["Str::remove_comment"] ]}
 
 ; normalize phone numbers using Phone::format + Str::remove_whitespace when
 ; 'hide_field_name' option is set (which usually means we want to copy paste
 ; things). e.g. '0812-1234-5678' becomes '+6281212345678'.
 
 field_value_formatter_rules={"field_name_matches":"/phone|wa|whatsapp/i", "hide_field_name":true, "formatters":[ ["Phone::format", "Str::remove_whitespace"] ]}
 
 ; but if 'hide_field_name' field is not set, normalize phone numbers using
 ; Phone::format without removing whitespaces, which is easier to see (e.g.
 ; '+62 812 1234 5678').
 
 field_value_formatter_rules={"field_name_matches":"/phone|wa|whatsapp/i", "hide_field_name":false, "formatters":[ ["Phone::format"] ]}

Condition keys:

=over

=item * C<field_name_matches> (value: str/re): Check if field name matches a regex pattern.

=item * C<hide_field_name> (value: bool): Check if C<--hide-field-name> (C<-N>) option is
set (true) or unset (false).

=back

Formatter keys:

=over

=item * C<formatters>: an array of formatters, to be applied. Each formatter is a name
of perl Sah filter rule, or a two-element array of perl Sah filter rule name
followed by hash containing arguments. See C<--formatter> for more detais on
specifying formatter.

=back

=item * B<field_value_formatters> => I<array[str]>

Add one or more formatters to display field value.

Specify one or more formatters to apply to the field value before displaying.

A formatter is name of C<Data::Sah::Filter::perl::*> module, without the prefix.
For example: C<Str::uc> will convert the field value to uppercase. Another
formatter, C<Str::remove_comment> can remove comment.

A formatter can have arguments, which is specified using this format:

 [FORMATTER_NAME, {ARG1NAME => ARG1VAL, ...}]

If formatter name begins with C<[> character, it will be parsed as JSON. Example:

 ['Str::remove_comment', {'style':'cpp'}]

Note that this option overrides C<--field-value-formatter-rules> but is
overridden by the C<--no-field-value-formatters> (C<--raw-field-values>, C<-F>)
option.

=item * B<fields> => I<array[str_or_re]>

Find (sub)fields by string or regex search.

=item * B<filter_entries_by_fields> => I<array[str]>

Find entry by the fields or subfields it has.

The format of each entry_by_field is one of:

 str
 /re/
 str = str2
 str = /re2/
 /re/ = str2
 /re/ = /re2/

That is, it can search for a string (C<str>) or regex (C<re>) in the field name,
and optionally also search for a string (C<str2>) or regex (C<re2>) in the field
value.

=item * B<hide_category> => I<true>

Do not show category.

=item * B<hide_entry> => I<true>

Do not show entry headline.

=item * B<hide_field_name> => I<true>

Do not show field names, just show field values.

Mnemonic for short option C<-N>: field I<N>ame (uppercase letter usually means
/no/).

=item * B<no_field_value_formatters> => I<true>

Do not apply formatters for field value (overrides --field-value-formatter option).

Note that this option has higher precedence than
C<--default-field-value-formatter-rules> or the C<--field-value-formatter>
(C<--fvfmt>) option.

=item * B<num_entries> => I<uint>

Specify maximum number of entries to return (0 means unlimited).

=item * B<num_fields> => I<uint>

Specify maximum number of fields (per entry) to return (0 means unlimited).


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
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>,
L<Pod::Weaver::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla- and/or Pod::Weaver plugins. Any additional steps required beyond
that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-orgadb>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
