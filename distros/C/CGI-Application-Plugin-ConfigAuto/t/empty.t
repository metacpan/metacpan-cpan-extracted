use Test::More qw/no_plan/;
BEGIN { use_ok('CGI::Application::Plugin::ConfigAuto') };

use lib './t';
use strict;

$ENV{CGI_APP_RETURN_ONLY} = 1;

use TestAppBasic;
my $t1_obj = TestAppBasic->new();
eval { $t1_obj->cfg_file('t/empty_config.pl'); 
       $t1_obj->cfg();
};

like ($@, qr/\QNo configuration found. Check your config file(s) (check the syntax if this is a perl format)/);

