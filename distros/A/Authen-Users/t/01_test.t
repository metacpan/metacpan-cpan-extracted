#!/usr/bin/perl

use Test::More tests => 17;

BEGIN { use_ok( 'Authen::Users' ); }

my $db_name = 'test';

    # Test if we have Mysql
    SKIP:
    {
	    eval "require DBD::MySQL;";
        skip "No DBD::MySQL", 8 if $@;
        skip "Win32 MySQL testing issues", 8 if($^O =~ /MSWin32/i);
        my $auth = new Authen::Users( dbtype => 'MySQL', 
        	dbname => $db_name, dbuser => 'user', # dbpass => 'testing', 
        	create => 1 );
		isa_ok ($auth, 'Authen::Users');
        ok($auth->is_in_table('test', 'user') or $auth->add_user('test', 'user', 'pw', 'My User', 'user@sql.org', 'my dog?', 'Fido'),
        	"Add user");
        ok($auth->is_in_table('test', 'user2') or $auth->add_user('test', 'user2', 'pw2', 'My User', 'user@sql.org', 'my dog?', 'Fido'),
        	"Add second user");
        isnt($auth->add_user('test', 'user2', 'pw2', 'My User', 'user@sql.org', 'my dog?', 'Fido'),
        	"Add second user TWICE, should fail");        	
        ok($auth->authenticate('test', 'user', 'pw'), "Authenticate user");
        ok($auth->count_group('test') == 2, 'Count group');
        ok($auth->delete_user('test', 'user2'), 'Delete user');
        ok($auth->count_group('test') == 1, 'Count group after delete');
    }
    
    # test SQLite also
    SKIP:
    {
	    eval "require DBD::SQLite;";
        skip "No DBD::SQLite", 8 if $@;
        # remove temp SQLite db
        unlink $db_name if -e $db_name;
        my $auth = new Authen::Users( dbtype => 'SQLite', 
        	dbname => $db_name, create => 1 );
		isa_ok ($auth, 'Authen::Users');
        ok($auth->add_user('test', 'user', 'pw', 'My User', 'user@sql.org', 'my dog?', 'Fido'),
        	"Add user");
        ok($auth->add_user('test', 'user2', 'pwd2', 'My User', 'user@sql.org', 'my dog?', 'Fido'),
        	"Add second user");
        isnt($auth->add_user('test', 'user2', 'pw2', 'My User', 'user@sql.org', 'my dog?', 'Fido'),
        	"Add second user TWICE, should fail");        	
        ok($auth->authenticate('test', 'user', 'pw'), "Authenticate user");
        ok($auth->count_group('test') == 2, 'Count group');
        ok($auth->delete_user('test', 'user2'), 'Delete user');
        ok($auth->count_group('test') == 1, 'Count group after delete');
    }
