package App::perlmv::scriptlet::remove_common_prefix;

use 5.010001;
use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-02-25'; # DATE
our $DIST = 'App-perlmv'; # DIST
our $VERSION = '0.605'; # VERSION

our $SCRIPTLET = {
    summary => 'Remove prefix that are common to all args, e.g. (file1, file2b) -> (1, 2b)',
    code => sub {
        package
            App::perlmv::code;
        use vars qw($COMMON_PREFIX $TESTING $FILES);

        if (!defined($COMMON_PREFIX) && !$TESTING) {
            my $i;
            for ($i=0; $i<length($FILES->[0]); $i++) {
                last if grep { substr($_, $i, 1) ne substr($FILES->[0], $i, 1) } @{$FILES}[1..@$FILES-1];
            }
            $COMMON_PREFIX = substr($FILES->[0], 0, $i);
        }

        s/^\Q$COMMON_PREFIX//;
        $_;
    },
};

1;

# ABSTRACT: Remove prefix that are common to all args, e.g. (file1, file2b) -> (1, 2b)

__END__

=pod

=encoding UTF-8

=head1 NAME

App::perlmv::scriptlet::remove_common_prefix - Remove prefix that are common to all args, e.g. (file1, file2b) -> (1, 2b)

=head1 VERSION

This document describes version 0.605 of App::perlmv::scriptlet::remove_common_prefix (from Perl distribution App-perlmv), released on 2022-02-25.

=head1 DESCRIPTION

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-perlmv>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-perlmv>.

=head1 SEE ALSO

L<perlmv> (from L<App::perlmv>)

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

This software is copyright (c) 2022, 2020, 2015, 2014, 2013, 2012, 2011, 2010 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-perlmv>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
