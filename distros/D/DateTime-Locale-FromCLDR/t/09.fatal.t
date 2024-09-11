#!perl
BEGIN
{
    use strict;
    use warnings;
    use lib './lib';
    use open ':std' => ':utf8';
    use vars qw( $DEBUG );
    use utf8;
    use version;
    use Test::More;
    use DBD::SQLite;
    if( version->parse( $DBD::SQLite::sqlite_version ) < version->parse( '3.6.19' ) )
    {
        plan skip_all => 'SQLite driver version 3.6.19 or higher is required. You have version ' . $DBD::SQLite::sqlite_version;
    }
    our $DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
};

BEGIN
{
    use_ok( 'DateTime::Locale::FromCLDR' ) || BAIL_OUT( 'Unable to load DateTime::Locale::FromCLDR' );
};

use strict;
use warnings;

my $str = eval
{
    # no warnings 'DateTime::Locale::FromCLDR';
    local $SIG{__DIE__} = sub{};
    my $fmt = DateTime::Locale::FromCLDR->new( 'en', fatal => 1 );
    my $str = $fmt->format_gmt;
};
ok( !defined( $str ), "DateTime::Locale::FromCLDR->format_interval returned undef upon missing argument" );
ok( $@, "\$\@ is set." );
diag( "\$\@ is set to '", ( $@ // 'undef' ), "'" ) if( $DEBUG );
isa_ok( $@ => 'DateTime::Locale::FromCLDR::Exception', '$@ is a DateTime::Locale::FromCLDR::Exception object' );

done_testing();

__END__

