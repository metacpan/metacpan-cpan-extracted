package Comparer::file_mtime;

use 5.010001;
use strict 'subs', 'vars';
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-09-19'; # DATE
our $DIST = 'Comparer-file_mtime'; # DIST
our $VERSION = '0.001'; # VERSION

sub meta {
    return +{
        v => 1,
        args => {
            reverse => {schema => 'bool*'},
        },
    };
}

sub gen_comparer {
    my %args = @_;

    my $reverse = $args{reverse};

    sub {
        (
            (-M $_[1]) <=> (-M $_[0])
        ) * ($args{reverse} ? -1 : 1)
    };
}

1;
# ABSTRACT: Compare file's mtime (modification time)

__END__

=pod

=encoding UTF-8

=head1 NAME

Comparer::file_mtime - Compare file's mtime (modification time)

=head1 VERSION

This document describes version 0.001 of Comparer::file_mtime (from Perl distribution Comparer-file_mtime), released on 2024-09-19.

=head1 SYNOPSIS

 use Comparer::from_sortkey;

 my $cmp = Comparer::file_mtime::gen_comparer();
 my @sorted = sort { $cmp->($a,$b) } "newest", "old", "new";
 # => ("old","new","newest")

 # reverse
 $cmp = Comparer::file_mtime::gen_comparer(reverse => 1);
 @sorted = sort { $cmp->($a,$b) } "newest", "old", "new";
 # => ("newest","new","old")

=head1 DESCRIPTION

This comparer assumes the entries are filenames and will compare their
modification time.

=for Pod::Coverage ^(meta|gen_comparer)$

=head1 COMPARER ARGUMENTS

=head2 reverse

Bool.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Comparer-file_mtime>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Comparer-file_mtime>.

=head1 SEE ALSO

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

This software is copyright (c) 2024 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Comparer-file_mtime>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
