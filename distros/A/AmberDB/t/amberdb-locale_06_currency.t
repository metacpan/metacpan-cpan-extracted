use strict;
use warnings;
use utf8;
use open ':std', ':utf8';
use Test::More;
binmode Test::More->builder->output,         ':utf8';
binmode Test::More->builder->failure_output, ':utf8';
binmode Test::More->builder->todo_output,    ':utf8';
use FindBin qw($Bin);
use lib "$Bin/../lib", 'lib';

use_ok('AmberDB::Locale::Currency');
use_ok('AmberDB::Locale');

subtest 'Master Registry (AmberDB::Locale::Currency)' => sub {
    my $loc = AmberDB::Locale->new('tr');
    is( $loc->utf_decode(AmberDB::Locale::Currency->cur_symbol('TRY')), '₺', 'TRY symbol is ₺' );
    is( $loc->utf_decode(AmberDB::Locale::Currency->cur_symbol('USD')), '$', 'USD symbol is $' );
    is( $loc->utf_decode(AmberDB::Locale::Currency->cur_symbol('EUR')), '€', 'EUR symbol is €' );
    is( $loc->utf_decode(AmberDB::Locale::Currency->cur_symbol('GBP')), '£', 'GBP symbol is £' );
    is( $loc->utf_decode(AmberDB::Locale::Currency->cur_symbol('AZN')), '₼', 'AZN symbol is ₼' );

    my $try_data = AmberDB::Locale::Currency->by_code('TRY');
    is( $try_data->{num}, '949', 'TRY ISO num is 949' );
    is( $try_data->{name}, 'Turkish Lira', 'TRY name' );

    my @all = AmberDB::Locale::Currency->all();
    ok( scalar(@all) >= 4, 'Currency->all returns list' );
    is( $all[0]->[0], 'TRY', 'First currency code is TRY' );
};

subtest 'AmberDB::Locale format_currency with Master Registry' => sub {
    my $tr = AmberDB::Locale->new('tr');
    is( $tr->format_currency(1234.56), '₺1.234,56', 'TR default format_currency' );
    is( $tr->format_currency(1234.56, 'USD'), '$1.234,56', 'TR format USD using master registry symbol $' );

    my $de = AmberDB::Locale->new('de');
    is( $de->format_currency(1234.56), '1.234,56 €', 'DE suffix EUR format' );
    is( $de->format_currency(1234.56, 'TRY'), '1.234,56 ₺', 'DE format TRY with German suffix rule' );
};

done_testing();
