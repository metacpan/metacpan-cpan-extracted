package App::FindUtils;

use 5.010001;
use strict;
use warnings;
use Log::ger;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2025-10-31'; # DATE
our $DIST = 'App-FindUtils'; # DIST
our $VERSION = '0.004'; # VERSION

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
    },
    examples => [
        {
            summary => "Find duplicate filenames under the current directory",
            test => 0,
            'x.doc.show_result' => 0,
            src => '[[prog]]',
            src_plang => 'bash',
        },
    ],
};
sub find_duplicate_filenames {
    require Cwd;
    require File::Find;

    my %args = @_;
    $args{dirs} //= ["."];
    #my $ci = $args{case_insensitive};

    my %files; # filename => {realpath1=>orig_filename, ...}. if hash has >1 keys than it's duplicate
    File::Find::find(
        sub {
            no warnings 'once'; # for $File::find::dir
            # XXX inefficient
            my $realpath = Cwd::realpath($_);
            log_debug "Found path $realpath";
            $files{$_}{$realpath}++;
        },
        @{ $args{dirs} }
    );

    my @res;
    for my $file (sort keys %files) {
        next unless keys(%{$files{$file}}) > 1;
        log_info "%s is a DUPLICATE name (found in %d paths)", $file, scalar(keys %{$files{$file}});
        if ($args{detail}) {
            for my $path (sort keys %{$files{$file}}) {
                push @res, {name=>$file, path=>$path};
            }
        } else {
            push @res, $file;
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

This document describes version 0.004 of App::FindUtils (from Perl distribution App-FindUtils), released on 2025-10-31.

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
