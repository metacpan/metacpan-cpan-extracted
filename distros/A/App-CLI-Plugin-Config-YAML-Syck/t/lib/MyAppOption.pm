package MyAppOption;

use strict;
use base qw(App::CLI::Extension);
use constant alias => ("yaml" => "YAMLTest");

$ENV{APPCLI_NON_EXIT} = 1;
__PACKAGE__->load_plugins(qw(Config::YAML::Syck));

1;

