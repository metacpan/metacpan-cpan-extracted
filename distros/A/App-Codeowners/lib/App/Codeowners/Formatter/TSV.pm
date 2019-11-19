package App::Codeowners::Formatter::TSV;
# ABSTRACT: Format codeowners output as tab-separated values


use warnings;
use strict;

our $VERSION = '0.47'; # VERSION

use parent 'App::Codeowners::Formatter::CSV';

sub sep { "\t" }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Codeowners::Formatter::TSV - Format codeowners output as tab-separated values

=head1 VERSION

version 0.47

=head1 DESCRIPTION

This is a L<App::Codeowners::Formatter::CSV> that formats output using L<Text::CSV>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/chazmcgarvey/git-codeowners/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Charles McGarvey <chazmcgarvey@brokenzipper.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Charles McGarvey.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
