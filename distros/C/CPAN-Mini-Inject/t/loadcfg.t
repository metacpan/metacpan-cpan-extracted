use strict;
use warnings;

use File::Path qw(make_path);
use File::Spec::Functions qw(catfile);
use File::Temp ();

use Test::More;

my $class = 'CPAN::Mini::Inject';

$SIG{'INT'} = sub { print "\nCleaning up before exiting\n"; exit 1 };
my $temp_dir = File::Temp::tempdir(CLEANUP=>1);

subtest 'sanity' => sub {
	use_ok $class;
	can_ok $class, qw(new loadcfg);
	};

subtest nothing => sub {
	delete local $ENV{HOME};
	delete local $ENV{MCPANI_CONFIG};

	my $mcpi = $class->new;
	isa_ok $mcpi, $class;
	can_ok $mcpi, qw(loadcfg);

	my $config_path = catfile $temp_dir, 'nothing-config';
	write_config($config_path);
	ok -e $config_path, 'config path exists';

	ok eval { $mcpi->loadcfg( $config_path ); 1 }, 'loadcfg works';
	ok exists $mcpi->{cfgfile}, 'cfgfile key exists';
	is( $mcpi->{cfgfile}, $config_path );
	};

my $mcpani_dir = catfile $temp_dir, '.mcpani';
subtest 'setup .mcpani' => sub {
	make_path $mcpani_dir;
	ok -e $mcpani_dir, '.mcpani dir exists';
	};

subtest HOME => sub {
	local $ENV{HOME} = $temp_dir;

	my $mcpi = $class->new;
	isa_ok $mcpi, $class;
	can_ok $mcpi, qw(loadcfg);

	my $config_path = catfile $mcpani_dir, 'home-config';
	write_config($config_path);
	ok -e $config_path, 'config path exists';

	ok eval { $mcpi->loadcfg( $config_path ); 1 }, 'loadcfg works';
	ok exists $mcpi->{cfgfile}, 'cfgfile key exists';
	is( $mcpi->{cfgfile}, $config_path );
	};

subtest MCPANI_CONFIG => sub {
	local $ENV{MCPANI_CONFIG} = catfile $temp_dir, 'env-config';

	my $mcpi = $class->new;
	isa_ok $mcpi, $class;
	can_ok $mcpi, qw(loadcfg);

	my $config_path = $ENV{MCPANI_CONFIG};
	write_config($config_path);
	ok -e $config_path, 'config path exists';

	ok eval { $mcpi->loadcfg( $config_path ); 1 }, 'loadcfg works';
	ok exists $mcpi->{cfgfile}, 'cfgfile key exists';
	is( $mcpi->{cfgfile}, $ENV{MCPANI_CONFIG},  );
	};

done_testing();

sub write_config {
	my( $path ) = @_;

	open my $fh, '>', $path;

	print {$fh} <<"HERE";
local: t/local/CPAN
remote : http://localhost:11027
repository: t/local/MYCPAN
dirmode: 0775
passive: yes
HERE

	close $fh;
	}
