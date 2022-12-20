use v5.10;
use strict;
use warnings;
use utf8;

use Test::More;
use Data::Localize;
use Data::Localize::Format::Maketext;

my $loc = Data::Localize->new();

$loc->add_localizer(
	class => 'YAML',
	path => 't/array_lexicons/*.yaml',
	formatter => Data::Localize::Format::Maketext->new,
	array_key_value => [qw(key msg)],
);

subtest 'translating using Data::Localize' => sub {
	foreach my $data (
		[pl => 'Lepszy wróbel w garści, niż gołąb na dachu test.'],
		[en => 'A bird in the hand is worth two in the bush test.']
		)
	{
		my ($lang, $trans) = @$data;

		$loc->set_languages($lang);
		is($loc->localize('saying', 'test'), $trans, "$lang ok");
	}
};

done_testing;

