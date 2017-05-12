use strict;
use ExtUtils::MakeMaker;
use lib 't/lib';
use lib '../blib/lib';
use Apache::test qw(have_httpd);

my %params = Apache::test->get_test_params();

chomp (my $cwd = `pwd`);
my $libdir = $cwd . '/t/lib';
my $mods = 'MyLib; TestLib1::Mod1; TestLib2::Mod2;';
my $conf_text = <<"EOF";
StartServers 15
MinSpareServers 15
MaxSpareServers 15
MaxClients 15

<Location "/appc_svr">
	SetHandler perl-script
	PerlSetVar AppCLibs "--libs--"
	PerlSetVar AppCModules "--mods--"
	PerlHandler Apache::AppCluster::Server
</Location>
EOF

$conf_text =~ s/--libs--/$libdir/g;
$conf_text =~ s/--mods--/$mods/g;
Apache::test->write_httpd_conf(%params, include => $conf_text);

*MY::test = sub { Apache::test->MM_test(%params) } if(have_httpd());

WriteMakefile(
    'NAME'		=> 'Apache::AppCluster::Server',
    'VERSION_FROM'	=> 'Server.pm', 
    'dist' => { COMPRESS => 'gzip',
    		SUFFIX => 'gz', 
		},
    'clean' => { FILES => "t/httpd t/httpd.conf t/error_log" },
    'PREREQ_PM'		=> {
    	'mod_perl' => 0,
	'Apache' => 0,
	'Apache::Constants' => 0,
	'Storable' => 0,
	'Digest::MD5' => 0,
	'Time::HiRes' => 0,
	'POSIX' => 0,
	'IO::Socket' => 0,
    }, 
);


