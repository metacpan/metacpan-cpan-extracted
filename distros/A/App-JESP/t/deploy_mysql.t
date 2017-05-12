#! perl -w

use Test::Most;
BEGIN{
    eval "use Test::mysqld";
    plan skip_all => "Test::mysqld is required for this test" if $@;
    eval "use Net::EmptyPort";
    plan skip_all => "Net::EmptyPort is required for this test" if $@;
}

use App::JESP;

# Test deployment in SQLite
# use Log::Any::Adapter qw/Stderr/;

# Then something with MySQL
my $mysqld = eval{ Test::mysqld->new( my_cnf => {
    'skip-networking' => '1',
    socket => File::Spec->catfile( File::Spec->tmpdir() , 'socket-'.$$.'-testmysqld')
}) } or plan skip_all => $Test::mysqld::errstr;

my @mysqls = ( $mysqld );

if( $ENV{EXTENDED_TESTING} ){
    # Other flavours of Test::mysqld
    push @mysqls , Test::mysqld->new( my_cnf => { port => Net::EmptyPort::empty_port() } );
}

foreach my $mysql ( @mysqls ){
    # A home that is there.
    my $jesp = App::JESP->new({ dsn => $mysql->dsn(),
                                password => '',
                                username => '',
                                home => './t/home_mysql/'
                            });
    throws_ok(sub{ $jesp->deploy() } , qr/ERROR querying meta/ );

    # Time to install
    $jesp->install();
    # And deploy
    is( $jesp->deploy(), 2, "Ok applied 2 patches");
    is( $jesp->deploy(), 0, "Ok applied 0 patches on the second call");
}

done_testing();
