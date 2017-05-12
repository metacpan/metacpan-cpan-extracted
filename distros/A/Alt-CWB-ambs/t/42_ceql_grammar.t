# -*-cperl-*-
## Test various parts of standard CWB::CEQL grammar

use Test::More tests => 82;
use CWB::CEQL;

our $grammar = new CWB::CEQL;
isa_ok($grammar, "CWB::CEQL"); # T1

## basic tests for wildcard patterns
check_query('ordinary', "literal_string", # T2
            'ordinary');
check_query('me\ta".?\"meta', "literal_string",
            'meta\"\.\?\"meta');
check_query('ord\inary\,', "wildcard_pattern",
            '"ordinary,"');
check_query('inter+', "wildcard_pattern",
            '"inter.+"');
check_query('[over,under]estimate[d,]', "wildcard_pattern",
            '"(over|under)estimate(d)?"');
check_query('part[,ed,,s]', "wildcard_pattern",
            '"part(ed|s)?"');
check_query('aa[b\*,c\+,\[[a+,b+,]\]]aa', "wildcard_pattern",
            '"aa(b\*|c\+|\[(a.+|b.+)?\])aa"');
check_query('\u\L-\L-\u\L', "wildcard_pattern",
            '"[A-Z][a-z]+-[a-z]+-[A-Z][a-z]+"');
check_error('ab[,]ba', "wildcard_pattern", # T10
            qr/empty list of alternatives/);
check_error('no\\\\good', "wildcard_pattern",
            qr/literal backslash/);
check_error('also_no_good\\', "wildcard_pattern",
            qr/end in a backslash/);
check_error('one,two,three', "wildcard_pattern",
            qr/alternatives.*within brackets/);
check_error('aa[cd,e[fg,h],aa', "wildcard_pattern",
            qr/bracketing.*balanced.*opening/);
check_error('aa[cd,e[fg,]h,]]aa', "wildcard_pattern",
            qr/bracketing.*balanced.*closing/);

## POS tags and simple POS
check_query('NN*', "pos_tag",       # T16
            'pos="NN.*"');
$grammar->SetParam("pos_attribute", "tag");
check_query('VV[INF,FIN]', "pos_tag",
            'tag="VV(INF|FIN)"');
$grammar->SetParam("pos_attribute", "pos");
check_error('N', "simple_pos",
            qr/no simple.*tags.*available/);
$grammar->SetParam("simple_pos", { # -- example from CEQL manpage
                                  "N" => "NN.*", # common nouns
                                  "V" => "V.*",  # any verb forms
                                  "A" => "JJ.*", # adjectives
                                 });
check_query('N', "simple_pos",
            'pos="NN.*"');
check_error('Noun', "simple_pos",
            qr/not.*simple.*tag.*available.* A N V/);
check_query('NN[S,]', "pos_constraint",
            'pos="NN(S)?"');
check_query('{V}', "pos_constraint",
            'pos="V.*"');
check_error('{N', "pos_constraint",
            qr/lonely curly brace/);

check_query('[over,under]+tion', "word_or_lemma_constraint", # T24
            'word="(over|under).+tion"%c');
check_query('Bath:C', "word_or_lemma_constraint",
            'word="Bath"');
$grammar->SetParam("default_ignore_case", 0);
check_query('Bath', "word_or_lemma_constraint",
            'word="Bath"');
$grammar->SetParam("default_ignore_case", 1);
check_query('DEJA:Cd', "word_or_lemma_constraint",
            'word="DEJA"%d');
check_query('{sing}', "word_or_lemma_constraint",
            'lemma="sing"%c');
check_query('{I}:C', "word_or_lemma_constraint",
            'lemma="I"');
check_query('{\A-\A}:d', "word_or_lemma_constraint",
            'lemma="[A-Za-z]+-[A-Za-z]+"%cd');
check_query('one\:two', "word_or_lemma_constraint",
            'word="one:two"%c');
check_error('Bath:x', "word_or_lemma_constraint",
            qr/invalid flag/);
check_error('{Bath:C', "word_or_lemma_constraint",
            qr/lonely.*brace.*lemma/);
check_error('{[under,over]]estimate}', "word_or_lemma_constraint",
            qr/bracketing.*not balanced/);
$grammar->SetParam("lemma_attribute", undef);
check_error('{sing}', "word_or_lemma_constraint",
            qr/lemmatisation.*not available/);
$grammar->SetParam("lemma_attribute", "lemma");

check_query('Bath:c', "token_expression", # T36
            '[word="Bath"%c]');
check_query('drives_{N}', "token_expression",
            '[word="drives"%c & pos="NN.*"]');
check_query('{light}:C_NNS', "token_expression",
            '[lemma="light" & pos="NNS"]');
check_query('drives_', "token_expression",
            '[word="drives"%c]');
check_query('_AJS', "token_expression",
            '[pos="AJS"]');
check_query('*_AJS', "token_expression",
            '[pos="AJS"]');
check_query('*_', "token_expression",
            '[word=".*"%c]');
check_query('file\_path_NP', "token_expression",
            '[word="file_path"%c & pos="NP"]');
check_error('file_path_NP', "token_expression",
            qr/only.*single.*separator/);
check_error('_', "token_expression",
            qr/neither word form nor part-of-speech/);

check_query('pretty', "phrase_query", # T46
            '[word="pretty"%c]');
check_query('pretty young girl', "phrase_query",
            '[word="pretty"%c] [word="young"%c] [word="girl"%c]');
check_query('[the,this] _{A} {girl}:C', "phrase_query",
            '[word="(the|this)"%c] [pos="JJ.*"] [lemma="girl"]');
check_query('(the|this) girl', "phrase_query",
            '([word="the"%c] | [word="this"%c]) [word="girl"%c]');
check_query('the ((_RB*)? _{A})* girl', "phrase_query",
            '[word="the"%c] (([pos="RB.*"])? [pos="JJ.*"])* [word="girl"%c]');
check_query('(_DT){0,1}(_{A}){2,}(_NN*){1}', "phrase_query",
            '([pos="DT"]){0,1} ([pos="JJ.*"]){2,} ([pos="NN.*"]){1}');
check_query('<s> \L:C', "phrase_query",
            '<s> [word="[a-z]+"]');
check_error('girl|boy', "phrase_query",
            qr/alternatives sep.*within parentheses/);
check_error('(girl||boy)', "phrase_query",
            qr/empty alternative/);
check_error('(girl|boy|)', "phrase_query",
            qr/empty alternative/);
check_error('the ()+ girl', "phrase_query",
            qr/must not be empty/);
check_error('this (_{A})** girl', "phrase_query",
            qr/invalid quantifier/);
check_error('this (_{A}){,42} girl', "phrase_query",
            qr/invalid quantifier/);
check_error('the (_RB*)? _{A})* girl', "phrase_query",
            qr/bracketing.*not balanced.*closing/);
check_error('(', "phrase_query",
            qr/bracketing.*not balanced.*opening/);
check_error('one </> two', "phrase_query",
            qr/syntax error.*XML tag/);
check_error('<head> News:C', "phrase_query",
            qr/invalid XML tag/);

check_query('cat <<5>> dog', "proximity_query", # T63
            'MU(meet [word="cat"%c] [word="dog"%c] -5 5)');
check_query('bucket <<2,5<< {kick}:C', "proximity_query",
            'MU(meet [word="bucket"%c] [lemma="kick"] -5 -2)');
check_query('{cat}_N*<<s>>{dog}_N*', "proximity_query",
            'MU(meet [lemma="cat"%c & pos="N.*"] [lemma="dog"%c & pos="N.*"] s)');
check_query('spite <<1<<in >>1>>of', "proximity_query",
            'MU(meet (meet [word="spite"%c] [word="in"%c] -1 -1) [word="of"%c] 1 1)');
check_query('in spite of', "proximity_query",
            'MU(meet (meet [word="in"%c] [word="spite"%c] 1 1) [word="of"%c] 2 2)');
check_query('{kick}:C_V* <<s>> the bucket', "proximity_query",
            'MU(meet [lemma="kick" & pos="V.*"] (meet [word="the"%c] [word="bucket"%c] 1 1) s)');
check_query('{love}_V* <<s>> (cats <<3>> dogs)', "proximity_query",
            'MU(meet [lemma="love"%c & pos="V.*"] (meet [word="cats"%c] [word="dogs"%c] -3 3) s)');
check_error('cat <<-5>> dog', "proximity_query",
            qr/neither.*numeric.*nor.*structural/);
check_error('cat >>s>> dog', "proximity_query",
            qr/structural.*must be two-sided/);
check_error('cat <<document>> dog', "proximity_query",
            qr/supported structures.*<<s>>/);
check_error('<<s>> cat dog', "proximity_query",
            qr/expected token expression/);
check_error('cat dog <<s>>', "proximity_query",
            qr/expected another term/);
check_error('cat <<3<< >>5>> dog', "proximity_query",
            qr/distance operator not allowed/);
check_error('(cat <<3>> dog) <<s>> ()', "proximity_query",
            qr/empty subexpression/);
check_error('cat <<3,5>> dog', "proximity_query",
            qr/range.*not allowed.*two-sided/);

# final tests check auto-detection of proximity vs. phrase queries
check_query('[the,this] _{A} {girl}:C', "ceql_query", # T78
            '[word="(the|this)"%c] [pos="JJ.*"] [lemma="girl"]');
check_query('(_DT){0,1}(_{A}){2,}(_NN*){1}', "default",
            '([pos="DT"]){0,1} ([pos="JJ.*"]){2,} ([pos="NN.*"]){1}');
check_query('<s> \L:C', "ceql_query",
            '<s> [word="[a-z]+"]');
check_query('bucket <<2,5<< {kick}:C', "ceql_query",
            'MU(meet [word="bucket"%c] [lemma="kick"] -5 -2)');
check_query('{kick}:C_V* <<s>> the bucket', "ceql_query",
            'MU(meet [lemma="kick" & pos="V.*"] (meet [word="the"%c] [word="bucket"%c] 1 1) s)');

# -- 82 tests

## helper routines for testing automatic translation results
sub check_query {
  my ($query, $rule, $expected) = @_;
  my $msg = "parse ``$query'' as $rule";
  my $result = $grammar->Parse($query, $rule);
  if (defined $result) {
    is($result, $expected, $msg);
  }
  else {
    fail($msg);
    foreach ($grammar->ErrorMessage) { diag($_) };
  }
}

sub check_error {
  my ($query, $rule, $err_regexp) = @_;
  my $msg = "find syntax error in ``$query'' as $rule";
  my $result = $grammar->Parse($query, $rule);
  if (defined $result) {
    fail($msg);
  }
  else {
    like(join("\n",$grammar->ErrorMessage), $err_regexp, $msg);
  }
}
