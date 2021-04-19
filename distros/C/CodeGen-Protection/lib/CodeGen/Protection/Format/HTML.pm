package CodeGen::Protection::Format::HTML;

# ABSTRACT: Safely rewrite parts of HTML documents

use Moo;
use Carp 'croak';
with 'CodeGen::Protection::Role';

our $VERSION = '0.05';

sub _tidy {
    my ( $self, $code ) = @_;
    return $code;    # we don't yet tidy
}

sub _start_marker_format {
    '<!-- %s %s. Do not touch any code between this and the end comment. Checksum: %s -->';
}

sub _end_marker_format {
    '<!-- %s %s. Do not touch any code between this and the start comment. Checksum: %s -->';
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

CodeGen::Protection::Format::HTML - Safely rewrite parts of HTML documents

=head1 VERSION

version 0.05

=head1 SYNOPSIS

    my $rewrite = CodeGen::Protection::Format::HTML->new(
        protected_code => $text,
    );
    say $rewrite->rewritten;

    my $rewrite = CodeGen::Protection::Format::HTML->new(
        existing_code => $existing_code,
        protected_code => $protected_code,
    );
    say $rewrite->rewritten;

=head1 DESCRIPTION

This module allows you to do a safe partial rewrite of documents. If you're
familiar with L<DBIx::Class::Schema::Loader>, you probably know the basic
concept.

Note that this code is designed for HTML documents and is not very
configurable.

In short, we wrap your "protected" (C<protected_code>) HTML code in start and
end comments, with checksums for the code:

    #<<< CodeGen::Protection::Format::HTML 0.01. Do not touch any code between this and the end comment. Checksum: fa97a021bd70bf3b9fa3e52f203f2660
    
    # protected HTML goes here

    #>>> CodeGen::Protection::Format::HTML 0.01. Do not touch any code between this and the start comment. Checksum: fa97a021bd70bf3b9fa3e52f203f2660

If C<existing_code> is provided, this module removes the code between the old
code's start and end markers and replaces it with the C<protected_code>. If
the code between the start and end markers has been altered, it will no longer
match the checksums and rewriting the code will fail.

=head1 AUTHOR

Curtis "Ovid" Poe <ovid@allaroundtheworld.fr>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Curtis "Ovid" Poe.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
