package App::Codeowners::Formatter::JSON;
# ABSTRACT: Format codeowners output as JSON


use warnings;
use strict;

our $VERSION = '0.47'; # VERSION

use parent 'App::Codeowners::Formatter';

use App::Codeowners::Util qw(zip);


sub finish {
    my $self    = shift;
    my $results = shift;

    eval { require JSON::MaybeXS } or die "Missing dependency: JSON::MaybeXS\n";

    my %options;
    $options{pretty} = 1 if lc($self->format) eq 'pretty';

    my $json = JSON::MaybeXS->new(canonical => 1, utf8 => 1, %options);

    my $columns = $self->columns;
    $results = [map { +{zip @$columns, @$_} } @$results];
    print { $self->handle } $json->encode($results);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Codeowners::Formatter::JSON - Format codeowners output as JSON

=head1 VERSION

version 0.47

=head1 DESCRIPTION

This is a L<App::Codeowners::Formatter> that formats output using L<JSON::MaybeXS>.

=head1 ATTRIBUTES

=head2 format

If unset (default), the output will be compact. If "pretty", the output will look nicer to humans.

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
