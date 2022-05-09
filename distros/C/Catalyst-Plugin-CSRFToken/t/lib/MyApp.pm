package MyApp;
use Catalyst;

MyApp->setup_plugins([qw/
  CSRFToken
/]);

MyApp->config(
  'Plugin::CSRFToken' => { default_secret=>'changeme', auto_check => 1 }
);

sub sessionid { 23123123123 }
     
MyApp->setup;
