use strict;
use warnings;

use Carp;
use Test::More;
use Test::LongString;
use Data::Dumper;

use lib 't';
use TestData;


BEGIN {
    plan tests => $ENV{online_stress_tests} ? 34 : 28;
    use_ok( 'API::PleskExpand' );
    use_ok( 'API::PleskExpand::Accounts' );
    use_ok( 'API::PleskExpand::Domains' );
    use_ok( 'API::Plesk::Response');
}


my $expand_client = API::PleskExpand->new( %TestData::online_expand_valid_params);
isa_ok( $expand_client, 'API::PleskExpand', 'STATIC call new' );

# Calling undefined method from Plesk.pm

{
    our $our_warning;
    local $SIG{__DIE__} = sub { $our_warning = shift; }; # confess <=> die
    eval { API::PleskExpand->new(%TestData::online_expand_valid_params)->aaa__bbbccc() };
    like($our_warning, qr/aaa__bbbccc/,
         'Checking AUTOLOAD by calling undefined method.');
}


my %create_account_data = (
    'select'        => 'optimal',
    'template-id'   =>  1,
    'general_info'  => {
        login   => 'suxdffffxx',
        pname   => 'stdsdffafff',
        passwd  => '1234d5678',
        status  => 0,
        cname   => '',
        phone   => '',
        fax     => '',
        email   => '',
        address => '',
        city    => '',
        state   => '',
        pcode   => '',
        country => 'RU',
    }
);


my $create_request = API::PleskExpand::Accounts::create( %create_account_data );

is_string($create_request, $_, 'create account test') for
'<add_use_template><gen_info><address></address><city></city><cname></cname>'          .
'<country>RU</country><email></email><fax></fax><login>suxdffffxx</login>'             .
'<passwd>1234d5678</passwd><pcode></pcode><phone></phone><pname>stdsdffafff</pname>'   .
'<state></state><status>0</status></gen_info><!-- create_client -->'                   .
'<tmpl_id>1</tmpl_id><server_auto><optimal></optimal></server_auto></add_use_template>';

$create_request = API::PleskExpand::Accounts::create(
    %create_account_data,
    'attach_to_template' => 1 
);

is_string($create_request, $_, 'create account test') for 
'<add_use_template><gen_info><address></address><city></city><cname></cname>'        .
'<country>RU</country><email></email><fax></fax><login>suxdffffxx</login>'           .
'<passwd>1234d5678</passwd><pcode></pcode><phone></phone><pname>stdsdffafff</pname>' .
'<state></state><status>0</status></gen_info><!-- create_client -->'                 .
'<tmpl_id>1</tmpl_id><attach_to_template></attach_to_template><server_auto>'         .
'<optimal></optimal></server_auto></add_use_template>';


is_deeply(
    API::PleskExpand::Accounts::create( %create_account_data, select => ''),  
    '',
    'Manual select without server_id param'
);

like(
    API::PleskExpand::Accounts::create( %create_account_data, select => '', server_id => 5),  
    qr#<tmpl_id>1</tmpl_id><server_id>5</server_id></add_use_template>$#,
    'Manual select without server_id param'
);

like(
    API::PleskExpand::Accounts::create(
        %create_account_data,
        select   => 'optimal',
        group_id => 2
    ),
    qr#<tmpl_id>1</tmpl_id><server_auto><optimal></optimal><group_id>2</group_id></server_auto></add_use_template>$#x,
    'Select "Optimal server" with group_id',
);

like(
    API::PleskExpand::Accounts::create(
        %create_account_data,
        select         => 'optimal',
        server_keyword => 'Hosting'
    ),
    qr#<server_auto><optimal></optimal></server_auto><server_keyword>Hosting</server_keyword></add_use_template>$#,
    'Select "Optimal server" with keyword',
);

like(
    API::PleskExpand::Accounts::create( %create_account_data, select => 'min_domains', server_keyword => 'Hosting'),
    qr#<server_auto><min_domains></min_domains></server_auto><server_keyword>Hosting</server_keyword></add_use_template>$#x,
    'Select server has "max_diskspace" with keyword',
);


like(
    API::PleskExpand::Accounts::create( %create_account_data, select => 'max_diskspace', server_keyword => 'Hosting'),
    qr#<server_auto><max_diskspace></max_diskspace></server_auto><server_keyword>Hosting</server_keyword></add_use_template>$#,
    'Select server has "min_domains" with keyword',
);



my $delete_query = API::PleskExpand::Accounts::delete( id => 15 );

is_deeply( $delete_query . "\n", <<DOC, 'delete account test');
<del><!-- del_client --><filter><id>15</id></filter></del>
DOC


my $modify_query = API::PleskExpand::Accounts::modify(
    id => 15, 
    general_info => { status => 16 } # deactivate!
);


is_string( $modify_query, $_, 'modify account test') for
'<set><filter><id>15</id></filter><!-- modify_client --><values>' .
'<gen_info><status>16</status></gen_info></values></set>';


my $modify_query_alter = API::PleskExpand::Accounts::modify(
    id => 5, 
    general_info => { status => 0 } # deactivate!
);


is_string( $modify_query_alter, $_, 'modify account test') for 
'<set><filter><id>5</id></filter><!-- modify_client --><values>' .
'<gen_info><status>0</status></gen_info></values></set>';

my %new_domain_data = (
    dname               => 'y2a1ddsdfandex.ru',
    client_id           => 16,
    'template-id'       => 1,
    ftp_login           => 'nrddgddsdasd',
    ftp_password        => 'dadsdasd',
);

my $create_domain = API::PleskExpand::Domains::create( %new_domain_data );


is_string( $create_domain, $_, 'modify account test') for 
'<add_use_template><gen_setup><name>y2a1ddsdfandex.ru</name>'  .
'<client_id>16</client_id><status>0</status></gen_setup>'      .
'<hosting><vrt_hst><ftp_login>nrddgddsdasd</ftp_login>'        .
'<ftp_password>dadsdasd</ftp_password></vrt_hst></hosting>'    .
'<!-- create_domain --><tmpl_id>1</tmpl_id></add_use_template>';

$create_domain = API::PleskExpand::Domains::create( %new_domain_data, attach_to_template  => 1 );

is_string( $create_domain, $_, 'modify account test') for
'<add_use_template><gen_setup><name>y2a1ddsdfandex.ru</name>' .
'<client_id>16</client_id><status>0</status></gen_setup>'     .
'<hosting><vrt_hst><ftp_login>nrddgddsdasd</ftp_login>'       .
'<ftp_password>dadsdasd</ftp_password></vrt_hst></hosting>'   .
'<!-- create_domain --><tmpl_id>1</tmpl_id>'                  .
'<attach_to_template></attach_to_template></add_use_template>';

$expand_client->{dump_headers} = 1; # debugg =)

is_deeply(
    $expand_client->_execute_query('<add_use_template><!-- create_domain --></add_use_template>'),
    {
        ':HTTP_AUTH_LOGIN'  => $TestData::online_expand_valid_params{'username'},
        ':HTTP_AUTH_PASSWD' => $TestData::online_expand_valid_params{'password'},
        ':HTTP_AUTH_OP'     => 'exp_plesk_domain'
    },
    'test request headers'
);

is_deeply(
    $expand_client->_execute_query('<add_use_template><!-- create_client --></add_use_template>'),
    {
        ':HTTP_AUTH_LOGIN'  => $TestData::online_expand_valid_params{'username'},
        ':HTTP_AUTH_PASSWD' => $TestData::online_expand_valid_params{'password'},
        ':HTTP_AUTH_OP'     => 'exp_plesk_client'
    },
    'exp_plesk_client'
);

$expand_client->{dump_headers} = 0;


my $req_answer1 = {
    errtext     => "[Operator] Client already exists. Plesk client 'hello_medved' is exist.",
    server_id   => 1,
    status      => 'error',
    tmpl_id     => 1,
    expiration  => -1,
    errcode     => 4203,
};

is_deeply(
    API::PleskExpand::Accounts::create_response_parse( $_ ),
    $req_answer1,
    'create with error parser'
) for
'<?xml version="1.0" encoding="UTF-8" standalone="no" ?>'           .
'<packet version="2.2.4.1"><add_use_template><result>'              .
'<status>error</status><errcode>4203</errcode><errtext>'            .
"[Operator] Client already exists. Plesk client 'hello_medved' "    .
'is exist.</errtext><server_id>1</server_id><tmpl_id>1</tmpl_id>'   .
'<expiration>-1</expiration></result></add_use_template></packet>';


is_deeply(
    API::PleskExpand::Accounts::create_response_parse( $_ ), 
    {
        'server_id'  => '1',
        'status'     => 'ok',
        'expiration' => '-1',
        'tmpl_id'    => '1',
        'id'         => '29'
    },
    'parse success create xml response '
) for '<?xml version="1.0" encoding="UTF-8" standalone="no" ?>'    .
'<packet version="2.2.4.1"><add_use_template><result><status>ok'   .
'</status><id>29</id><server_id>1</server_id><tmpl_id>1</tmpl_id>' .
'<expiration>-1</expiration></result></add_use_template></packet>' ;


is_deeply(
    API::PleskExpand::Accounts::modify_response_parse( $_ ), 
    {
        'server_id' => '1',
        'status' => 'ok',
        'tmpl_id' => '1',
        'id' => '32',
        'plesk_client_id' => '395',
        'login' => 'aseaasdsassrews'
    },
    'parse success modify xml response'
) for '<?xml version="1.0" encoding="UTF-8" standalone="no" ?><packet version="2.2.4.1">' .
      '<set><result><status>ok</status><id>32</id><server_id>1</server_id><tmpl_id>1</tmpl_id>' .
      '<plesk_client_id>395</plesk_client_id><login>aseaasdsassrews</login></result></set></packet>';


is_deeply(
    API::PleskExpand::Accounts::delete_response_parse( $_ ), 
    {
        'server_id' => '1',
        'status' => 'ok',
        'id' => '33',
    },
    'parse success delete xml response'
) for '<?xml version="1.0" encoding="UTF-8" standalone="no" ?><packet version="2.2.4.1">' . 
      '<del><result><status>ok</status><id>33</id><server_id>1</server_id></result></del></packet>';



is_deeply(
    API::PleskExpand::Domains::create_response_parse( $_ ), 
    {
        'server_id'     => '1',
        'status'        => 'ok',
        'expiration'    => '-1',
        'tmpl_id'       => '1',
        'client_id'     => '38',
        'id'            => '16'

    },
    'parse success add domain xml response')
for '<?xml version="1.0" encoding="UTF-8" standalone="no" ?><packet version="2.2.4.1">' .
    '<add_use_template><result><status>ok</status><id>16</id><client_id>38</client_id>' .
    '<server_id>1</server_id><tmpl_id>1</tmpl_id><expiration>-1</expiration></result></add_use_template></packet>';



is_deeply(
    API::PleskExpand::Domains::create_response_parse( $_ ), 
    {
        errtext     => "[Operator] Domain already exists. Plesk domain 'yandex.ru' is exist.",
        errcode     => '4304',
        status      => 'error',
        tmpl_id     => 1,
        expiration  => -1,
        client_id   => 40,
        server_id   => 1,
    },
    'parse fail add domain xml response')
for '<?xml version="1.0" encoding="UTF-8" standalone="no" ?><packet version="2.2.4.1"><add_use_template>' .
    '<result><status>error</status><errcode>4304</errcode><errtext>[Operator] Domain already exists.'     .
    " Plesk domain 'yandex.ru' is exist.</errtext><client_id>40</client_id><server_id>1</server_id>"      .
    '<tmpl_id>1</tmpl_id><expiration>-1</expiration></result></add_use_template></packet>';

is_string(
    API::PleskExpand::Domains::get(all => 1),
    '<get><filter></filter><dataset><gen_info/></dataset></get><!-- create_domain -->',
    'Domains get'
);



exit unless $ENV{'online_stress_tests'};

my ($domain_template_id, $client_template_id);
$domain_template_id = $client_template_id = $ENV{template_id} || 1;

diag "Online tests start!";
# 5 tests -- full set !!!
my $login = $ENV{'online_stress_tests_login'} || 'expandtestaccount';
my $create_account_result = $expand_client->Accounts->create(
    'select'             => 'optimal',
    'template-id'        =>  $client_template_id,
    'attach_to_template' => 1,
    'general_info'  => {
        login   => $login,
        pname   => $login,
        passwd  => 'asdasdasd',
        status  => 0,
        cname   => '',
        phone   => '',
        fax     => '',
        email   => '',
        address => '',
        city    => '',
        state   => '',
        pcode   => '',
        country => 'RU',
    }
);

if ($create_account_result->is_success) {
    #warn Dumper $create_account_result;

    my $client_id =  $create_account_result->{answer_data}->[0]->{id};
    my $server_id =  $create_account_result->{answer_data}->[0]->{server_id};

    pass "Account succcessful created!";

    my $deactivate_result = $expand_client->Accounts->modify(
        general_info => { status => 16 }, # deactivate! 
        id           => $client_id,
    );

    if ($deactivate_result->is_success) {
        pass "Deactivation success!";

        my $activate_result = $expand_client->Accounts->modify(
            general_info => { status => 0 }, # activate! 
            id           => $client_id,
        );

        my $plesk_id = $activate_result->get_data->[0]->{plesk_client_id};

        if ($activate_result->is_success) {
            pass "Activation success!";

            
            my $create_domain = $expand_client->Domains->create(
                dname                => $login . '.ru',
                client_id            => $client_id,
                'template-id'        => $domain_template_id,
                'attach_to_template' => 1,
                ftp_login            => $login,
                ftp_password         => 'afsfsaf',
            );

        
            if ($create_domain->is_success) {
   
                pass "Create domain successful";

                my $nop_result = $expand_client->Accounts->modify(
                    general_info => { },         # blank operation
                    id           => $client_id,
                );

                if ($nop_result->is_success && $nop_result->get_data->[0]->{plesk_client_id} eq $plesk_id) {
                    pass "Get plesk_id $plesk_id success";
                        
                    my $delete_result = $expand_client->Accounts->delete(
                        id => $client_id,
                    );
        
                    if ( $delete_result->is_success ) {
                        pass "Delete account success";
                    } else {
                        fail "Remove account failed";   
                        exit;
                    }

                } else {
                    fail "Get plesk_id failed";
                    exit;
                }      
            } else {
                fail "Add domain failed! " . $create_domain->get_error_string;
                exit;
            }
        } else {
            fail "Activation failed!";
            exit;
        }

    } else {
        fail "Deactivation failed!";
        exit;
    }
} else {
    fail $create_account_result->get_error_string;
    exit;
}
