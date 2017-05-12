use Test::More qw/no_plan/;
use Test::Exception;
use strict;

use_ok( 'Data::LazyACL' );

basic();
a_lot();

sub basic {
    my $acl = Data::LazyACL->new();
    $acl->set_all_access_keys( [qw/edit insert view/] );
   
    is_deeply( $acl->get_all_access_keys() , [qw/edit insert view/] );
    
    my $token = $acl->generate_token([qw/edit insert/]);
    
    $acl->set_token( $token );
    
    ok(  $acl->has_privilege( 'edit'    ) ); 
    ok(  $acl->has_privilege( 'insert'  ) );
    ok( !$acl->has_privilege( 'view'    ) );
    ok( !$acl->has_privilege( 'admin'   ) );

    throws_ok( sub { $acl->has_privilege( 'boo' )  } , qr{can not find access key \[boo\]});
    
    my $admin_token =  $acl->generate_token([qw/edit admin/]);
    
    $acl->set_token( $admin_token );
    
    ok(  $acl->has_privilege( 'view' ) );
    
    throws_ok( sub { $acl->set_all_access_keys([qw/admin/]) } , qr{You can not use reserved word 'admin' as access key.} );

    my $keys = $acl->retrieve_access_keys_for( $token );

    ok( &any( $keys , 'edit'   ) );
    ok( &any( $keys , 'insert' ) );
    ok(!&any( $keys , 'view'   ) );
    ok(!&any( $keys , 'admin'  ) );

    my $keys_in_hash = $acl->retrieve_access_keys_in_hash_for( $token );

    ok( $keys_in_hash->{edit} );
    ok( $keys_in_hash->{insert} );
    ok( !$keys_in_hash->{view} );
    ok( !$keys_in_hash->{admin} );
    
    my $admin_key = $acl->retrieve_access_keys_for( $admin_token );
    
    ok( &any( $admin_key , 'admin' ) );
}

sub any {
    my $keys = shift;
    my $item = shift;
    foreach my $key ( @{ $keys } ) {
        return 1 if $item eq $key;
    }

    return 0;
}

sub a_lot {
    my $acl = Data::LazyACL->new();

    my @master = map { 'access_' . $_ } (0...10000);
    
    $acl->set_all_access_keys( \@master );

    my $token = $acl->generate_token( [qw/access_0 access_1/] );
    
    $acl->set_token( $token );
    ok(  $acl->has_privilege( 'access_0' ) );
    ok(  $acl->has_privilege( 'access_1' ) );
    ok(  !$acl->has_privilege( 'access_8941' ) );
    
}

