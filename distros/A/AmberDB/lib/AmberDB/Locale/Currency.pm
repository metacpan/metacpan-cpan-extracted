package AmberDB::Locale::Currency;

use 5.016;
use warnings;
use utf8;
use Carp qw(croak cluck);

our $VERSION = '5.25.1';
my $CREATED  = '2026-08-06';

# Master ISO 4217 Currency Dictionary
# Value objects: immutable, static, universal data.
my %CURRENCIES = (
    'TRY' => { num => '949', name => 'Turkish Lira',     symbol => '₺',    digits => 2 },
    'USD' => { num => '840', name => 'US Dollar',        symbol => '$',    digits => 2 },
    'EUR' => { num => '978', name => 'Euro',             symbol => '€',    digits => 2 },
    'GBP' => { num => '826', name => 'Pound Sterling',   symbol => '£',    digits => 2 },
    'RUB' => { num => '643', name => 'Russian Ruble',    symbol => '₽',    digits => 2 },
    'AZN' => { num => '944', name => 'Azerbaijani Manat',symbol => '₼',    digits => 2 },
    'SAR' => { num => '682', name => 'Saudi Riyal',      symbol => 'ر.س',  digits => 2 },
    'JPY' => { num => '392', name => 'Japanese Yen',     symbol => '¥',    digits => 0 },
    'CHF' => { num => '756', name => 'Swiss Franc',      symbol => 'CHF',  digits => 2 },
    'CAD' => { num => '124', name => 'Canadian Dollar',  symbol => 'CA$',  digits => 2 },
    'AUD' => { num => '036', name => 'Australian Dollar',symbol => 'A$',   digits => 2 },
    'CNY' => { num => '156', name => 'Chinese Yuan',     symbol => '¥',    digits => 2 },
);

my @CURRENCY_ORDER = qw(TRY USD EUR GBP RUB AZN SAR JPY CHF CAD AUD CNY);

# Get currency hash by 3-letter ISO code
# AmberDB::Locale::Currency->by_code('TRY') -> { num=>'949', name=>'Türk Lirası', symbol=>'₺', digits=>2 }
sub by_code {
    my ( $class_or_self, $code ) = @_;
    return unless defined $code;
    return $CURRENCIES{ uc($code) };
}

# Get currency symbol by ISO code
# AmberDB::Locale::Currency->symbol('TRY') -> '₺'
sub symbol {
    my ( $class_or_self, $code ) = @_;
    return '' unless defined $code;
    my $c = $CURRENCIES{ uc($code) };
    return $c ? $c->{symbol} : uc($code);
}

# Get currency name by ISO code
# AmberDB::Locale::Currency->name('TRY') -> 'Türk Lirası'
sub name {
    my ( $class_or_self, $code ) = @_;
    return '' unless defined $code;
    my $c = $CURRENCIES{ uc($code) };
    return $c ? $c->{name} : uc($code);
}

# Get all currencies as [ [$code, $name], ... ] for form selects/dropdowns
sub all {
    return map { [ $_, $CURRENCIES{$_}->{name} ] } @CURRENCY_ORDER;
}

# List active ISO codes
sub active_codes {
    return @CURRENCY_ORDER;
}

1;
