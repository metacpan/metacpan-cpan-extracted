#! perl -w

use Test::More;

use App::JIRAPrint;

{
    my $j = App::JIRAPrint->new({ config_files => [ 't/config1.conf' ,  't/config2.conf' ] });
    is_deeply( $j->config() , { foo => [ 'bar1' , 'bar2' ], bla => 'from2'  } );
    is( $j->config_place() , 'in config files: '.join(', ' , @{[ 't/config1.conf',  't/config2.conf'] } ) );
    is( $j->config()->{bla} , 'from2' );
}

{
    my $j = App::JIRAPrint->new({ config => {} });
    is( $j->config_place() , 'in memory config' );
}

{
    my $j = App::JIRAPrint->new({ config_files => [ 't/fullconfig.conf' ]});
    ok( $j->config() );
    ok( $j->url() );
    ok( $j->username() );
    ok( $j->password() );
    ok( $j->project() );
    ok( $j->sprint() );
    ok( $j->jql() );
    is_deeply( $j->fields() , [ 'a', 'b' ]);
    is( $j->maxissues() , 314 );
}


done_testing();

