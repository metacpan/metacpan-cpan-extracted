# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)
BEGIN { $| = 1; print "1..8\n"; } END {print "not ok 1\n" unless $loaded;} 
use AltaVista::SDKLinguistics qw(avsl_thesaurus_init avsl_thesaurus_get avsl_thesaurus_close 
				avsl_phrase_init avsl_phrase_get avsl_phrase_close
				avsl_stem_init avsl_stem_get avsl_stem_close
				avsl_spell_init avsl_spellcheck_get avsl_spellcorrection_get avsl_spell_close);
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

$phrase_config = "phrase_config.txt";
$spell_config = "spell_config.txt";
$stem_config = "stem_config.txt";
$thesaurus_config = "thesaurus_config.txt";


$handle = avsl_thesaurus_init($thesaurus_config);
print "avsl_thesaurus_init() ", ($handle != 0) ? "ok" : "NOT ok", "\n";

$language = "ENGLISH";
$word = "car";
$expected = "automobile auto vehicle van sedan";
$test = "thesaurus";
$actual = avsl_thesaurus_get($handle, $word, $language);
print "test=:$test:, language=:$language:, results=";
if ($actual ne $expected)
	{ print "NOT "; }
print "ok\n\tword:$word:\n\tactual:$actual:\n\texpected:$expected:\n";

$language = "ENGLISH";
$word = "avs";
$expected = " AltaVista";
$test = "thesaurus user dictionary";
$actual = avsl_thesaurus_get($handle, $word, $language);
print "test=:$test:, language=:$language:, results=";
if ($actual ne $expected)
	{ print "NOT "; }
print "ok\n\tword:$word:\n\tactual:$actual:\n\texpected:$expected:\n";

print "avsl_thesaurus_close()", (avsl_thesaurus_close($handle) == 0) ? " ok" : " NOT ok","\n";



$handle = avsl_phrase_init($phrase_config);
print "avsl_phrase_init() ", ($handle != 0) ? "ok" : "NOT ok", "\n";

$language = "ENGLISH";
$word = "i love new york";
$expected = "new york";
$test = "phrase";
$actual = avsl_phrase_get($handle, $word, $language);
print "test=:$test:, language=:$language:, results=";
if ($actual ne $expected)
	{ print "NOT "; }
print "ok\n\tword:$word:\n\tactual:$actual:\n\texpected:$expected:\n";


$language = "ENGLISH";
$word = "i love rock and roll";
$expected = "rock and roll";
$test = "phrase user dictionary";
$actual = avsl_phrase_get($handle, $word, $language);
print "test=:$test:, language=:$language:, results=";
if ($actual ne $expected)
	{ print "NOT "; }
print "ok\n\tword:$word:\n\tactual:$actual:\n\texpected:$expected:\n";

print "avsl_phrase_close()", (avsl_phrase_close($handle) == 0) ? " ok" : " NOT ok","\n";


$handle = avsl_stem_init($stem_config, "parts_of_speech.txt");
print "avsl_stem_init() ", ($handle != 0) ? "ok" : "NOT ok", "\n";

$language = "ENGLISH";
$word = "skating";
$expected = "skate skated skates skating";
$test = "stem";
$actual = avsl_stem_get($handle, $word, $language);
print "test=:$test:, language=:$language:, results=";
if ($actual ne $expected)
	{ print "NOT "; }
print "ok\n\tword:$word:\n\tactual:$actual:\n\texpected:$expected:\n";


$language = "ENGLISH";
$word = "asdfs";
$expected = "asdf asdfed asdfs asdfing";
$test = "stem user dictionary";
$actual = avsl_stem_get($handle, $word, $language);
print "test=:$test:, language=:$language:, results=";
if ($actual ne $expected)
	{ print "NOT "; }
print "ok\n\tword:$word:\n\tactual:$actual:\n\texpected:$expected:\n";

print "avsl_stem_close()", (avsl_stem_close($handle) == 0) ? " ok" : " NOT ok","\n";

print "ABOUT TO call avsl_spell_init\n";

$handle = avsl_spell_init($spell_config);

print "COMPLETED the call avsl_spell_init\n";

print "avsl_spell_init() ", ($handle != 0) ? "ok" : "NOT ok", "\n";

$language = "ENGLISH";
$word = "mispelledd";
$expected = "mispelledd";
print "ABOUT TO call avsl_spellcheck_get\n";
$test = "avsl_spellcheck_get";
$actual = avsl_spellcheck_get($handle, $word, $language);
print "test=:$test:, language=:$language:, results=";
if ($actual ne $expected)
	{ print "NOT "; }
print "ok\n\tword:$word:\n\tactual:$actual:\n\texpected:$expected:\n";

$language = "asdf";
$word = "misspelledd";
$expected = "";
$test = "avsl_spellcheck_get BAD language";
$actual = avsl_spellcheck_get($handle, $word, $language);
print "test=:$test:, language=:$language:, results=";
if ($actual ne $expected)
	{ print "NOT "; }
print "ok\n\tword:$word:\n\tactual:$actual:\n\texpected:$expected:\n";

$language = "ENGLISH";
$word = "misspelledd";
$expected = "misspelled";
$test = "avsl_spellcorrection_get";
$actual = avsl_spellcorrection_get($handle, $word, $language);
print "test=:$test:, language=:$language:, results=";
if ($actual ne $expected)
	{ print "NOT "; }
print "ok\n\tword:$word:\n\tactual:$actual:\n\texpected:$expected:\n";

$language = "asdf";
$word = "misspelledd";
$expected = "";
$test = "avsl_spellcorrection_get BAD language";
$actual = avsl_spellcorrection_get($handle, $word, $language);
print "test=:$test:, language=:$language:, results=";
if ($actual ne $expected)
	{ print "NOT "; }
print "ok\n\tword:$word:\n\tactual:$actual:\n\texpected:$expected:\n";

print "avsl_spell_close()", (avsl_spell_close($handle) == 0) ? " ok" : " NOT ok","\n";


