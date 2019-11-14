package App::Codeowners::Formatter::Table;
# ABSTRACT: Format codeowners output as a table


use warnings;
use strict;

our $VERSION = '0.43'; # VERSION

use parent 'App::Codeowners::Formatter';

use App::Codeowners::Util qw(stringify);
use Encode qw(encode);

sub finish {
    my $self    = shift;
    my $results = shift;

    eval { require Text::Table::Any } or die "Missing dependency: Text::Table::Any\n";

    my $table = Text::Table::Any::table(
        header_row  => 1,
        rows        => [$self->columns, map { [map { stringify($_) } @$_] } @$results],
        backend     => $ENV{PERL_TEXT_TABLE},
    );
    print { $self->handle } encode('UTF-8', $table);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Codeowners::Formatter::Table - Format codeowners output as a table

=head1 VERSION

version 0.43

=head1 DESCRIPTION

This is a L<App::Codeowners::Formatter> that formats output using L<Text::Table::Any>.

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
