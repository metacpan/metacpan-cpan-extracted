use utf8;
use strict;
use warnings;
use charnames qw( :full );
use open qw( :encoding(UTF-8) :std );
use Test::More tests => 60;
use Test::Warn;
use CLDR::Number;

my $cldr = CLDR::Number->new;
my $decf = $cldr->decimal_formatter;
my $perf = $cldr->percent_formatter;
my $curf = $cldr->currency_formatter(currency_code => 'EUR');

$decf->locale('en');
is $decf->format(5.0),              '5';
is $decf->format(0),                '0';
is $decf->format(.5),               '0.5';
is $decf->format(.05),              '0.05';
is $decf->format(.005),             '0.005';
is $decf->format(50_000.05),        '50,000.05';
is $decf->format(5_000_000.05),     '5,000,000.05';
is $decf->format(5_000_000_000.05), '5,000,000,000.05';
is $decf->format(-50_000.05),       '-50,000.05';

$decf->locale('fr');
is $decf->format(5.0),              '5';
is $decf->format(0),                '0';
is $decf->format(.5),               '0,5';
is $decf->format(.05),              '0,05';
is $decf->format(.005),             '0,005';
is $decf->format(50_000.05),        '50 000,05';
is $decf->format(5_000_000.05),     '5 000 000,05';
is $decf->format(5_000_000_000.05), '5 000 000 000,05';
is $decf->format(-50_000.05),       '-50 000,05';

$decf->locale('ar');
is $decf->format(-50.0),   "\N{RIGHT-TO-LEFT MARK}-٥٠";
is $decf->format(-50_000), "\N{RIGHT-TO-LEFT MARK}-٥٠٬٠٠٠";
is $decf->format(-50.05),  "\N{RIGHT-TO-LEFT MARK}-٥٠٫٠٥";
is $decf->format(-.05),    "\N{RIGHT-TO-LEFT MARK}-٠٫٠٥";

$decf->locale('en-IN');
is $decf->format(1_23_456),    '1,23,456';
is $decf->format(1_23_45_678), '1,23,45,678';

warning_is {
    is $decf->format(undef), undef, 'decimal format when undef';
} 'Use of uninitialized value in CLDR::Number::Format::Decimal::format';

warning_is {
    is $decf->at_least(undef), undef, 'decimal at_least when undef';
} 'Use of uninitialized value in CLDR::Number::Format::Decimal::at_least';

warning_is {
    is $decf->range(undef, 1), undef, 'decimal range when A is undef';
} 'Use of uninitialized value in CLDR::Number::Format::Decimal::range';

warning_is {
    is $decf->range(1, undef), undef, 'decimal range when B is undef';
} 'Use of uninitialized value in CLDR::Number::Format::Decimal::range';

warning_is {
    my $perf = $cldr->percent_formatter;
    is $perf->format(undef), undef, 'percent format when undef';
} 'Use of uninitialized value in CLDR::Number::Format::Percent::format';

warning_is {
    my $curf = $cldr->currency_formatter(currency_code => 'EUR');
    is $curf->format(undef), undef, 'currency format when undef';
} 'Use of uninitialized value in CLDR::Number::Format::Currency::format';

$decf->locale('it');
$perf->locale('it');
$curf->locale('it');

warning_is {
    is $decf->format('X'), '0', 'decimal format when not num';
} q{Argument "X" isn't numeric in CLDR::Number::Format::Decimal::format};

warning_is {
    is $decf->format('1.5X'), '1,5', 'decimal format when not all num';
} q{Argument "1.5X" isn't numeric in CLDR::Number::Format::Decimal::format};

warning_is {
    is $decf->at_least('X'), '⩾0', 'decimal at_least when not num';
} q{Argument "X" isn't numeric in CLDR::Number::Format::Decimal::at_least};

warning_is {
    is $decf->at_least('1.5X'), '⩾1,5', 'decimal at_least when not all num';
} q{Argument "1.5X" isn't numeric in CLDR::Number::Format::Decimal::at_least};

warning_is {
    is $decf->range('A', 5), '0-5', 'decimal range when A not num';
} q{Argument "A" isn't numeric in CLDR::Number::Format::Decimal::range};

warning_is {
    is $decf->range(5, 'B'), '5-0', 'decimal range when B not num';
} q{Argument "B" isn't numeric in CLDR::Number::Format::Decimal::range};

warnings_are {
    is $decf->range('A', 'B'), '0-0', 'decimal range when both not num';
} [
    q{Argument "A" isn't numeric in CLDR::Number::Format::Decimal::range},
    q{Argument "B" isn't numeric in CLDR::Number::Format::Decimal::range},
];

warnings_are {
    is $decf->range('5X', '10X'), '5-10', 'decimal range when both not all num';
} [
    q{Argument "5X" isn't numeric in CLDR::Number::Format::Decimal::range},
    q{Argument "10X" isn't numeric in CLDR::Number::Format::Decimal::range},
];

warning_is {
    is $perf->format('X'), '0%', 'percent format when not num';
} q{Argument "X" isn't numeric in CLDR::Number::Format::Percent::format};

warning_is {
    is $perf->format('1.5X'), '150%', 'percent format when not all num';
} q{Argument "1.5X" isn't numeric in CLDR::Number::Format::Percent::format};

warning_is {
    is $curf->format('X'), '0,00 €', 'currency format when not num';
} q{Argument "X" isn't numeric in CLDR::Number::Format::Currency::format};

warning_is {
    is $curf->format('1.5X'), '1,50 €', 'currency format when not all num';
} q{Argument "1.5X" isn't numeric in CLDR::Number::Format::Currency::format};
