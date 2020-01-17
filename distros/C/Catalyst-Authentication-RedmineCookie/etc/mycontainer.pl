{
    web => {
        'Plugin::Authentication' => {
            default_realm => 'redmine_cookie',
            realms => {
                redmine_cookie => {
                    credential => {
                        class => 'RedmineCookie',
                        # examples
                        # cmd   => [qw(ssh redmine.server /root/rails4_cookie_to_json.rb)],
                        # cmd   => [qw(sudo jexec redmine /root/rails4_cookie_to_json.rb)],
                    },
                    # It does not specify a store, it works with NullStore.
                    # store => {
                    #     class => 'DBIx::Class',
                    #     user_model => 'DBIC::Users',
                    # }
                },
            },
        },
        # Not required for NullStore.
        # 'Model::DBIC' => {
        #     compose_namespaces => 0,
        #     schema_class => "Catalyst::Authentication::RedmineCookie::Schema",
        #     connect_info => [
        #         "DBI:mysql:database=redmine", 'user', 'pass',
        #         {
        #             RaiseError        => 1,
        #             PrintError        => 0,
        #             AutoCommit        => 1,
        #             pg_enable_utf8    => 1, # for pg
        #             mysql_enable_utf8 => 1, # for mysql
        #             quote_names       => 1,
        #         }
        #     ],
        # },
    },
};
