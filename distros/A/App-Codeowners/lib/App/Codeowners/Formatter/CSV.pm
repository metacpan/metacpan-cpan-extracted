package App::Codeowners::Formatter::CSV;
# ABSTRACT: Format codeowners output as comma-separated values


use warnings;
use strict;

our $VERSION = '0.43'; # VERSION

use parent 'App::Codeowners::Formatter';

use App::Codeowners::Util qw(stringify);
use Encode qw(encode);

sub start {
    my $self = shift;

    $self->text_csv->print($self->handle, $self->columns);
}

sub stream {
    my $self    = shift;
    my $result  = shift;

    $self->text_csv->print($self->handle, [map { encode('UTF-8', stringify($_)) } @$result]);
}


sub text_csv {
    my $self = shift;

    $self->{text_csv} ||= do {
        eval { require Text::CSV } or die "Missing dependency: Text::CSV\n";

        my %options;
        $options{escape_char} = $self->escape_char if $self->escape_char;
        $options{quote}       = $self->quote       if $self->quote;
        $options{sep}         = $self->sep         if $self->sep;
        if ($options{sep} && $options{sep} eq ($options{quote} || '"')) {
            die "Invalid separator value for CSV format.\n";
        }

        Text::CSV->new({binary => 1, eol => $/, %options});
    } or die "Failed to construct Text::CSV object";
}


sub sep         { $_[0]->{sep} || $_[0]->format }
sub quote       { $_[0]->{quote} }
sub escape_char { $_[0]->{escape_char} }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Codeowners::Formatter::CSV - Format codeowners output as comma-separated values

=head1 VERSION

version 0.43

=head1 DESCRIPTION

This is a L<App::Codeowners::Formatter> that formats output using L<Text::CSV>.

=head1 ATTRIBUTES

=head2 text_csv

Get the L<Text::CSV> instance.

=head2 sep

Get the value used for L<Text::CSV/sep>.

=head2 quote

Get the value used for L<Text::CSV/quote>.

=head2 escape_char

Get the value used for L<Text::CSV/escape_char>.

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
