use Test::More tests => 6;
use strict;
use File::Temp qw/ tempfile tempdir /;

BEGIN { use_ok( 'Config::MyConfig2' ); }

my ($fh, $filename) = tempfile();

open CONF, "> $filename";
print CONF <<EOF;
testparam = test
EOF
close CONF;

my $myconfig;
eval { $myconfig = Config::MyConfig2->new( conffile => $filename) };
ok ((!$@),'Create object - '.$@);

my $conftemplate->{global}->{testparam} = { required => 'true', type => 'single', match => '\w+'};
eval { $myconfig->SetupDirectives($conftemplate) };
ok ((!$@),'Setup directives - '.$@);

my $config_hashtree;
eval { $config_hashtree = $myconfig->ReadConfig() };
ok ((!$@),'Read configuration from '.$filename.' - '.$@ );

my $global_value = $myconfig->GetGlobalValue('testparam');
ok (($global_value eq 'test'),'Get global configuration value from keyword testparam');

eval { $myconfig->WriteConfig('My Test Config',$filename) };
ok ((!$@),'Write configuration to '.$filename.' - '.$@);
