package App::FileRemoveUtils;

use 5.010001;
use strict;
use warnings;
use Log::ger;

use Exporter 'import';

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-11-20'; # DATE
our $DIST = 'App-FileRemoveUtils'; # DIST
our $VERSION = '0.007'; # VERSION

our @EXPORT_OK = qw(delete_all_empty_files delete_all_empty_dirs);

our %SPEC;

$SPEC{list_all_empty_files} = {
    v => 1.1,
    summary => 'List all empty (zero-sized) files in the current directory tree',
    args => {},
    result_naked => 1,
};
sub list_all_empty_files {
    require File::Find;

    my @files;
    File::Find::find(
        sub {
            -l $_; # perform lstat instead of stat
            return unless -f _;
            return if -s _;
            push @files, "$File::Find::dir/$_";
        },
        '.'
    );

    \@files;
}

$SPEC{list_all_empty_dirs} = {
    v => 1.1,
    summary => 'List all sempty (zero-entry) subdirectories in the current directory tree',
    args_as => 'array',
    args => {
        include_would_be_empty => {
            summary => 'Include directories that would be empty if '.
                'their empty subdirectories are removed',
            schema => 'bool*',
            pos => 0,
            default => 1,
        },
    },
    result_naked => 1,
};
sub list_all_empty_dirs {
    require File::Find;
    require File::Util::Test;

    my $include_would_be_empty = $_[0] // 1;

    my %dirs; # key = path, value = {subdir => 1}
    File::Find::find(
        sub {
            return if $_ eq '.' || $_ eq '..';
            return if -l $_;
            return unless -d _;
            return if File::Util::Test::dir_has_non_subdirs($_);
            my $path = "$File::Find::dir/$_";
            $dirs{$path} = { map {$_=>1} File::Util::Test::get_dir_entries($_) };
        },
        '.'
    );

    my @dirs;
    for my $dir (sort { length($b) <=> length($a) || $a cmp $b } keys %dirs) {
        if (!(keys %{ $dirs{$dir} })) {
            push @dirs, $dir;
            if ($include_would_be_empty) {
                $dir =~ m!(.+)/(.+)! or next;
                my ($parent, $base) = ($1, $2);
                delete $dirs{$parent}{$base};
            }
        }
    }

    \@dirs;
}

$SPEC{delete_all_empty_files} = {
    v => 1.1,
    summary => 'Delete all empty (zero-sized) files recursively',
    args => {
    },
    features => {
        dry_run=>{default=>1},
    },
    examples => [
        {
            summary => 'Show what files will be deleted (dry-mode by default)',
            src => 'delete-all-empty-files',
            src_plang => 'bash',
            test => 0,
            'x.doc.show_result' => 0,
        },
        {
            summary => 'Actually delete files (disable dry-run mode)',
            src => 'delete-all-empty-files --no-dry-run',
            src_plang => 'bash',
            test => 0,
            'x.doc.show_result' => 0,
        },
    ],
};
sub delete_all_empty_files {
    my %args = @_;

    my $files = list_all_empty_files();
    for my $f (@$files) {
        if ($args{-dry_run}) {
            log_info "[DRY-RUN] Deleting %s ...", $f;
        } else {
            log_info "Deleting %s ...", $f;
            unlink $f or do {
                log_error "Failed deleting %s: %s", $f, $!;
            };
        }
    }

    [200, "OK", undef, {
        'func.files' => $files,
    }];
}

$SPEC{delete_all_empty_dirs} = {
    v => 1.1,
    summary => 'Delete all empty (zero-sized) subdirectories recursively',
    args => {
    },
    features => {
        dry_run=>{default=>1},
    },
    examples => [
        {
            summary => 'Show what directories will be deleted (dry-mode by default)',
            src => 'delete-all-empty-dirs',
            src_plang => 'bash',
            test => 0,
            'x.doc.show_result' => 0,
        },
        {
            summary => 'Actually delete files (disable dry-run mode)',
            src => 'delete-all-empty-dirs --no-dry-run',
            src_plang => 'bash',
            test => 0,
            'x.doc.show_result' => 0,
        },
    ],
};
sub delete_all_empty_dirs {
    my %args = @_;

    my $dirs = list_all_empty_dirs();
    for my $dir (@$dirs) {
        if ($args{-dry_run}) {
            log_info "[DRY-RUN] Deleting %s ...", $dir;
        } else {
            if (File::Util::Test::dir_empty($dir)) {
                log_info "Deleting %s ...", $dir;
                rmdir $dir or do {
                    log_error "Failed deleting %s: %s", $dir, $!;
                };
            }
        }
    }

    [200];
}

1;
# ABSTRACT: Utilities related to removing/deleting files

__END__

=pod

=encoding UTF-8

=head1 NAME

App::FileRemoveUtils - Utilities related to removing/deleting files

=head1 VERSION

This document describes version 0.007 of App::FileRemoveUtils (from Perl distribution App-FileRemoveUtils), released on 2023-11-20.

=head1 DESCRIPTION

This distribution provides the following command-line utilities:

=over

=item * L<delete-all-empty-dirs>

=item * L<delete-all-empty-files>

=item * L<list-all-empty-dirs>

=item * L<list-all-empty-files>

=back

=head1 FUNCTIONS


=head2 delete_all_empty_dirs

Usage:

 delete_all_empty_dirs() -> [$status_code, $reason, $payload, \%result_meta]

Delete all empty (zero-sized) subdirectories recursively.

This function is not exported by default, but exportable.

This function supports dry-run operation.


No arguments.

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



=head2 delete_all_empty_files

Usage:

 delete_all_empty_files() -> [$status_code, $reason, $payload, \%result_meta]

Delete all empty (zero-sized) files recursively.

This function is not exported by default, but exportable.

This function supports dry-run operation.


No arguments.

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



=head2 list_all_empty_dirs

Usage:

 list_all_empty_dirs($include_would_be_empty) -> any

List all sempty (zero-entry) subdirectories in the current directory tree.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<$include_would_be_empty> => I<bool> (default: 1)

Include directories that would be empty if their empty subdirectories are removed.


=back

Return value:  (any)



=head2 list_all_empty_files

Usage:

 list_all_empty_files() -> any

List all empty (zero-sized) files in the current directory tree.

This function is not exported.

No arguments.

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-FileRemoveUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-FileRemoveUtils>.

=head1 SEE ALSO

L<rmhere> from L<App::rmhere>

Other similar distributions: L<App::FileModifyUtils>,
L<App::FileRenameUtilities>.

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

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-FileRemoveUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
