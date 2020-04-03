# -*- Mode: CPerl -*-
use Test::More;
use JSON;
use strict;
no strict qw(refs);

my $PKG = 'DDC::PP';
sub test_qcomments {
  my $pkg = shift;
  $PKG = $pkg if ($pkg);

  ${"${PKG}::COMPILER"} = "${PKG}::CQueryCompiler"->new() if (!${"${PKG}::COMPILER"});
  ok(defined(${"${PKG}::COMPILER"}), "defined(\$${PKG}::COMPILER)");
  ok(UNIVERSAL::can("${PKG}::CQueryCompiler",'setKeepLexerComments'), "${PKG}::CQueryCompiler->can(setKeepLexerComments)");

  ##-- test +lexer-comments (requires ddc >= v2.2.3)
  ${"${PKG}::COMPILER"}->setKeepLexerComments(1);
  ok(${"${PKG}::COMPILER"}->getKeepLexerComments, "\$${PKG}::COMPILER->getKeepLexerComments");
  ##
  testLexerComments("foo", []);
  testLexerComments("foo #[block comment]", ['#[block comment]']);
  testLexerComments("foo #:line comment\n", ["#:line comment\n"]);
  testLexerComments("foo #:line comment\n#[block comment]", ["#:line comment\n",'#[block comment]']);

  ##-- test -lexer-comments
  ${"${PKG}::COMPILER"}->setKeepLexerComments(0);
  ok(!${"${PKG}::COMPILER"}->getKeepLexerComments, "\! \$${PKG}::COMPILER->getKeepLexerComments");
  ##
  testLexerComments("foo", []);
  testLexerComments("foo #[block comment]", []);
  testLexerComments("foo #:line comment\n", []);
  testLexerComments("foo #:line comment\n#[block comment]", []);
}


#my $TEST_DIR = File::Basename::dirname($0);
sub testLexerComments {
  my ($qstr,$expect,$label) = @_;
  my $qobj = $PKG->parse($qstr);
  return undef if (!$qobj || !$qobj->getOptions);
  my $qcmts = $qobj->getOptions->getLexerComments;

  $label ||= "lexerComments(".JSON::to_json($qstr,{allow_nonref=>1}).") == " . JSON::to_json($expect);
  is_deeply($qobj->getOptions->getLexerComments, $expect, $label);
}

1; ##-- be happy
