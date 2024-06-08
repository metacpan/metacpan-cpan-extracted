use strict;
use warnings;

use Test::More;

use File::Spec::Functions qw(catfile);

my $class = 'CPAN::Mini::Inject';

subtest sanity => sub {
	use_ok $class or BAIL_OUT( "$class did not compile: $@" );
	};

subtest 'loadcfg' => sub {
	my $mcpi = $class->new;
	isa_ok $mcpi, $class;

	my $file = catfile qw(t .mcpani config);
	ok -e $file, "file <$file> exists";

	$mcpi->loadcfg( $file );
	$mcpi->parsecfg;

	ok exists $mcpi->{config}, 'config key exists';

	is( $mcpi->{config}{local},      't/local/CPAN' );
	is( $mcpi->{config}{remote},     'http://localhost:11027' );
	is( $mcpi->{config}{repository}, 't/local/MYCPAN' );
	};

subtest 'no loadcfg' => sub {
	my $mcpi = $class->new;
	isa_ok $mcpi, $class;

	my $file = catfile qw(t .mcpani config);
	ok -e $file, "file <$file> exists";

	$mcpi->parsecfg( $file );
	is( $mcpi->{config}{local},      't/local/CPAN' );
	is( $mcpi->{config}{remote},     'http://localhost:11027' );
	is( $mcpi->{config}{repository}, 't/local/MYCPAN' );
	};

subtest 'whitespace' => sub {
	my $mcpi = $class->new;
	isa_ok $mcpi, $class;

	my $file = catfile qw(t .mcpani config_with_whitespaces);
	ok -e $file, "file <$file> exists";

	$mcpi->parsecfg( $file );
	is( $mcpi->{config}{local},      't/local/CPAN' );
	is( $mcpi->{config}{remote},     'http://localhost:11027' );
	is( $mcpi->{config}{repository}, 't/local/MYCPAN' );
	is( $mcpi->{config}{dirmode},    '0775' );
	is( $mcpi->{config}{passive},    'yes' );
	};

done_testing();
