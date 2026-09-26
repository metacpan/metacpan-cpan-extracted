#!perl
##----------------------------------------------------------------------------
## SQL API Abstraction - t/910.coverage.t
##----------------------------------------------------------------------------
BEGIN
{
    use lib './lib';
    use Test::More;
    unless( $ENV{AUTHOR_TESTING} || $ENV{RELEASE_TESTING} )
    {
        plan(skip_all => 'These tests are for author or release candidate testing');
    }
};

eval "use Test::Pod::Coverage 1.04; use Pod::Coverage::TrustPod;";
plan( skip_all => 'Test::Pod::Coverage 1.04 required for testing POD coverage' ) if( $@ );

my $params =
{
    coverage_class => 'Pod::Coverage::TrustPod',
    trustme => [qr/^(new|init|FREEZE|STORABLE_freeze|STORABLE_thaw|STORABLE_thaw_post_processing|THAW|TO_JSON)$/],
};

my %driver_for =
(
    'DB::Object::Mysql'    => 'DBD::mysql',
    'DB::Object::Postgres' => 'DBD::Pg',
    'DB::Object::SQLite'   => 'DBD::SQLite',
);

my %available;

foreach my $class ( keys( %driver_for ) )
{
    my $driver = $driver_for{ $class };

    $available{ $class } = eval( "require $driver; 1" ) ? 1 : 0;
}

my @modules = all_modules();

plan( tests => scalar( @modules ) );

foreach my $module ( @modules )
{
    SKIP:
    {
        foreach my $class ( keys( %driver_for ) )
        {
            next if( $module !~ /^\Q$class\E(?:::|$)/ );

            if( !$available{ $class } )
            {
                skip( "$driver_for{ $class } is not installed", 1 );
            }

            last;
        }

        pod_coverage_ok(
            $module,
            $params,
            "Pod coverage on $module",
        );
    }
}