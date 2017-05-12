use utf8;
use strict;
use warnings;
use open qw( :encoding(UTF-8) :std );
use Test::More tests => 31;
use CLDR::Number;
use CLDR::Number::Data::Base;

my $cldr = new_ok 'CLDR::Number' => [locale => 'zh'], 'CLDR::Number';
is $cldr->locale, 'zh', 'generator locale set on instantiation';

$cldr->locale('ja');
is $cldr->locale, 'ja', 'generator locale updated';

is $cldr->version, $CLDR::Number::VERSION,
    'version attribute matches $VERSION';
is $cldr->version, $CLDR::Number::Data::Base::VERSION,
    'version attribute matches data $VERSION';
is $cldr->cldr_version, $CLDR::Number::Data::Base::CLDR_VERSION,
    'cldr_version attribute matches data $CLDR_VERSION';

my $decf = $cldr->decimal_formatter;
isa_ok $decf, 'CLDR::Number::Format::Decimal';
is $decf->locale, 'ja', 'generator locale passed to formatter';

$decf->locale('ko');
is $decf->locale, 'ko', 'formatter locale updated';
is $cldr->locale, 'ja', 'generator locale remains the same';

$cldr->locale('vi');
is $cldr->locale, 'vi', 'generator locale updated';
is $decf->locale, 'ko', 'formatter locale remains the same';

$decf = $cldr->decimal_formatter(
    locale                  => 'en',
    minimum_integer_digits  => 2,
    maximum_integer_digits  => 3,
    minimum_fraction_digits => 1,
    maximum_fraction_digits => 2,
    primary_grouping_size   => 2,
    secondary_grouping_size => 1,
    minimum_grouping_digits => 2,
    rounding_increment      => 2,
);

is $decf->minimum_integer_digits,  2, 'min int spared by locale on create';
is $decf->maximum_integer_digits,  3, 'max int spared by locale on create';
is $decf->minimum_fraction_digits, 1, 'min frac spared by locale on create';
is $decf->maximum_fraction_digits, 2, 'max frac spared by locale on create';
is $decf->primary_grouping_size,   2, '1st group spared by locale on create';
is $decf->secondary_grouping_size, 1, '2nd group spared by locale on create';
is $decf->minimum_grouping_digits, 2, 'min group spared by locale on create';
is $decf->rounding_increment,      2, 'rounding spared by locale on create';

$decf = $cldr->decimal_formatter(
    locale  => 'en',
    pattern => '00.0#',
);

is $decf->pattern,   '00.0#', 'pattern spared by locale on create';
is $decf->format(5), '05.0',  'pattern spared by locale on create';

my $perf = $cldr->percent_formatter;
my $curf = $cldr->currency_formatter;

ok !$cldr->can('has'),   'generator: has should not be inherited';
ok !$decf->can('has'),   'decimal: has should not be inherited';
ok !$perf->can('has'),   'percent: has should not be inherited';
ok !$curf->can('has'),   'currency: has should not be inherited';
ok !$cldr->can('croak'), 'generator: croak should not be inherited';
ok !$decf->can('croak'), 'decimal: croak should not be inherited';
ok !$perf->can('croak'), 'percent: croak should not be inherited';
ok !$curf->can('croak'), 'currency: croak should not be inherited';
ok !$decf->can('looks_like_number'), 'looks_like_number should not be inherited';
