#!perl
##----------------------------------------------------------------------------
## Lightweight DateTime Alternative - t/00.load.t
##----------------------------------------------------------------------------
use strict;
use warnings;
use lib './lib';
use Test::More;

BEGIN
{
    use_ok( 'DateTime::Lite' ) or BAIL_OUT( 'Cannot load DateTime::Lite' );
    use_ok( 'DateTime::Lite::Duration' );
    use_ok( 'DateTime::Lite::Exception' );
    use_ok( 'DateTime::Lite::Infinite' );
    use_ok( 'DateTime::Lite::PP' );
    use_ok( 'DateTime::Lite::TimeZone' );
}

diag( "Testing DateTime::Lite $DateTime::Lite::VERSION, Perl $], $^X" );
diag( "XS loaded: " . ( $DateTime::Lite::IsPurePerl ? "no (pure-Perl fallback)" : "yes" ) );

done_testing;

__END__
