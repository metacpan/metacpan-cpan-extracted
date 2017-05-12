package Data::Section::Seekable;

our $DATE = '2016-02-19'; # DATE
our $VERSION = '0.09'; # VERSION

1;
# ABSTRACT: Read and write parts from data section

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Section::Seekable - Read and write parts from data section

=head1 VERSION

This document describes version 0.09 of Data::Section::Seekable (from Perl distribution Data-Section-Seekable), released on 2016-02-19.

=head1 DESCRIPTION

This module defines a simple format to let you store and read parts from data
section. The distribution also comes with a reader (see
L<Data::Section::Seekable::Reader>) and a writer/generator (see
L<Data::Section::Seekable::Writer>).

Like L<Data::Section>, the format allows you to store multiple parts in data
section. This module's format is different from Data::Section's and is meant to
allow seeking to any random content part just by reading the index/"table of
content" part of the data section.

=head1 FORMAT

This document descries version 1 (v1) of the format.

First line of data section is the header line and must be:

 Data::Section::Seekable v1

Actually, the header line need not be the first line of data. Previous lines not
matching the header line will be ignored (so you can put other stuffs here).

After the header line, comes zero or more TOC ("table of content") lines. Each
TOC line must match this Perl regex:

 /^([^,]+), (\d+), (\d+) (?:, (.*))?/x

The first field is the name, the second field is the offset, the third field is
the length. Offset starts from 0 and the zero is counted from after the blank
line after the last TOC line. The fourth field is to store extra information, it
is optional and can contain zero or more non-newline characters.

After the last TOC line is a blank line. And after that is content.

Example:

 Data::Section::Seekable v1
 part1,0,14
 part2,14,17,very,important

 This is part1
 This is part
 two

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Data-Section-Seekable>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Data-Section-Seekable>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Section-Seekable>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Data::Section>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
