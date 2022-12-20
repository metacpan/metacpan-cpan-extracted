use v5.10;
use strict;
use warnings;
use utf8;

use Test::More;
use Data::Localize::YAML;

my $loc = Data::Localize::YAML->new(
	path => 't/array_lexicons/*.yaml',
	array_key_value => [qw(key msg)],
);

subtest 'basic translations' => sub {
	foreach my $data ([pl => 'Polski'], [en => 'English']) {
		my ($lang, $trans) = @$data;
		is($loc->get_lexicon($lang => 'language'), $trans, "$lang ok");
	}
};

subtest 'special letters' => sub {
	foreach my $data ([pl => 'zażółć gęślą jaźń ZAŻÓŁĆ GĘŚLĄ JAŹŃ'], [en => 'none']) {
		my ($lang, $trans) = @$data;
		is($loc->get_lexicon($lang => 'special letters'), $trans, "$lang ok");
	}
};

done_testing;

