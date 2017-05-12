# fake MyConfig.pm for testing purposes
package test_data::MyConfig;

$CONFIG = {
  'APACHE_GID' => 80,
  'APACHE_UID' => 81,
  'CODE_PATH' => 'code',
  'CONF_FILE' => 'etc/voodoo.conf',
  'CONF_PATH' => 'etc',
  'DEBUG_DBD' => [
    'dbi:SQLite:dbname=/tmp/apachevoodoo.db',
    'username',
    'password'
  ],
  'DEBUG_PATH' => '/debug',
  'INSTALL_PATH' => '/data/apache/sites',
  'PREFIX' => '/data/apache',
  'SESSION_PATH' => '/data/apache/session',
  'TMPL_PATH' => 'html',
  'UPDATES_PATH' => 'etc/updates',
  'USE_LOG4PERL' => 1,
  'LOG4PERL_CONF' => '/etc/log4perl.conf'
}
;

1;
