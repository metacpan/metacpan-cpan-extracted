package Bundle::BDFOY;
use strict;
use warnings;

=encoding utf8

=head1 The build file for Bundle::BDFOY

This build file is a modulino; it works as both a build script and a
module. Most of it converts the list of Perl namespaces in
F<module_list> to Bundle:: and Task:: files.

To build the distribution, run this file normally:

	% perl Makefile.PL

But, it's more interesting than that. You can load it with C<require>
and call C<arguments> to get the data structure it passes to
C<WriteMakefile>:

	my $package = require '/path/to/Makefile.PL';
	my $arguments = $package->arguments;

Note that C<require>-ing a file makes an entry in C<%INC> for exactly
that name. If you try to C<require> another file with the same name,
even from a different path, C<require> thinks it has already loaded
the file. As such, I recommend you always require the full path to the
file.

The return value of the C<require> is a package name (in this case,
the name of the main module. Use that to call the C<arguments> method.

Even if this distribution needs a higher version of Perl, this bit
only needs v5.8. You can play with the data structure with a primitive
Perl.

=cut

use File::Spec::Functions qw(catfile);

my $module    = __PACKAGE__;
( my $dist = $module ) =~ s/::/-/g;

my $github    = 'https://github.com/briandfoy/Bundle-BDFOY';
my $main_file = catfile(  qw(lib Bundle BDFOY.pm ) );

my %WriteMakefile = (
	'MIN_PERL_VERSION' => '5.008',

	'NAME'          => $module,
	'VERSION_FROM'  => $main_file,
	'ABSTRACT'      => 'install all modules by BDFOY',
	'LICENSE'       => 'artistic_2',
	'AUTHOR'        => 'brian d foy <briandfoy@pobox.com>',

	'CONFIGURE_REQUIRES' => {
		'ExtUtils::MakeMaker'   => '6.64',
		'File::Spec::Functions' => '0',
		},

	'BUILD_REQUIRES' => {
		},

	'TEST_REQUIRES' => {
		'Test::Pod'  => '0',
		'Test::More' => '1',
		},

    'PREREQ_PM'     => {
		map { $_ => '0' } @{ get_modules() }
		},

	'PL_FILES'      => {
		'preprocess/Bundle-BDFOY.pm.PL' => 'blib/lib/Bundle/BDFOY.pm',
		'preprocess/Task-BDFOY.pm.PL'   => 'blib/lib/Task/BDFOY.pm',
		},

	'META_MERGE' => {
		'meta-spec' => { version => 2 },
		resources => {
			repository => {
				type => 'git',
				url  => $github,
				web  => $github,
				},
			bugtracker => {
				web  => "$github/issues",
				},
			homepage => $github,
			},
		},

	clean => { FILES => "$dist-*" },
	);


sub arguments { \%WriteMakefile }

do_it() unless caller;
sub do_it {
	require File::Spec;
	my $MM ='ExtUtils::MakeMaker';
	my $MM_version =
		eval{ "$MM " . $WriteMakefile{'CONFIGURE_REQUIRES'}{'ExtUtils::MakeMaker'} }
			||
		"$MM 6.64";
	eval "use $MM_version; 1" or die "Could not load $MM_version: $@";
	eval "use Test::Manifest 1.21"
		if -e File::Spec->catfile( qw(t test_manifest) );

	my $arguments = arguments();
	my $minimum_perl = $arguments->{MIN_PERL_VERSION} || '5.008';
	eval "require $minimum_perl;" or die $@;

	WriteMakefile( %$arguments );
	}

sub make_file {
	my( $package, $template, $file ) = @_;

	unlink $file if -e $file;

	require File::Basename;
	require File::Path;
	my $dirname = File::Basename::dirname( $file );
	File::Path::make_path( $dirname );
	open my $fh, '>:utf8', $file
		or die "Could not open file <$file>: $!";

	print { $fh } process_template( $template );
	close $fh;
	}

sub process_template {
	my( $string ) = @_;
	my $version = get_version();
	my $list    = get_modules_pod_list();

	$string =~ s/%%VERSION%%/$version/g;
	$string =~ s/%%LIST%%/$list/g;

	$string;
	}

sub get_version {
	require "./lib/Bundle/BDFOY.pm";
	$Bundle::BDFOY::VERSION;
	}

sub get_modules {
	my $file = 'module_list';
	local $/ = "\n";
	chomp( my @list = do { local(@ARGV)=$file; <> } );
	return \@list;
	}

sub get_modules_pod_list {
	join "\n\n",
	map { "=item * $_" }
	@{ get_modules() }
	}

no warnings;
__PACKAGE__;
