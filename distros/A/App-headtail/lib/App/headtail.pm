package App::headtail;

use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-12-27'; # DATE
our $DIST = 'App-headtail'; # DIST
our $VERSION = '0.001'; # VERSION

sub run {
    my %opts = @_;

    if (defined $opts{lines}) {
        my (@first, @last);

        while (<>) {
            push @first, $_ unless @first >= $opts{lines};
            push @last , $_; shift @last if @last > $opts{lines};
        }

        if ($. < @first + @last) {
            splice @last, 0, (@first + @last) - $.;
        }

        print for @first;
        print for @last;

    } else {
        die;
    }
}


1;
# ABSTRACT: head+tail

__END__

=pod

=encoding UTF-8

=head1 NAME

App::headtail - head+tail

=head1 VERSION

This document describes version 0.001 of App::headtail (from Perl distribution App-headtail), released on 2023-12-27.

=head1 SYNOPSIS

See the command-line script L<headtail>.

=for Pod::Coverage ^(.+)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-headtail>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-headtail>.

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

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-headtail>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
