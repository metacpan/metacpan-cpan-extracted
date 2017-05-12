use ExtUtils::MakeMaker;

# Eventually I'll want to have a test with a real Apache...
# Ignore this stuff for now.
#
#use Apache::test;
#
#my %params = Apache::test->get_test_params();
#
#Apache::test->write_httpd_conf (
#	%params,
#	include => <<EOF
#<Location /chart>
#SetHandler perl-script
#PerlHandler Apache::GD::Graph
#PerlSetVar Expires 15 # days
#PerlSetVar CacheDir "./t/cache"
#</Location>
#EOF
#	);
#
## Patch into MakeMakers test method.
#*MY::test = sub { Apache::test->MM_test(%params) };

WriteMakefile(
	NAME		=> 'Apache::GD::Graph',
	VERSION_FROM	=> 'lib/Apache/GD/Graph.pm', # finds $VERSION
	ABSTRACT	=> 'Apache handler to generate graphs.',
	PREREQ_PM	=> {
		GD::Graph	=> 0,
		GD::Text::Align	=> 0,
		File::Cache	=> 0,
		LWP::Simple	=> 0,
	},
	DISTNAME	=> 'Apache-GDGraph',
	dist		=> {
		COMPRESS => 'gzip -9f',
		SUFFIX   => 'gz',
		PREOP	 => makeReadme(),
	}
);

sub makeReadme {
    return <<EOF;
pod2text -72 < ./blib/lib/Apache/GD/Graph.pm > ./README ;	\\
EOF
}
