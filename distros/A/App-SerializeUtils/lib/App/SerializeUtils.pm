package App::SerializeUtils;

use 5.010001;
use strict;
use warnings;

our $VERSION = '0.13'; # VERSION

1;
# ABSTRACT: Utilities for serialization tasks

__END__

=pod

=encoding UTF-8

=head1 NAME

App::SerializeUtils - Utilities for serialization tasks

=head1 VERSION

This document describes version 0.13 of App::SerializeUtils (from Perl distribution App-SerializeUtils), released on 2017-05-23.

=head1 SYNOPSIS

 $ script-that-produces-json | json2yaml

=head1 DESCRIPTION

This distributions provides the following command-line utilities related to
serialization:

=over

=item * L<check-json>

=item * L<check-phpser>

=item * L<check-yaml>

=item * L<dd2ddc>

=item * L<dd2json>

=item * L<dd2phpser>

=item * L<dd2sereal>

=item * L<dd2storable>

=item * L<dd2yaml>

=item * L<json2dd>

=item * L<json2ddc>

=item * L<json2phpser>

=item * L<json2sereal>

=item * L<json2storable>

=item * L<json2yaml>

=item * L<phpser2dd>

=item * L<phpser2ddc>

=item * L<phpser2json>

=item * L<phpser2sereal>

=item * L<phpser2storable>

=item * L<phpser2yaml>

=item * L<pp-dd>

=item * L<pp-json>

=item * L<pp-yaml>

=item * L<sereal2dd>

=item * L<sereal2ddc>

=item * L<sereal2json>

=item * L<sereal2phpser>

=item * L<sereal2storable>

=item * L<sereal2yaml>

=item * L<serializeutils-convert>

=item * L<storable2dd>

=item * L<storable2ddc>

=item * L<storable2json>

=item * L<storable2phpser>

=item * L<storable2sereal>

=item * L<storable2yaml>

=item * L<yaml2dd>

=item * L<yaml2ddc>

=item * L<yaml2json>

=item * L<yaml2phpser>

=item * L<yaml2sereal>

=item * L<yaml2storabls>

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-SerializeUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-SerializeUtils>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-SerializeUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Data::Dump>

L<JSON>

L<PHP::Serialization>

L<Sereal>

L<Storable>

L<YAML>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017, 2015, 2014, 2013, 2011 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
