use strict;
use warnings;

# which loads Bread::Board containers lazily from files
use Test::More;
use Test::Exception;
use t::Utils qw(clear_history file_loaded);

BEGIN {
    use_ok( 'Bread::Board::LazyLoader', 'load_container' );
}

subtest 'Simple container with one root' => sub {

    my $root_file     = 't/data/core/Root.ioc';
    my $database_file = 't/data/core/Database.ioc';
    my $webapp_file   = 't/data/core/Webapp.ioc';

    clear_history();
    my $c = load_container(
        root_dir => ['t/data/core'],
        filename_extension   => 'ioc',
    );
    is_deeply( [ sort  $c->get_sub_container_list ],
        [ sort 'Database', 'Webapp', 'NoCoderef' ], 'The sub containers are "loaded in list"' );

    ok( file_loaded($root_file),      "Root container loaded" );
    ok( !file_loaded($database_file), "Database container not loaded" );
    ok( !file_loaded($webapp_file),   "Webapp container not loaded" );

    my $root_package = $c->fetch('package')->get;
    like( $root_package, qr{Bread::Board::LazyLoader::Sandbox::\d+::t_2fdata_2fcore_2fRoot_2eioc}, 'Root file is evaled in special package');

    my $db = $c->fetch('Database');
    ok( file_loaded($database_file), "Database container not loaded");

    throws_ok {
        $c->fetch('NoCoderef')
    }
    qr{Evaluation of file 't/data/core/NoCoderef.ioc' did not return a coderef},
        "There is no sub in file";
};

subtest 'Different container name' => sub {
    clear_history();

    # Database is used as root
    my $c = load_container(
        root_dir           => ['t/data/core'],
        filename_extension => 'ioc',
        container_name     => 'Database',
    );
    ok( !file_loaded('t/data/core/Root.ioc'),    "Root container not loaded");
    ok( file_loaded('t/data/core/Database.ioc'), "Database.ioc loaded");

    my $db = $c->fetch('Root');
    ok( file_loaded('t/data/core/Root.ioc'),    "Root container loaded");
};

subtest 'container factory' => sub {
    clear_history();

    my $container_factory_called;
    my $c = load_container(
        root_dir          => ['t/data/core'],
        filename_extension => 'ioc',
        container_factory => sub {
            my ($name) = @_;

            $container_factory_called = $name;
            my $c = Bread::Board::Container->new( name => $name );
            $c->add_service(
                Bread::Board::Literal->new( name => 'marker', value => 101 )
            );
            return $c;
        }
    );

    my $database_container = $c->fetch('Database');
    ok(!$container_factory_called, "Container factory not called yet");

    my $webapp_container = $c->fetch('Webapp');
    is($container_factory_called, 'Webapp', 'Container Webapp was created by container_factory');
};

subtest 'Different extension' => sub {
    clear_history();
    my $c = load_container(
        root_dir           => ['t/data/core'],
        filename_extension => 'bb',
    );
    ok( file_loaded('t/data/core/Root.bb'), "Root.bb container loaded" );
    ok( !file_loaded('t/data/core/Root.ioc'),
        "Root.ioc container not loaded"
    );
    dies_ok { !$c->fetch('Database') } 'Other files are ignored';
    dies_ok { !$c->fetch('Webapp') } 'Dirs with no bb files are ignored too';
};

subtest 'Core and site together' => sub {
    clear_history();

    my $c = load_container(
        root_dir           => ['t/data/site', 't/data/core'],
        filename_extension => 'ioc',
    );

    is($c->fetch('core_present')->get, 1, 'Core creates the container');
    is($c->fetch('site_present')->get, 1, 'Site adds into container');
    is($c->fetch('source')->get, 'site_root', 'Site can overwrite some services in the core');

    is_deeply( [ sort  $c->get_sub_container_list ],
        [ sort 'Database', 'Webapp', 'NoCoderef', 'Rating' ], 'The sub containers comes from both site and core' );

    ok( !file_loaded('t/data/site/Database.ioc'),
        "Site Database.ioc container not loaded yet"
    );
	
    my $db_container = $c->fetch('Database');
    ok( file_loaded('t/data/site/Database.ioc'),
        "Site Database.ioc container loaded"
    );
    ok( !file_loaded('t/data/core/Database.ioc'),
        "Core Database.ioc file never to be loaded"
    );
};

done_testing();
