package App::perlmv::scriptlet::to_random_ext;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-08-04'; # DATE
our $DIST = 'App-perlmv-scriptlet-to_random'; # DIST
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;

our $SCRIPTLET = {
    summary => 'Rename to random characters, preserve extension',
    args => {
        # XXX len
    },
    code => sub {
        package
            App::perlmv::code;
        my $ext;
        if (/.+\.(.+)/) {$ext=$1} else {$ext=undef}
        join("", map {("a".."z")[26*rand()]} 1..8) . (defined $ext ? ".$ext" : "");
    },
};

1;

# ABSTRACT: Rename to random characters, preserve extension

__END__

=pod

=encoding UTF-8

=head1 NAME

App::perlmv::scriptlet::to_random_ext - Rename to random characters, preserve extension

=head1 VERSION

This document describes version 0.001 of App::perlmv::scriptlet::to_random_ext (from Perl distribution App-perlmv-scriptlet-to_random), released on 2020-08-04.

=head1 SYNOPSIS

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-perlmv-scriptlet-to_random>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-perlmv-scriptlet-to_random>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-perlmv-scriptlet-to_random>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<perlmv> (from L<App::perlmv>)

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
