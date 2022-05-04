package Browser::Find::Windows;

use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-05-03'; # DATE
our $DIST = 'Browser-Find-Windows'; # DIST
our $VERSION = '0.002'; # VERSION

use Exporter qw(import);
our @EXPORT_OK = qw(find_browser list_browsers);

my @paths = (
    'C:/Program Files/Mozilla Firefox/firefox.exe',
    'C:/Program Files/Google/Chrome/Application/chrome.exe',
);

sub find_browser {
    for (@paths) { return $_ if -x $_ }
    return;
}

sub list_browsers {
    my @res;
    for (@paths) { push @res, $_ if -x $_ }
    @res;
}

1;
# ABSTRACT: Find available browser on Windows

__END__

=pod

=encoding UTF-8

=head1 NAME

Browser::Find::Windows - Find available browser on Windows

=head1 VERSION

This document describes version 0.002 of Browser::Find::Windows (from Perl distribution Browser-Find-Windows), released on 2022-05-03.

=head1 SYNOPSIS

 use Browser::Find::Windows qw(find_browser list_browsers);
 my $path = find_browser() or die "Can't find a browser";

 say for list_browsers();

=head1 DESCRIPTION

Preliminary version.

=head1 FUNCTIONS

=head2 find_browser

=head2 list_browsers

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Browser-Find-Windows>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Browser-Find-Windows>.

=head1 SEE ALSO

The B<start> command can also be used to open a URL or HTML page. This is
utilized by L<Browser::Open>.

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
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla plugin and/or Pod::Weaver::Plugin. Any additional steps required
beyond that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Browser-Find-Windows>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
