use lib 't/lib';

use strict;
use warnings;

use Test::More;

use LibraryHelper;

BEGIN { require_ok 'Dallycot::Library::Linguistics' };

uses 'http://www.dallycot.net/ns/linguistics/1.0#';

isa_ok(Dallycot::Library::Linguistics->instance, 'Dallycot::Library');

my $result;

$result = run(q{stop-words("en")'});

is_deeply $result, String('a'), "'a' is the first stop word in English";

$result = run('language-classifier-languages');

isa_ok $result, 'Dallycot::Value::Vector', "language-classifier-languages is a vector";

if(defined $Lingua::YALI::LanguageIdentifier::VERSION) {
  $result = run('classify-text-language("The quick brown fox jumped over the lazy bear.")');

  is_deeply $result, String('en'), "Should return 'en' for English text";

  #$result = run('language-classify(classifier, <http://en.wikipedia.org/wiki/Project_Gutenberg>)');

  #is_deeply $result, String('en');

  #$result = run('language-classify(classifier, <http://es.wikipedia.org/wiki/Proyecto_Gutenberg>)');

  #is_deeply $result, String('es');
}

done_testing();
