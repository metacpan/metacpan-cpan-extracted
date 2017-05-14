use Test::More;

use Data::Classifier::NaiveBayes::Tokenizer;

my $tokenizer = Data::Classifier::NaiveBayes::Tokenizer->new;

is_deeply $tokenizer->words("Hello World"), ['hello', 'world'];

$tokenizer->stemming(1);

is_deeply $tokenizer->words("Information Highway"), ['inform', 'highway'];

is_deeply $tokenizer->words("Information Highway", sub { return "foo" } ), ["foo","foo"];

done_testing;
