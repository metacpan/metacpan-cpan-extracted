# -*- Mode: CPerl -*-
use Test::More;

#use lib qw(../blib/lib ../blib/arch);
use lib qw(.);
use DDC::XS;
use JSON;

#my $TEST_DIR = File::Basename::dirname($0);
sub testLexerComments {
  my ($qstr,$expect,$label) = @_;
  my $qobj = DDC::XS->parse($qstr);
  return undef if (!$qobj || !$qobj->getOptions);
  my $qcmts = $qobj->getOptions->getLexerComments;

  $label ||= "lexerComments(".JSON::to_json($qstr,{allow_nonref=>1}).") == " . JSON::to_json($expect);
  is_deeply($qobj->getOptions->getLexerComments, $expect, $label);
}


$DDC::XS::COMPILER = DDC::XS::CQueryCompiler->new() if (!$DDC::XS::COMPILER);
ok(defined($DDC::XS::COMPILER), "defined(\$DDC::XS::COMPILER)");
ok(UNIVERSAL::can($DDC::XS::COMPILER,'setKeepLexerComments'), "\$DDC::XS::COMPILER->can(setKeepLexerComments)");

##-- test +lexer-comments (requires ddc >= v2.2.3)
$DDC::XS::COMPILER->setKeepLexerComments(1);
ok($DDC::XS::COMPILER->getKeepLexerComments, "\$DDC::XS::COMPILER->getKeepLexerComments");
##
testLexerComments("foo", []);
testLexerComments("foo #[block comment]", ['#[block comment]']);
testLexerComments("foo #:line comment\n", ["#:line comment\n"]);
testLexerComments("foo #:line comment\n#[block comment]", ["#:line comment\n",'#[block comment]']);

##-- test -lexer-comments
$DDC::XS::COMPILER->setKeepLexerComments(0);
ok(!$DDC::XS::COMPILER->getKeepLexerComments, "\! \$DDC::XS::COMPILER->getKeepLexerComments");
##
testLexerComments("foo", []);
testLexerComments("foo #[block comment]", []);
testLexerComments("foo #:line comment\n", []);
testLexerComments("foo #:line comment\n#[block comment]", []);


done_testing();
