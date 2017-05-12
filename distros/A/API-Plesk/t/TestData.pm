package TestData;

use Test::More;
use API::Plesk;

#
# Support sub`s and data for tests
#

our @EXPORT = qw(
    delete_all_accounts
    create_unique_user_data
    _compare
    gen_passwd
    iterate
    check_input_data
    create_work_logins
);

# ONLINE configs

my $online_plesk_url = 'https://127.0.0.1:8443/enterprise/control/agent.php';

our $online_manual_created_template_name = $ENV{'template_name'};
our $online_manual_created_template_id  = $ENV{'template_id'};
our $online_new_tariff_name = $ENV{'new_tariff'};

our %online_plesk_valid_params = (
    api_version   => $ENV{'plesk_api_version'}  || '1.5.0.0',
    username      => $ENV{'plesk_username'}     || 'admin',
    password      => $ENV{'plesk_password'}     || 'qwerty',
    url           => $ENV{'plesk_url'}          || $online_plesk_url,
    debug         => '',
);

# END online  configs

our $test_user_data =  { 
    pname   => 'pavel', 
    login   => 'pav_perl',
    passwd  => 'password',
    phone   => '8 555 1111111',
    email   => 'nrg@nrg.name',
    country => 'RU'                 # optional field
};


our $stress_test_data = {
    pname => [ # 1 .. 60 symbols 
        'pavel',
        '2342134123412',
        'dasdf_dasdsa_ADdssd__DASsd',
        # '____', error
        (join '', 'x' x 60),
        'add_(efewf)_(sdfsd)',
    ],
    login => [ # 1 .. 20 symbols, 
        'pav_perl',
        # '___', error
        '123546',
        #'_sdad',
        'nrg.name',
        'test.code.google.com',
        'yet-another-test',
        (join q//, 'x' x 20),
        # '_(fsdf)_(fsadf)' error
    ],
    passwd => [
        'five!',
        (join q//, 'x' x 14),
        #'##$^$#&^%!@#$d',
        12314321,
        '_(sdf)%!Sas',
        gen_passwd(),
        gen_passwd(),
        gen_passwd()
        #'тестовый' error
    ],
    phone => [ # 0 .. 30
        '8 555 1111111',
        # 'abcdefaff', error
        '5',
        '+7 499 123 44 55',
        '+74991234455',
        '',
        ' ',
        '8(846)1234356',
        '+7(846)1234356',
        # '()()()(',
        '312(4324)324',
    ],
    email => [ # 0 .. 255
        'nrg@nrg.name',
        'asdsadad@nrg.name',
        'sadasd.adasd.asfsf@nrg.name',
        'asdasd-fghh@nrg.name',
        'ad@fdsf.fsdf.dsf.nrg.name'
    ],
    country => [ # two characters only
        'RU',
        #'TEST',
        'US',
        'UG'
    ],
};



my $plesk_url = 'https://192.168.1.1:8443/enterprise/control/agent.php';

our %plesk_valid_params = (
    api_version   => '1.6.3.0',
    username      => 'admin',
    password      => 'qwerty',
    url           => $plesk_url,
    debug         => 0,
);


my $manual_created_template_name = $ENV{'template_name'} || 'name';
my $manual_created_template_id = $ENV{'template_id'} || 1;


sub iterate {
    my $hash = shift;
    my $plesk_client = shift;

    my $result_hash = { };

    # initial data
    for (keys %$hash) {
        $result_hash->{$_} = $hash->{$_}->[0];
    }

    check_input_data($result_hash, $plesk_client);

    foreach my $key (keys %$hash) {
        my $old_value = $result_hash->{$key}; # rewrite 

        for my $index (1 .. scalar @{$hash->{$key}} - 1){
            $result_hash->{$key} = $hash->{$key}->[$index];
            check_input_data($result_hash, $plesk_client);
            # warn Dumper $result_hash;
        }
        $result_hash->{$key} = $old_value;
    }

    return $result_hash;
}


sub check_input_data {
    my $params = shift;
    my $plesk_client = shift;

    my $general_info = {
        pname   => $params->{pname},  # utf8 string 
        login   => $params->{login},
        passwd  => $params->{passwd},
        phone   => $params->{phone},
        email   => $params->{email},
        country => $params->{country}, # optional field
    };
    

    my $result_add_by_id = $plesk_client->Accounts->create( 
        general_info    => $general_info,
        'template-name' => $manual_created_template_name 
    );

    delete_all_accounts($plesk_client);
    # warn Dumper($general_info) . "\n" . $result_add_by_id->get_error_string unless
    unless (like( 
        $result_add_by_id->get_id,
        qr/^\d+$/,
        'Create account input data check'
    )) {
        warn $result_add_by_id->get_error_string . "\n" .
             Dumper $general_info;
    }
}


sub gen_passwd {
    my $passwd='';
    for (my $i=0; $i<8; $i++) {
        $passwd .= chr(rand( 0x3E ));
    }
    $passwd =~ tr/\x00-\x3D/A-Za-z0-9/;
    return $passwd;
}


# Delete all accounts
# STATIC(plesk_client)
sub delete_all_accounts {
    my $client = shift;
    
    is_deeply( 
      $client->Accounts->delete( all => 1)->is_success,
      1,
      'Delete all accounts'
    );
}


# Sub for create accounts online test
sub create_work_logins {
    my $plesk_client = shift;
    my $data_accumulator_for_online_tests = shift;

    my $result_add_by_id = $plesk_client->Accounts->create( 
        general_info    => create_unique_user_data('crby_login'),
        'template-name' => $manual_created_template_name 
    );

    like(
        $data_accumulator_for_online_tests->{user_id_from_create_with_tmpl_name} = 
        $result_add_by_id->get_id,

        qr/^\d+$/,
        'Create account with template name'
    );

    like(
        $data_accumulator_for_online_tests->{user_id_from_create_with_tmpl_id} = 
            
        $plesk_client->Accounts->create( 
            general_info  => create_unique_user_data('createby_id'),
            'template-id' => $manual_created_template_id
        )->get_id,

        qr/^\d+$/,
        'Create account with template id'
    );
}


sub create_unique_user_data {
    my $unique_id = shift;
    my %result_user_data = %{$test_user_data};

    $result_user_data{'pname'} = $result_user_data{'login'} = "testuser_$unique_id";
    return \%result_user_data;
}


# "Compare" two hashrefs
# Sub for get info online tests
sub _compare {
    my $checked = shift;
    my $template = shift;

    return '' unless ref $checked eq 'HASH' &&  ref $template eq 'HASH';
    
    foreach my $key (keys %$template) {
        my $key_name_from;  # field name in response from Plesk
        my $key_name_to;    # field name  

        # in request to Plesk field named "passwd"
        # in response from Plesk -- it named "password" :(

        if ($key =~ /pass/) {

            $key_name_from  = 'password';
            $key_name_to    = 'passwd';

        } else {
            $key_name_to = $key_name_from = $key;
        }

        if ($checked->{$key_name_from}) {
            return '' unless $template->{$key_name_to} eq 
                             $checked->{$key_name_from};
        } else {
            return '';
        }
    }

    return 1;
}



# Light weight Exporter
sub import {
    no strict 'refs';
    my $called_from = caller;

    foreach my $package_sub (@EXPORT) {
        # importing our sub into caller`s namespace
        *{$called_from . '::' . $package_sub} = \&$package_sub;
    }
}


1;
