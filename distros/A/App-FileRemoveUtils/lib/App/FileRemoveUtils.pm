package App::FileRemoveUtils;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-05-30'; # DATE
our $DIST = 'App-FileRemoveUtils'; # DIST
our $VERSION = '0.002'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

use Exporter 'import';
our @EXPORT_OK = qw(delete_all_empty_files delete_all_empty_dirs);

our %SPEC;

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
    require File::Find;
    my %args = @_;

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

    for my $f (@files) {
        if ($args{-dry_run}) {
            log_info "[DRY-RUN] Deleting %s ...", $f;
        } else {
            log_info "Deleting %s ...", $f;
            unlink $f or do {
                log_error "Failed deleting %s: %s", $f, $!;
            };
        }
    }

    [200];
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
    require File::Find;
    require File::MoreUtil;
    my %args = @_;

    my %dirs; # key = path, value = {subdir => 1}
    File::Find::find(
        sub {
            return if $_ eq '.' || $_ eq '..';
            return if -l $_;
            return unless -d _;
            return if File::MoreUtil::dir_has_non_subdirs($_);
            my $path = ($File::Find::dir eq '.' ? '' : "$File::Find::dir/"). $_;
            $dirs{$path} = { map {$_=>1} File::MoreUtil::get_dir_entries($_) };
        },
        '.'
    );

    for my $dir (sort { length($b) <=> length($a) } keys %dirs) {
        if ($args{-dry_run}) {
            if (!(keys %{ $dirs{$dir} })) {
                log_info "[DRY-RUN] Deleting %s ...", $dir;
                $dir =~ m!(.+)/(.+)! or next;
                my ($parent, $base) = ($1, $2);
                delete $dirs{$parent}{$base};
            }
        } else {
            if (File::MoreUtil::dir_empty($dir)) {
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

This document describes version 0.002 of App::FileRemoveUtils (from Perl distribution App-FileRemoveUtils), released on 2020-05-30.

=head1 DESCRIPTION

This distribution provides the following command-line utilities:

=over

=item * L<delete-all-empty-dirs>

=item * L<delete-all-empty-files>

=back

=head1 FUNCTIONS


=head2 delete_all_empty_dirs

Usage:

 delete_all_empty_dirs() -> [status, msg, payload, meta]

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

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 delete_all_empty_files

Usage:

 delete_all_empty_files() -> [status, msg, payload, meta]

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

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-FileRemoveUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-FileRemoveUtils>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-FileRemoveUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<rmhere> from L<App::rmhere>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
