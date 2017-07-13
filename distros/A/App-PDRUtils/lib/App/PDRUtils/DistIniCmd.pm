package App::PDRUtils::DistIniCmd;

our $DATE = '2017-07-10'; # DATE
our $VERSION = '0.11'; # VERSION

use 5.010001;
use strict;
use warnings;

our %common_args = (
    #dist_ini => {
    #    schema => 'str*',
    #    req => 1,
    #},
    parsed_dist_ini => {
        schema => ['obj*'],
        req => 1,
    },
);

1;
# ABSTRACT: Common stuffs for App::PDRUtils::DistIniCmd::*

__END__

=pod

=encoding UTF-8

=head1 NAME

App::PDRUtils::DistIniCmd - Common stuffs for App::PDRUtils::DistIniCmd::*

=head1 VERSION

This document describes version 0.11 of App::PDRUtils::DistIniCmd (from Perl distribution App-PDRUtils), released on 2017-07-10.

=head1 DESCRIPTION

A module under the L<App::PDRUtils::DistIniCmd> namespace represents a command
that modifies F<dist.ini>. It is passed a parsed F<dist.ini> in the form of
L<Config::IOD::Document> object and is expected to modify the object and return
status 200 (along with the object), or return 304 if nothing is modified. Result
(if there is an output) can be returned in the result metadata in
C<func.result> key).

A DistIniCmd can easily be turned into a SingleCmd or MultiCmd.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-PDRUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-PDRUtils>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-PDRUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017, 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
