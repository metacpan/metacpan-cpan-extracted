package CPAN::Mini::NoLargeFiles;

our $DATE = '2015-01-13'; # DATE
our $VERSION = '0.02'; # VERSION

use 5.010;
use strict;
use warnings;

use LWP::UserAgent::Patch::FilterMirrorMaxSize
    -size=>($ENV{MAX_FILE_SIZE} // 10*1024*1024), -verbose=>1;

use parent 'CPAN::Mini';

1;

# ABSTRACT: Create a CPAN mirror excluding files that are too large

__END__

=pod

=encoding UTF-8

=head1 NAME

CPAN::Mini::NoLargeFiles - Create a CPAN mirror excluding files that are too large

=head1 VERSION

This document describes version 0.02 of CPAN::Mini::NoLargeFiles (from Perl distribution CPAN-Mini-NoLargeFiles), released on 2015-01-13.

=head1 SYNOPSIS

By default files larger than 10MB will be skipped:

 % minicpan -c CPAN::Mini::NoLargeFiles ...

To specify size:

 % MAX_FILE_SIZE=20000000 minicpan -c CPAN::Mini::NoLargeFiles ...

=head1 DESCRIPTION

There are files uploaded to CPAN that are quite large (over 100MB). For those
like me who are often on a limited mobile data plan, or using a miniscule-sized
SSD, this L<CPAN::Mini> subclass might be useful.

This is a thin wrapper for L<LWP::UserAgent::Patch::FilterMirrorMaxSize>, so
instead of:

 % PERL5OPT="-MLWP::UserAgent::Patch::FilterMirrorMaxSize=-size,10485760,-verbose,1" minicpan ...

you can just do:

 % cpan -c CPAN::Mini::NoLargeFiles ...

=for Pod::Coverage ^(.*)$

=head1 FAQ

=head2 How to mix with other subclasses (e.g. I also want to use CPAN::Mini::LatestDistVersion)

Use the patch directly instead of this subclass (see Description).

=head1 SEE ALSO

L<http://blogs.perl.org/users/steven_haryanto/2014/06/skipping-large-files-when-mirroring-your-mini-cpan.html>

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/CPAN-Mini-NoLargeFiles>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-CPAN-Mini-NoLargeFiles>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=CPAN-Mini-NoLargeFiles>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
