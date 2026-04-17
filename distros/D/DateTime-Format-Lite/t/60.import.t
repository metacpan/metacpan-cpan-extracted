# -*- perl -*-
##----------------------------------------------------------------------------
## DateTime Format Lite - t/60.import.t
##----------------------------------------------------------------------------
use strict;
use warnings;
use lib './lib';
use utf8;
use Test::More qw( no_plan );

use_ok( 'DateTime::Format::Lite', qw( strptime strftime ) ) or BAIL_OUT( 'Cannot load DateTime::Format::Lite' );
use_ok( 'DateTime::Lite' ) or BAIL_OUT( 'Cannot load DateTime::Lite' );

# NOTE: strptime export
subtest 'strptime export' => sub
{
    my $dt = strptime( '%Y', '2026' );
    ok( defined( $dt ), 'strptime returned a defined value' );
    is( $dt->year, 2026, 'year is 2026' );
};

# NOTE: strftime export
subtest 'strftime export' => sub
{
    my $dt = DateTime::Lite->new( year => 2026, month => 4, day => 15 );
    my $result = strftime( '%Y-%m-%d', $dt );
    is( $result, '2026-04-15', 'strftime returned correct string' );
};

# NOTE: strptime returns undef on parse failure (default on_error is 'undef')
subtest 'strptime returns undef on parse failure' => sub
{
    my $warning = '';
    local $SIG{__WARN__} = sub{ $warning = join( '', @_ ) };
    my $result = strptime( '%Y', 'not-a-year' );
    ok( !defined( $result ), 'strptime returns undef for unparseable input' );
};

done_testing();

__END__
