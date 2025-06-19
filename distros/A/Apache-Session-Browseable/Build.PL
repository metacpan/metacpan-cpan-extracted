use Module::Build;

# See perldoc Module::Build for details of how this works

Module::Build->new(
    dist_author => 'LLNG Team <https://lemonldap-ng.org>',
    module_name => 'Apache::Session::Browseable',
    license     => 'perl',
    requires    => { 'Apache::Session' => 0, 'JSON' => 0, },
    recommends  => {
        'DBI'            => 0,
        'Net::LDAP'      => 0.38,
        'DBD::Cassandra' => 0,
        'Redis::Fast'    => 0,
    },
    test_requires      => { DBI => 0, 'DBD::SQLite' => 0, },
    dist_version       => '1.3.17',
    autosplit          => [qw(lib/Apache/Session/Browseable/_common.pm)],
    configure_requires => { 'Module::Build' => 0, },
    meta_merge         => {
        resources => {
            repository =>
              'https://github.com/LemonLDAPNG/Apache-Session-Browseable'
        }
    },
)->create_build_script;
