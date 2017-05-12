#!/usr/bin/perl

use strict;
use warnings;

use Data::Dumper;

our $ONLINE;

BEGIN {
    $ONLINE = $ENV{password};
}

use Test::More tests => $ONLINE ? 42 : 40;

my $test_host = $ENV{host} || 'ultrasam.ru';

ok(1, 'Test OK');
use_ok('API::ISPManager');

$a = 'refs';

is( refs( undef ),   '',       $a);
is( refs( {} ),      'HASH',   $a );
is( refs( [] ),      'ARRAY',  $a );
is( refs( sub {} ),  'CODE',   $a );
is( refs( \$a ),     'SCALAR', $a );

$a = 'is_success';

ok(! is_success(), $a);
ok(! is_success( { error => {}, data => {} } ), $a);
ok(  is_success( { data  => {} } ), $a);
ok(! is_success( { } ), $a);

$a = 'get_data';

ok(! get_data(), $a);
ok(! get_data( { } ), $a);
ok(! get_data( { error => {}, data => {} } ), $a);
is_deeply(  get_data( { data => { aaa => 'bbb' } } ), { aaa => 'bbb' }, $a);

$a = 'filter_hash';
is_deeply( API::ISPManager::filter_hash( {  }, [ ]), {}, $a );
is_deeply( API::ISPManager::filter_hash( { aaa => 555, bbb => 111 }, [ 'aaa' ]), { aaa => 555 }, $a );
is_deeply( API::ISPManager::filter_hash( { aaa => 555, bbb => 111 }, [ ]), { }, $a );
is_deeply( API::ISPManager::filter_hash( { }, [ 'aaa' ]), { }, $a );

$a = 'mk_query_string';
is( API::ISPManager::mk_query_string( {  }  ), '', $a );
is( API::ISPManager::mk_query_string( ''    ), '', $a );
is( API::ISPManager::mk_query_string( undef ), '', $a );
is( API::ISPManager::mk_query_string( { aaa => 111, bbb => 222 } ), 'aaa=111&bbb=222', $a );
is( API::ISPManager::mk_query_string( { bbb => 222, aaa => 111 } ), 'aaa=111&bbb=222', $a );
is( API::ISPManager::mk_query_string( [ ] ), '', $a );
is( API::ISPManager::mk_query_string( { dddd => 'dfdf' } ), 'dddd=dfdf', $a );

my $kill_start_end_slashes_test = {
    '////aaa////' => 'aaa',
    'bbb////'     => 'bbb',
    '////ccc'     => 'ccc', 
    ''            => '',
};

for (keys %$kill_start_end_slashes_test) {
    is(
        API::ISPManager::kill_start_end_slashes ($_),
        $kill_start_end_slashes_test->{$_},
        'kill_start_end_slashes'
    );
}

$a = 'mk_full_query_string';
is( API::ISPManager::mk_full_query_string( {
        host => $test_host, 
    } ), 
    '',
    $a
);

is( API::ISPManager::mk_full_query_string( {
        host       => $test_host,
        allow_http => 1,
        path       => 'manager',
    } ), 
    '',
    $a
);

is(  API::ISPManager::mk_full_query_string( {
        host       => $test_host,
        allow_http => 1,
        path       => '//my_manager///',
        param1     => 'val1',
        param2     => 'val2',
    } ), 
    "http://$test_host/my_manager/ispmgr?param1=val1&param2=val2",
    $a
);

is(  API::ISPManager::mk_full_query_string( {
        host       => $test_host,
        param1     => 'val1',
        param2     => 'val2',
    } ), 
    "https://$test_host/manager/ispmgr?param1=val1&param2=val2",
    $a
);


$a = 'mk_query_to_server';
is( API::ISPManager::mk_query_to_server( '' ), '', $a );

my %correct_params = (
    username => $ENV{username} || 'root',
    password => $ENV{password},
    host     => $test_host,
    path     => 'manager',
);

### Services

my $fake_services = <<DOC;
<?xml version="1.0" encoding="UTF-8"?>
<doc><elem><name>HTTP</name><proc>apache2</proc><autostart/><count>33</count><active/></elem><elem><name>FTP</name><proc>proftpd</proc><autostart/><count>1</count><active/></elem><elem><name>DNS</name><proc>named</proc><autostart/><count>1</count><active/></elem><elem><name>SMTP</name><proc>exim4</proc><autostart/><count>1</count><active/></elem><elem><name>POP3</name><proc>dovecot</proc><autostart/><count>2</count><active/></elem><elem><name>MySQL</name><proc>mysqld</proc><autostart/><count>3</count></elem></doc>
DOC

is_deeply( API::ISPManager::services::get( { %correct_params }, $fake_services ), {
        'data' => {
            'FTP' => {
                'count' => '1',
                'proc' => 'proftpd',
                'autostart' => {},
                'active' => {}
            },
            'HTTP' => {
                'count' => '33',
                'proc' => 'apache2',
                'autostart' => {},
                'active' => {}
            },
            'SMTP' => {
                'count' => '1',
                'proc' => 'exim4',
                'autostart' => {},
                'active' => {}
            },
            'MySQL' => {
                'count' => '3',
                'proc' => 'mysqld',
                'autostart' => {}
            },
            'POP3' => {
                'count' => '2',
                'proc' => 'dovecot',
                'autostart' => {},
                'active' => {}
             },
            'DNS' => {
                'count' => '1',
                'proc' => 'named',
                'autostart' => {},
                'active' => {}
            }
        }
    },
    'services test'
);


### Services end

### Databases

my $fake_db = <<DOC;
<?xml version="1.0" encoding="UTF-8"?>
<doc><elem><dbkey>MySQL-&gt;bt</dbkey><dbtype>MySQL</dbtype><name>bt</name><dbuser>bt</dbuser><owner>bt</owner><size>0.055</size></elem><elem><dbkey>MySQL-&gt;howtouse</dbkey><dbtype>MySQL</dbtype><name>howtouse</name><dbuser>howtouse</dbuser><owner>howtouse</owner><size>0.642</size></elem><elem><dbkey>MySQL-&gt;kapella2</dbkey><dbtype>MySQL</dbtype><name>kapella2</name><dbuser>datakapella2</dbuser><owner>kolian</owner><size>1.276</size></elem></doc>

DOC

is_deeply( API::ISPManager::db::list( { %correct_params } , $fake_db ), {
        'data' => {
            'kapella2'   => {
                'owner'  => 'kolian',
                'dbuser' => 'datakapella2',
                'dbtype' => 'MySQL',
                'dbkey'  => 'MySQL->kapella2',
                'size'   => '1.276'
            },
            'howtouse' => {
                'owner'  => 'howtouse',
                'dbuser' => 'howtouse',
                'dbtype' => 'MySQL',
                'dbkey'  => 'MySQL->howtouse',
                'size'   => '0.642'
            },
            'bt' => {
                'owner'  => 'bt',
                'dbuser' => 'bt',
                'dbtype' => 'MySQL',
                'dbkey'  => 'MySQL->bt',
                'size'   => '0.055'
            }
        }
    },
    'db list test'
);

### Databases end


### DB users

my $fake_db_user = <<DOC;
<?xml version="1.0" encoding="UTF-8"?>
<doc><plid>MySQL-&gt;blog</plid><elem><name>blog</name><read/><write/><manage/></elem></doc>
DOC

is_deeply(
    API::ISPManager::db_user::list( { %correct_params, elid => 'MySQL->blog' }, $fake_db_user ), {
        'data' => {
            'read' => {},
            'name' => 'blog',
            'manage' => {},
            'write' => {}
        }
    },
    'test db_user'
);


### DB users end

### Stats 

my $fake_sysinfo = <<DOC;
<?xml version="1.0" encoding="UTF-8"?>
<doc><elem><name>cpu</name><value>AMD Athlon(tm) 64 Processor 3700+ 2199.744 Mhz X 2</value></elem><elem><name>mem</name><value>393364 kB</value></elem><elem><name>swap</name><value>999992 kB</value></elem><elem><name>disk</name><value>49385 Mb</value></elem><elem><name>avg</name><value>1.39 0.96 0.89</value></elem><elem><name>uptime</name><value>55 days 14 hours 5 minutes</value></elem><elem><name>proc</name><value>88</value></elem><banner status="3" id="tutstat" info="http://download.ispsystem.com/tutorial/en/tutstat.html" infotype="url">ISPmanager statistics allow keeping cleaner track of your servers' performance. We also provide tutorials to help you along the way.</banner></doc>

DOC

is_deeply( API::ISPManager::stat::sysinfo( { %correct_params }, $fake_sysinfo ), {
        'data' => {
            'proc'   => '88',
            'disk'   => '49385 Mb',
            'cpu'    => 'AMD Athlon(tm) 64 Processor 3700+ 2199.744 Mhz X 2',
            'avg'    => '1.39 0.96 0.89',
            'uptime' => '55 days 14 hours 5 minutes',
            'swap'   => '999992 kB',
            'mem'    => '393364 kB',
        }
    },
    'sysinfo test'
);

my $fake_usagestat = <<DOC;
<?xml version="1.0" encoding="UTF-8"?>
<doc><elem><name>disk</name><value used="1817" limit="4950"/></elem><elem><name>reseller</name><value used="1" limit="0"/></elem><elem><name>user</name><value used="20" limit="0"/></elem><elem><name>bandwidth</name><value used="8170" limit="1700000000"/></elem><banner status="3" id="tutstat" info="http://download.ispsystem.com/tutorial/en/tutstat.html" infotype="url">ISPmanager statistics allow keeping cleaner track of your servers' performance. We also provide tutorials to help you along the way.</banner><elem><name>maildomain</name><value used="16" limit="80017"/></elem><elem><name>mailuser</name><value used="4" limit="60140"/></elem><elem><name>wwwdomain</name><value used="20" limit="70022"/></elem><elem><name>ftpuser</name><value used="20" limit="70220"/></elem><elem><name>domain</name><value used="23" limit="70022"/></elem><elem><name>database</name><value used="17" limit="70021"/></elem><elem><name>databaseuser</name><value used="17" limit="70026"/></elem></doc>
DOC

is_deeply( API::ISPManager::stat::usagestat( { %correct_params }, $fake_usagestat ), {
        'data' => {
            'ftpuser' => {
                'used' => '20',
                'limit' => '70220'
            },
            'disk' => {
                'used' => '1817',
                'limit' => '4950'
            },
            'maildomain' => {
                'used' => '16',
                'limit' => '80017'
            },
            'database' => {
                'used' => '17',
                'limit' => '70021'
            },
            'mailuser' => {
                'used' => '4',
                'limit' => '60140'
            },
            'domain' => {
                'used' => '23',
                'limit' => '70022'
            },
            'bandwidth' => {
                'used' => '8170',
                'limit' => '1700000000'
            },
            'databaseuser' => {
                'used' => '17',
                'limit' => '70026'
            },
            'user' => {
                'used' => '20',
                'limit' => '0'
            },
            'reseller' => {
                'used' => '1',
                'limit' => '0'
            },
            'wwwdomain' => {
                'used' => '20',
                'limit' => '70022'
            }
        }
    },
    'usagestat test'
);

### Stats end

#exit;

no warnings 'once';

$API::ISPManager::DEBUG = 0;


### ONLINE TESTS
exit if !$ONLINE;

$a = 'get_auth_id';
is( get_auth_id(
        username => 'root',
        password => 'qwerty',
        host     => $test_host,
        path     => 'manager',
    ), 
    '',
    "$a with error password"
);

my $auth_id;

like( $auth_id = get_auth_id(
        username => $ENV{username} || 'root',
        password => $ENV{password},
        host     => $test_host,
        path     => 'manager',
    ), 
    qr/\d+/,
    "$a with correct password ($auth_id)"
);

=head

is(
    scalar keys %{ API::ISPManager::user::list( { %correct_params } )->{elem} },
    20,
    'user::list test' 
);

=cut

my $ip_list = API::ISPManager::ip::list( { %correct_params } );

diag "Get ips from panel: " . Dumper( $ip_list );

if ($ip_list && ref $ip_list eq 'ARRAY' && scalar @$ip_list) {
    my $ip  = $ip_list->[0];
    
    if ($ip) {
        diag $ip;

        diag Dumper( API::ISPManager::user::create( {
            %correct_params,
            name      => 'nrgxxxxxapi',
            passwd    => 'qwerty',
            ip        => $ip, 
            preset    => 'Host-1',
            domain    => 'nrg.name',
        } ) );

        diag Dumper( API::ISPManager::ftp::list( {
            %correct_params,
            authinfo => 'username:password',
            su       => 'su_as_username',
        } ) );

    
        diag Dumper( API::ISPManager::user::disable( {
            %correct_params,
            elid      => 'nrgxxxxxapi',
        } ) );


        diag Dumper( API::ISPManager::user::enable( {
            %correct_params,
            elid      => 'nrgxxxxxapi',
        } ) );

        diag Dumper( API::ISPManager::user::delete( {
            %correct_params,
            elid      => 'nrgxxxxxapi',
        } ) );

    }
}

# warn Dumper( API::ISPManager::domain::list( { %correct_params } ) );


