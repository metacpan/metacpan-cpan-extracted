# test model used by t/*.t

$model->create_config_class (
   name => 'Host',

   element => [
       [qw/ipaddr canonical alias/] => { type => 'leaf', value_type => 'uniline',} 
   ]
);

$model->create_config_class (
   name => 'Hosts',

   rw_config  =>  {
       backend => 'augeas',
       config_dir => '/etc/',
       file => 'hosts',
       set_in => 'record',
       save   => 'backup',
       #sequential_lens => ['record'],
   },

   element => [
       record => {
           type => 'list',
           cargo => {
               type => 'node',
               config_class_name => 'Host',
           } ,
       },
   ]
);

$model->create_config_class (
   name => 'Sshd',

   rw_config => {
       backend => 'augeas',
       config_dir => '/etc/ssh/',
       file => 'sshd_config',
       save   => 'backup',
       sequential_lens => [qw/HostKey Subsystem Match/],
   },

   element => [
       'AcceptEnv' => {
           'type' => 'list',
           'cargo' => {
               'value_type' => 'uniline',
               'type' => 'leaf'
           },
       },
       'AllowUsers' => {
           'type' => 'list',
           'cargo' => {
               'value_type' => 'uniline',
               'type' => 'leaf'
           },
       },
       'ForceCommand' => {
           'type' => 'leaf',
           'value_type' => 'uniline',
       },
       'HostbasedAuthentication' => {
           'type' => 'leaf',
           'value_type' => 'enum',
           choice => [qw/no yes/],
       },
       'HostKey' => {
           'type' => 'list',
           'cargo' => {
               'type' => 'leaf',
               'value_type' => 'uniline',
           },
       },
       'DenyUSers' => {
           'type' => 'list',
           'cargo' => {
               'type' => 'leaf',
               'value_type' => 'uniline',
           },
       },
       'Protocol' => {
           'type' => 'check_list',
           'default_list' => ['1', '2'],
           'choice' => ['1', '2']
       },
       'Subsystem' => {
           'type' => 'hash',
           'index_type' => 'string',
           'cargo' => {
               'type' => 'leaf',
               'value_type' => 'uniline',
               'mandatory' => '1',
           },
       },
       'Match' => {
           'type' => 'list',
           'cargo' => {
               'type' => 'node',
			    '# commentnfig_class_name' => 'Sshd::MatchBlock'
           },
       },
       'Ciphers' => {
           'type' => 'check_list',
           'upstream_default_list' => [ 'aes256-cbc', 'aes256-ctr', 'arcfour256'],
           ordered => 1,
           'description' => 'Specifies the ciphers allowed for protocol version 2. By default, all ciphers are allowed.',
           'choice' => [
               'arcfour256',
               'aes192-cbc',
               'aes192-ctr',
               'aes256-cbc',
               'aes256-ctr'
           ]
       },
   ]
);

$model->create_config_class (
    'name' => 'Sshd::MatchBlock',
    'element' => [
		 'Condition' => {
             'type' => 'node',
             'config_class_name' => 'Sshd::MatchCondition'
		 },
		 'Settings' => {
             'type' => 'node',
             'config_class_name' => 'Sshd::MatchElement'
		 }
     ]
);

$model->create_config_class (
   'name' => 'Sshd::MatchCondition',
   'element' => [
       'User' => {
           'type' => 'leaf',
           'value_type' => 'uniline',
       },
       'Group' => {
           'type' => 'leaf',
           'value_type' => 'uniline',
       },
       'Host' => {
           'type' => 'leaf',
           'value_type' => 'uniline',
       },
       'Address' => {
           'type' => 'leaf',
           'value_type' => 'uniline',
       }
   ]
);

$model->create_config_class (
   'name' => 'Sshd::MatchElement',
   'element' => [
       'AllowTcpForwarding' => {
           'type' => 'leaf',
           'value_type' => 'enum',
           'choice' => ['no', 'yes']
       },
       'Banner' => {
           'type' => 'leaf',
           'value_type' => 'uniline',
       },
   ]
);


