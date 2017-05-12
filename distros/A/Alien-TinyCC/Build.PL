use strict;
use warnings;
use lib 'inc';

#            if OS is...      class is...
my $class = $^O =~ /MSWin/            ? 'My::Build::Windows'
           : $^O =~ /Cygwin/          ? 'My::Build::Cygwin'
           : $^O =~ /darwin/          ? 'My::Build::MacOSX'
           : $^O =~ /GNU\/?kFreeBSD/i ? 'My::Build::Linux' # Linux build process works for this particular BSD
           : $^O =~ /BSD/i            ? 'My::Build::BSD'   # all other BSDs need slight modification
           :                            'My::Build::Linux' # default to Linux
           ;

(my $module_file = "$class.pm") =~ s/::/\//g;
require $module_file;

# Explicitly use the sharedir and require File::Copy::Recursive only if we're on
# Windows. Properly using the sharedir as the prefix on Linux requires a direct
# make install (which does not require said module).
my @sharedir_args = (share_dir => 'share') if $^O =~ /MSWin/;
my @build_requires = ('File::Copy::Recursive' => 0) if $^O =~ /MSWin/;

# On Macs, we'll use File::Which to resolve the compiler.
@build_requires = ('File::Which' => 0) if $^O =~ /darwin/;

# OK, ready to build:
$class->new(
	module_name => 'Alien::TinyCC',
	dist_abstract => 'Ensure the Tiny C Compiler is installed on your system',
	dist_author => 'David Mertens <dcmertens.perl@gmail.com>',
	license => 'perl',
	@sharedir_args,
	configure_requires => {
		'Module::Build' => 0,
		'File::ShareDir' => 0,
	},
	build_requires => {
		'Module::Build' => 0,
		'ExtUtils::CBuilder' => 0,
		@build_requires,
		'File::ShareDir' => 0,
	},
	requires => {
		'File::ShareDir' => 0,
	},
	needs_compiler => 1,
	dynamic_config => 1,
	meta_merge => {
		resources  => {
			repository => "http://github.com/run4flat/Alien-TinyCC",
			bugtracker => "http://github.com/run4flat/Alien-TinyCC/issues",
		},
		no_index => {
			file      => [ 'README.pod' ],
		},
	},
)->create_build_script;
