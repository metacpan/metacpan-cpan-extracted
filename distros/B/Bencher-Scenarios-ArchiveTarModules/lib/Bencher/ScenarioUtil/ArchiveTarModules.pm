package Bencher::ScenarioUtil::ArchiveTarModules;

our $DATE = '2017-01-25'; # DATE
our $VERSION = '0.002'; # VERSION

use strict;
use warnings;

use File::ShareDir 'dist_dir';

our @Datasets = do {
    my @res;
    my $path;

    {
        $path = "share/archive.tar.gz";
        last if -f $path;
        $path = dist_dir("Bencher-Scenarios-ArchiveTarModules");
    }
    push @res, {
        name    => 'archive.tar.gz',
        summary => 'Sample archive with 10 files, ~10MB each',
        args    => {filename=>$path},
    };

    @res;
};

our %Modules = (
    'Archive::Tar' => {
        description => <<'_',

Archive::Tar is a core module. It reads the whole archive into memory, so care
should be taken when handling very large archives.

_
        code_template_list_files => <<'_',
            my $filename = <filename>;
            my $obj = Archive::Tar->new;
            my @files = $obj->read($filename);
            my @res;
            for my $file (@files) {
                push @res, {
                    name => $file->name,
                    size => $file->size,
                };
            }
            return @res;
_
    },

    'Archive::Tar::Wrapper' => {
        description => <<'_',

Archive::Tar::Wrapper is an API wrapper around the 'tar' command line utility.
It never stores anything in memory, but works on temporary directory structures
on disk instead. It provides a mapping between the logical paths in the tarball
and the 'real' files in the temporary directory on disk.

_
        code_template_list_files => <<'_',
            my $filename = <filename>;
            my $obj = Archive::Tar::Wrapper->new;
            my @res;
            $obj->list_reset;
            while (my $entry = $obj->list_next) {
                my ($tar_path, $phys_path) = @$entry;
                push @res, {
                    name => $tar_path,
                    size => (-s $phys_path),
                };
            }
            return @res;
_
    },
);

1;
# ABSTRACT: Utility routines

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::ScenarioUtil::ArchiveTarModules - Utility routines

=head1 VERSION

This document describes version 0.002 of Bencher::ScenarioUtil::ArchiveTarModules (from Perl distribution Bencher-Scenarios-ArchiveTarModules), released on 2017-01-25.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-ArchiveTarModules>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-ArchiveTarModules>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-ArchiveTarModules>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
