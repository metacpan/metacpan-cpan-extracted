package CodeGen::Protection;

# ABSTRACT: Safely rewrite parts of generated code

use v5.08.0;
use strict;
use warnings;
use base 'Exporter';
use Module::Runtime qw( use_module );
use Carp 'croak';
use CodeGen::Protection::Types qw(
  compile_named
  NonEmptyStr
  Bool
  Optional
);

our $VERSION = '0.06';
our @EXPORT_OK = qw(
  create_protected_code
  rewrite_code
);
our %EXPORT_TAGS = ( all => \@EXPORT_OK );

{
    my $check = compile_named(
        type           => NonEmptyStr,
        protected_code => NonEmptyStr,
        tidy           => Optional [Bool],
        name           => Optional [NonEmptyStr],
        overwrite      => Optional [Bool],
    );

    sub create_protected_code {
        return _rewritten( $check->(@_) );
    }
}

{
    my $check = compile_named(
        type           => NonEmptyStr,
        protected_code => NonEmptyStr,
        existing_code  => NonEmptyStr,
        tidy           => Optional [Bool],
        name           => Optional [NonEmptyStr],
        overwrite      => Optional [Bool],
    );

    sub rewrite_code {
        return _rewritten( $check->(@_) );
    }
}

sub _rewritten {
    my $arg_for = shift;
    my $type    = delete $arg_for->{type};
    my $class   = _use_module($type);
    return $class->new($arg_for)->rewritten;
}

sub _use_module {
    my $format = shift;
    my $class  = "CodeGen::Protection::Format::$format";
    use_module($class);
    return $class;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

CodeGen::Protection - Safely rewrite parts of generated code

=head1 VERSION

version 0.06

=head1 SYNOPSIS

    use CodeGen::Protection qw(:all);

    # Creating a new document:

    my $perl = create_protected_code(
        type           => 'Perl',
        protected_code => $sample,
    );

    # Or rewriting:

    my $rewritten = rewrite_code(
        type           => 'Perl',
        existing_code  => $perl,
        protected_code => $rewritten_code,
    );

=head1 DESCRIPTION

If this is hard to follow, you might find the
L<Tutorial|CodeGen::Protection::Tutorial> useful.

Code that writes code can be a powerful tool, especially when you need to
generate lots of boilerplate. However, when a developer takes the generated
code, they can easily rewrite that code in a way that no longer works, or make
good changes that get wiped out if the code is regenerated.
L<DBIx::Class::Schema::Loader|https://metacpan.org/pod/DBIx::Class::Schema::Loader>
protects against this by marking blocks of code with start and end comments
and an MD5 checksum. If you change any of the code between those comments,
regenerating your schema will fail.

This module takes this idea and generalizes it. It allows you to do a safe
partial rewrite of documents. At the present time, we support Perl and HTML.

In short, we wrap your "protected" (C<protected_code>) code in start and end
comments, with checksums for the code:

    #<<< CodeGen::Protection::Format::Perl 0.01. Do not touch any code between this and the end comment. Checksum: fa97a021bd70bf3b9fa3e52f203f2660
    
    # protected code goes here

    #>>> CodeGen::Protection::Format::Perl 0.01. Do not touch any code between this and the start comment. Checksum: fa97a021bd70bf3b9fa3e52f203f2660

Or:

    <!-- CodeGen::Protection::Format::HTML 0.01. Do not touch any code between this and the end comment. Checksum: c286b9b2577e085df857227eae996c40 -->
    
        <ol>
          <li>This is a list</li>
          <li>This is the second entry.</li>
        </ol>
    
    <!-- CodeGen::Protection::Format::HTML 0.01. Do not touch any code between this and the start comment. Checksum: c286b9b2577e085df857227eae996c40 -->

If calling the C<rewrite_code> function, this module removes the code between
the C<existing_code>'s start and end markers and replaces it with the
C<protected_code>. If the code between the start and end markers has been
altered, it will no longer match the checksums and rewriting the code will
fail.

=head1 TYPES

As of this writing, we can protect Perl and HTML:

    my $rewritten = rewrite_code(
        type           => 'Perl',
        existing_code  => $perl,
        protected_code => $protected_code,
    );

    my $rewritten = rewrite_code(
        type           => 'HTML',
        existing_code  => $HTML,
        protected_code => $protected_code,
    );

See L<CodeGen::Protection::Role> to learn how to create your own types to protect.

=head1 FUNCTIONS

Functions are exportable on-demand, or both can be exported via C<:all>.

    use CodeGen::Protection qw(rewrite_code);
    use CodeGen::Protection qw(:all);

=head2 C<create_protected_code>

    my $protected_code = create_protected_code(
        type           => 'Perl',
        protected_code => $text_of_code,
    );

Takes the code in C<$text_of_code> and adds start and end markers to it.

=head2 C<rewrite_code>

    my $protected_code = create_protected_code(
        type           => 'Perl',
        protected_code => $protected_code,
        existing_code  => $existing_code,
    );

Replaces the code in the protected block of C<$existing_code> with the code
from C<$protected_code>.

=head3 ARGUMENTS

Both C<create_protected_code> and C<rewrite_code> take the same arguments,
except that C<rewrite_code> does not allow the C<protected_code> argument.

=over 4

=item * C<protected_code>

This is a required string containing any new Perl code to be built with this
tool.

=item * C<existing_code>

This is an optional string containing Perl code  already built with this tool.
If provided, this code I<must> have the start and end markers generated by
this tool so that the rewriter knows the section of code to replace with the
injected code.

=item * C<name>

Optional name for the code. This is only used in error messages if you're
generating a lot of code and an error occurs and you'd like to see the name
in the error.

=item * C<tidy>

If true, will attempt to tidy the C<protected_code> block (the rest of the
code is ignored).  For Perl, if the value of perltidy is the number 1 (one),
then a generic pass of L<Perl::Tidy> will be done on the code. If the value is
true and anything I<other> than one, this is assumed to be the path to a
F<.perltidyrc> file and that will be used to tidy the code (or C<croak()> if
the F<.perltidyrc> file cannot be found).

=item * C<overwrite>

Optional boolean, default false. In "Rewrite mode", if the checksum in the
start and end markers doesn't match the code within them, someone has manually
altered that code and we do not automatically overwrite it (in fact, we
C<croak()>). Setting C<overwrite> to true will cause it to be overwritten.

=back

=head1 MODES

There are two modes: "Creation" and "Rewrite."

=head2 Creation Mode

    my $protected_code = create_protected_code(
        protected_code => $text,
    );

This will wrap the new text in start and end tags that "protect" the document
if you rewrite it:

    my $perl = <<'END';
    sub sum {
        my $total = 0;
        $total += $_ foreach @_;
        return $total;
    }
    END
    my $protected_code = create_protected_code( protected_code => $perl );

Result:

    #<<< CodeGen::Protection::Format::Perl 0.03. Do not touch any code between this and the end comment. Checksum: fa97a021bd70bf3b9fa3e52f203f2660

    sub sum {
        my $total = 0;
        $total += $_ foreach @_;
        return $total;
    }

    #>>> CodeGen::Protection::Format::Perl 0.03. Do not touch any code between this and the start comment. Checksum: fa97a021bd70bf3b9fa3e52f203f2660

You can then take the marked up document and insert it into another Perl
document and use the rewrite mode to safely rewrite the code between the start
and end markers. The rest of the document will be ignored.

Note that leading and trailing comments start with C<< #<<< >> and C<< #>>> >>
respectively. Those are special comments which tell L<Perl::Tidy> to ignore
what ever is between them. Thus, you can safely tidy code written with this.

The start and end checksums are the same and are the checksum of the text
between the comments. Leading and trailing lines which are all whitespace are
removed and one leading and one trailing newline will be added.

=head2 Rewrite Mode

Given a document created with the "Creating" mode, you can then take the
marked up document and insert it into another Perl document and use the
rewrite mode to safely rewrite the code between the start and end markers.
The rest of the document will be ignored.

    my $rewrite = rewrite_code(
        existing_code  => $existing_code,
        protected_code => $protected_code,
    );

In the above, assuming that C<$existing_code> is a rewritable document, the
C<$protected_code> will replace the rewritable section of the C<$existing_code>, leaving
the rest unchanged.

However, if C<$protected_code> is I<also> a rewritable document, then the rewritable
portion of the C<$protected_code> will be extract and used to replace the rewritable
portion of the C<$existing_code>.

So for the code shown in the "Creation mode" section, you could add more code
like this:

    package My::Package;

    use strict;
    use warnings;

    sub average {
        return sum(@_)/@_;
    }

    #<<< CodeGen::Protection::Format::Perl 0.03. Do not touch any code between this and the end comment. Checksum: fa97a021bd70bf3b9fa3e52f203f2660

    sub sum {
        my $total = 0;
        $total += $_ foreach @_;
        return $total;
    }

    #>>> CodeGen::Protection::Format::Perl 0.03. Do not touch any code between this and the start comment. Checksum: fa97a021bd70bf3b9fa3e52f203f2660
    
    1;

However, later on I might realize that the C<sum> function will happily try to
sum things which are not numbers, so I want to fix that. I'll slurp the
C<My::Package> code into the C<$existing_code> variable and then:

    my $perl = <<'END';
    use Scalar::Util 'looks_like_number';

    sub sum {
        my $total = 0;
        foreach my $number (@_) {
            unless (looks_like_number($number)) {
                die "'$number' doesn't look like a numbeer!";
            }
            $total += $number;
        }
        return $total;
    }
    END
    my $rewrite = rewrite_code( existing_code => $existing_code, protected_code => $perl );

And that will result in:

    package My::Package;
    
    use strict;
    use warnings;
    
    sub average {
        return sum(@_)/@_;
    }
    
    #<<< CodeGen::Protection::Format::Perl 0.03. Do not touch any code between this and the end comment. Checksum: d135a051f158ee19fbd68af5466fb1ae
    
    use Scalar::Util 'looks_like_number';
    
    sub sum {
        my $total = 0;
        foreach my $number (@_) {
            unless (looks_like_number($number)) {
                die "'$number' doesn't look like a numbeer!";
            }
            $total += $number;
        }
        return $total;
    }
    
    #>>> CodeGen::Protection::Format::Perl 0.03. Do not touch any code between this and the start comment. Checksum: d135a051f158ee19fbd68af5466fb1ae
    
    1;

You can see that the code between the start and end checksum comments and been
rewritten, while the rest of the code remains unchanged.

=head1 ACKNOWLEDGEMENTS

We would like to thank L<All Around the World|https://allaroundtheworld.fr/>

Thanks to Matt Trout (mst) for the inspiration from the schema loader.
for sponsoring this work.

=head1 AUTHOR

Curtis "Ovid" Poe <ovid@allaroundtheworld.fr>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Curtis "Ovid" Poe.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
