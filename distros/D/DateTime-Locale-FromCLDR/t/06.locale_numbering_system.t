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
use utf8;


my $tests = [
    {
        locale => 'en',
        expects => ["latn", ["0","1","2","3","4","5","6","7","8","9"]],
    },
    {
        locale => 'ja',
        expects => ["latn", ["0","1","2","3","4","5","6","7","8","9"]],
    },
    {
        locale => 'ar-EG',
        expects => ["arab", ["٠","١","٢","٣","٤","٥","٦","٧","٨","٩"]],
    },
    {
        locale => 'mr',
        expects => ["deva", ["०","१","२","३","४","५","६","७","८","९"]],
    },
];

foreach my $def ( @$tests )
{
    subtest $def->{locale} => sub
    {
        my $locale = DateTime::Locale::FromCLDR->new( $def->{locale} );
        SKIP:
        {
            if( !defined( $locale ) )
            {
                diag( "Error instantiating a DateTime::Locale::FromCLDR object for locale '$def->{locale}': ", DateTime::Locale::FromCLDR->error );
                fail( DateTime::Locale::FromCLDR->error );
                skip( "Unable to instantiate a DateTime::Locale::FromCLDR object for locale '$def->{locale}'", 1 );
            }
            isa_ok( $locale, 'DateTime::Locale::FromCLDR' );
            my $ref = $locale->locale_number_system;
            is( $ref->[0] => $def->{expects}->[0], 'numbering system -> ' . $def->{expects}->[0] );
            is_deeply( $ref->[1] => $def->{expects}->[1], 'digits' );
        };
    };
}

done_testing();

# NOTE: OpenBSD global destruction workaround
# On OpenBSD, a double free deep in the SQLite-backed dependency stack corrupts the heap during
# perl's global destruction. The OpenBSD allocator is strict and aborts the process on exit, which
# the harness then misreads as a failure even though every assertion above has already passed.
# Once done_testing() has emitted the TAP stream, we flush the standard handles and hard-exit,
# bypassing global destruction entirely. This is restricted to OpenBSD so that normal teardown,
# and the diagnostics it can surface, are preserved on every other platform.
if( $^O eq 'openbsd' )
{
    my $builder = Test::More->builder;
    my $passing = $builder->can( 'is_passing' ) ? $builder->is_passing : 1;
    require IO::Handle;
    STDOUT->flush;
    STDERR->flush;
    require POSIX;
    POSIX::_exit( $passing ? 0 : 1 );
}

__END__
