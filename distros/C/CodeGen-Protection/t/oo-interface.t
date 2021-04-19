#!/usr/bin/env perl

use lib 'lib', 't/lib';
use Test::Most;
use Test::CodeGen::Helpers;
use CodeGen::Protection::Format::Perl;

my $sample = <<'END';
sub sum {
    my $total = 0;
    $total += $_ foreach @_;
    return $total;
}
END

ok my $rewrite = CodeGen::Protection::Format::Perl->new(
    protected_code => $sample,
    identifier     => 'test'
  ),
  'We should be able to create a rewrite object without old text';

my $expected = update_version(<<'END');
#<<< CodeGen::Protection::Format::Perl 0.01. Do not touch any code between this and the end comment. Checksum: fa97a021bd70bf3b9fa3e52f203f2660

sub sum {
    my $total = 0;
    $total += $_ foreach @_;
    return $total;
}

#>>> CodeGen::Protection::Format::Perl 0.01. Do not touch any code between this and the start comment. Checksum: fa97a021bd70bf3b9fa3e52f203f2660
END

my $rewritten = $rewrite->rewritten;
is_multiline_text $rewritten, $expected,
  '... and we should get our rewritten Perl back with start and end markers';

# saving this for use later
my $full_document_with_before_and_after_text
  = "this is before\n$expected\nthis is after";

$rewritten = "before\n\n$rewritten\nafter";

my $protected_code = <<'END';
    class Foo {
        has $x;
    }
END

ok $rewrite = CodeGen::Protection::Format::Perl->new(
    existing_code  => $rewritten,
    protected_code => $protected_code,
    identifier     => 'test',
  ),
  'We should be able to rewrite the old Perl with new Perl, but leaving "outside" areas unchanged';

$expected = update_version(<<'END');
before

#<<< CodeGen::Protection::Format::Perl 0.01. Do not touch any code between this and the end comment. Checksum: 2cd05888383961c3a8032c7622d4cf19

    class Foo {
        has $x;
    }

#>>> CodeGen::Protection::Format::Perl 0.01. Do not touch any code between this and the start comment. Checksum: 2cd05888383961c3a8032c7622d4cf19

after
END
$rewritten = $rewrite->rewritten;
is_multiline_text $rewritten, $expected, '... and get our new text as expected';

my ( $old, $new ) = ( $rewritten, $full_document_with_before_and_after_text );
ok $rewrite = CodeGen::Protection::Format::Perl->new(
    existing_code  => $rewritten,
    protected_code => $full_document_with_before_and_after_text,
    identifier     => 'test',
  ),
  'We should be able to rewrite a document with a "full" new document, only extracting the rewrite portion of the new document.';
$rewritten = $rewrite->rewritten;

$expected = update_version(<<'END');
before

#<<< CodeGen::Protection::Format::Perl 0.01. Do not touch any code between this and the end comment. Checksum: fa97a021bd70bf3b9fa3e52f203f2660

sub sum {
    my $total = 0;
    $total += $_ foreach @_;
    return $total;
}

#>>> CodeGen::Protection::Format::Perl 0.01. Do not touch any code between this and the start comment. Checksum: fa97a021bd70bf3b9fa3e52f203f2660

after
END

is_multiline_text $rewritten, $expected,
  '... and see only the part between checksums is replaced';

$old
  =~ s/CodeGen::Protection::Format::Perl 0.01/CodeGen::Protection::Format::Perl 1.02/g;

ok $rewrite = CodeGen::Protection::Format::Perl->new(
    existing_code  => $old,
    protected_code => $new,
  ),
  'The version number of CodeGen::Protection::Format::Perl should not matter when rewriting code;';
$rewritten = $rewrite->rewritten;

is_multiline_text $rewritten, $expected,
  '... and see only the part between checksums is replaced';

$new = <<'END';
    sub foo {
          my ($bar   ) = @_  ;
          return $bar +  
          1;
        }
END
ok $rewrite = CodeGen::Protection::Format::Perl->new(
    existing_code  => $old,
    protected_code => $new,
    tidy           => 1,
  ),
  'The version number of CodeGen::Protection::Format::Perl should not matter when rewriting code;';
$rewritten = $rewrite->rewritten;

$expected = update_version(<<'END');
before

#<<< CodeGen::Protection::Format::Perl 0.01. Do not touch any code between this and the end comment. Checksum: 85aac48abc051a44c83bf11122764e1f

    sub foo {
        my ($bar) = @_;
        return $bar + 1;
    }

#>>> CodeGen::Protection::Format::Perl 0.01. Do not touch any code between this and the start comment. Checksum: 85aac48abc051a44c83bf11122764e1f

after
END

is_multiline_text $rewritten, $expected,
  'We should be able to tidy our code before it gets wrapped in start/end markers';

done_testing;
