package TestConfig;

use AppConfig::Exporter;
use base qw(AppConfig::Exporter);

__PACKAGE__->configure(Config_File => 't/config.test', AppConfig_Define => { two_Cars => {ARGCOUNT => ARGCOUNT_LIST} });

1;
