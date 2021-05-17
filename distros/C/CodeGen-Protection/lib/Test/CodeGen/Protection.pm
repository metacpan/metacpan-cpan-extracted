package Test::CodeGen::Protection;

# ABSTRACT: Test functions for generated files

use strict;
use warnings;

use Test::Builder::Module;
use CodeGen::Protection qw(rewrite_code);
use Module::Runtime qw(use_module);
our @ISA    = qw(Test::Builder::Module);
our @EXPORT = qw(
  is_protected_document_ok
  is_protected_file_ok
);


sub is_protected_document_ok ($$;$) {
    my ( $format, $code, $message ) = @_;
    my $tb = Test::CodeGen::Protection->builder;
    eval {
        rewrite_code(
            type           => $format,
            existing_code  => $code,
            protected_code => 'my $x = 1;',
        );
        1;
    };
    if ( my $error = $@ ) {
        $tb->ok( 0, $message );
        $tb->diag($error);
        return;
    }
    $tb->ok( 1, $message );
}


sub is_protected_file_ok ($$;$) {
    my ( $format, $file, $message ) = @_;
    my $tb = Test::CodeGen::Protection->builder;
    my $code;
    eval {
        open my $fh, '<', $file or die "Cannot open '$file' for reading: $!";
        $code = do { local $/; <$fh> };
    };
    if ( my $error = $@ ) {
        $tb->ok( 0, $message );
        $tb->diag($error);
        return;
    }
    is_protected_document_ok $format, $code, $message;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::CodeGen::Protection - Test functions for generated files

=head1 VERSION

version 0.06

=head2 C<is_protected_document_ok($format, $code, $message)>

    is_protected_document_ok 'Perl', $string, $message;

This test will pass if C<$string> is a document that matches the following
conditions:

=over 4

=item * Has start and end L<CodeGen::Protection> markers

=item * The start and end checksums match

=item * The text within the start and end markers matches the checksums

=back

=head2 C<is_protected_file_ok($format, $filename, $message)>

    is_protected_file_ok 'HTML', $filename, $message;

Like C<is_protected_document_ok>, but accepts a filename. Will fail under the
same conditions.

=head1 AUTHOR

Curtis "Ovid" Poe <ovid@allaroundtheworld.fr>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Curtis "Ovid" Poe.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
