package App::FindUtils;

use 5.010001;
use strict;
use warnings;
use Log::ger;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2025-11-26'; # DATE
our $DIST = 'App-FindUtils'; # DIST
our $VERSION = '0.005'; # VERSION

our %SPEC;

$SPEC{find_duplicate_filenames} = {
    v => 1.1,
    summary => 'Search directories recursively and find files/dirs with duplicate names',
    args => {
        dirs => {
            'x.name.is_plural' => 1,
            'x.name.singular' => 'dir',
            schema => ['array*', of=>'dirname*'],
            default => ['.'],
            pos => 0,
            slurpy => 1,
        },
        #case_insensitive => {
        #    schema => 'bool*',
        #    cmdline_aliases=>{i=>{}},
        #},
        detail => {
            summary => 'Instead of just listing duplicate names, return all the location of duplicates',
            schema => 'bool*',
            cmdline_aliases => {l=>{}},
        },
        eval => {
            #schema => 'code_from_str::local_topic*', # not yet available
            schema => 'str*',
            description => <<'MARKDOWN',

Process filename through this code. Code will receive filename in `$_` and is
expected to change and return a new "name" that will be compared for duplicate
instead of the original name. You can use this e.g. to find duplicate in some
part of the filename. As an alternative, see the `--regex` option.

MARKDOWN
            cmdline_aliases => {e=>{}},
        },
        regex => {
            schema => 're_from_str*',
            description => <<'MARKDOWN',

Specify a regex with a capture to get part of the filename. The first capture
`$1` will be used to compare for duplicate instead of the original name. You can
use this to find duplicate in some part of the filename. As an alternative, see
the `--eval` option.

MARKDOWN
            cmdline_aliases => {r=>{}},
        },
        exclude_filename_regex => {
            schema => 're_from_str*',
            summary => 'Filename regex to exclude',
            cmdline_aliases => {x=>{}},
        },
    },
    examples => [
        {
            summary => "Find duplicate filenames under the current directory",
            test => 0,
            'x.doc.show_result' => 0,
            src => '[[prog]]',
            src_plang => 'bash',
        },
        {
            summary => "Find duplicate receipts by order ID (filenames are named receipt-order=12345.pdf), exclude backup files",
            test => 0,
            'x.doc.show_result' => 0,
            src => q{[[prog]] -x '/\\.bak$/' -r '/order=(\\d+)/' --debug},
            src_plang => 'bash',
        },
    ],
    args_rels => {
        choose_one => ['eval', 'regex'],
    },
};
sub find_duplicate_filenames {
    require Cwd;
    require File::Find;

    my %args = @_;
    $args{dirs} //= ["."];
    my $eval;
    if (defined $args{eval}) {
        my $code = "no strict; no warnings; package main; sub { local \$_=\$_; " . $args{eval} . "; return \$_ }";
        $eval = eval $code or return [400, "Can't compile code in eval: $@"]; ## no critic: BuiltinFunctions::ProhibitStringyEval
    } elsif (defined $args{regex}) {
        $eval = sub { /$args{regex}/; $1 };
    }

    #my $ci = $args{case_insensitive};

    my %names; # filename (or name) => {realpath1=>1, ...}. if hash has >1 keys than it's duplicate
    File::Find::find(
        sub {
            no warnings 'once'; # for $File::find::dir
            # XXX inefficient
            my $realpath = Cwd::realpath($_);
            log_debug "Found path $realpath";

            if ($args{exclude_filename_regex}) {
                if ($_ =~ $args{exclude_filename_regex}) {
                    log_info "$_ excluded (matches --exclude-filename-regex: $args{exclude_filename_regex})";
                    return;
                }
            }

            my $name;
            if ($eval) {
                $name = $eval->();
            } else {
                $name = $_;
            }

            $names{$name}{$realpath}++;
        },
        @{ $args{dirs} }
    );

    my @res;
    for my $name (sort keys %names) {
        next unless keys(%{$names{$name}}) > 1;
        log_info "%s is a DUPLICATE name (found in %d paths: %s)", $name, scalar(keys %{$names{$name}}), join(", ", sort(keys %{$names{$name}}));
        if ($args{detail}) {
            for my $path (sort keys %{$names{$name}}) {
                push @res, {name=>$name, path=>$path};
            }
        } else {
            push @res, $name;
        }
    }
    [200, "OK", \@res];
}

1;
# ABSTRACT: Utilities related to finding files

__END__

=pod

=encoding UTF-8

=head1 NAME

App::FindUtils - Utilities related to finding files

=head1 VERSION

This document describes version 0.005 of App::FindUtils (from Perl distribution App-FindUtils), released on 2025-11-26.

=head1 DESCRIPTION

This distributions provides the following command-line utilities:

=over

=item * L<find-duplicate-filenames>

=back

=head1 FUNCTIONS


=head2 find_duplicate_filenames

Usage:

 find_duplicate_filenames(%args) -> [$status_code, $reason, $payload, \%result_meta]

Search directories recursively and find filesE<sol>dirs with duplicate names.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<detail> => I<bool>

Instead of just listing duplicate names, return all the location of duplicates.

=item * B<dirs> => I<array[dirname]> (default: ["."])

(No description)

=item * B<eval> => I<str>

Process filename through this code. Code will receive filename in C<$_> and is
expected to change and return a new "name" that will be compared for duplicate
instead of the original name. You can use this e.g. to find duplicate in some
part of the filename. As an alternative, see the C<--regex> option.

=item * B<exclude_filename_regex> => I<re_from_str>

Filename regex to exclude.

=item * B<regex> => I<re_from_str>

Specify a regex with a capture to get part of the filename. The first capture
C<$1> will be used to compare for duplicate instead of the original name. You can
use this to find duplicate in some part of the filename. As an alternative, see
the C<--eval> option.


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

Please visit the project's homepage at L<https://metacpan.org/release/App-FindUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-FindUtils>.

=head1 SEE ALSO

L<uniq-files> from L<App::UniqFiles>

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

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-FindUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
