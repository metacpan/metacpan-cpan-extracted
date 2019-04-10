use strict;
use warnings;

use Module::Build;

# exit if a pure-perl build is requested
if (PurePerlRequested()) {
	die "Error: a pure perl build is not available within this distribution\n";
}

my %recommends = ();
my %configure_requires = ('perl' => '5.8.0', 'Module::Build' => '0.19', );
my %build_requires =  ( 'ExtUtils::CBuilder' => 0, 'TAP::Harness' => 0 );

my %requires = ( %configure_requires, %build_requires );

my @files_to_cleanup = (
    'DRY.c', 'DRY.o',         'salcpis.o',
);



my $build = Module::Build->new
    (
     'auto_require'       => 1,
     'module_name'        => 'Code::DRY',
     'dist_author'        => 'Heiko Eißfeldt <hexcoder@cpan.org>',
     'dist_abstract'      => 'XS Version of Code::DRY',
     'recommends'         => \%recommends,
     'requires'           => \%requires,
     'configure_requires' => \%configure_requires,
     'build_requires'     => \%build_requires,
     'extra_compiler_flags' => "-DNDEBUG",
     'extra_linker_flags' => "",
     'xs_files'           => { 'DRY.xs' => 'lib/Code/DRY.xs', },
     'license'            => 'perl',
     'dist_version_from'  => 'lib/Code/DRY.pm',
     'c_source'          => '.',
     'needs_compiler'    => 1,
     'include_dirs'      => '.',
     'script_files'      => 'bin/CP_reporter',
    );

  $build->create_build_script;

# The Lancaster Consensus specifies how pure perl builds are requested
sub PurePerlRequested
{
	if (0 < scalar @ARGV) {
		# have command line arguments
		for my $arg (@ARGV) {
		       	if ($arg eq '--pureperl-only') {
				# wants a PUREPERL distribution
				return 1;
			}
		}
	}
       	if (exists $ENV{'PERL_MB_OPT'}) {
		# have options via environment variable
	       	if ($ENV{'PERL_MB_OPT'} =~ m{--pureperl-only\b}xms) {
			# have option specifying pureperl-only request
			return 1;
		}
	}
	return 0;
}

