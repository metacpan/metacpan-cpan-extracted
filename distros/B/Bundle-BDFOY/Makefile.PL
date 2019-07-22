package Bundle::BDFOY;
use strict;
use warnings;

=encoding utf8

=head1 The build file for Bundle::BDFOY

This build file is a modulino; it works as both a build script and
a module.

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
my $main_file = catfile( 'lib', split /::/, "$module.pm" );

my %WriteMakefile = (
	'MIN_PERL_VERSION' => '5.008',

	'NAME'          => $module,
	'VERSION_FROM'  => $main_file,
	'ABSTRACT_FROM' => $main_file,
	'LICENSE'       => 'artistic_2',
	'AUTHOR'        => 'brian d foy <bdfoy@cpan.org>',

	'CONFIGURE_REQUIRES' => {
		'ExtUtils::MakeMaker'   => '6.64',
		'File::Spec::Functions' => '0',
		},

	'BUILD_REQUIRES' => {
		},

	'TEST_REQUIRES' => {
		'Test::Pod'  => '0',
		'Test::More' => '0.94',
		},

    'PREREQ_PM'     => {
        'App::Module::Lister' => '0',
        'App::PPI::Dumper' => '0',
        'App::scriptdist' => '0',
        'Brick' => '0',
        'Business::ISBN' => '0',
        'Business::ISBN::Data' => '0',
        'Business::ISMN' => '0',
        'Business::ISSN' => '0',
        'Business::xISBN' => '0',
        'CACertOrg::CA' => '0',
        'Chemistry::Elements' => '0',
        'ConfigReader::Simple' => '0',
        'CPAN::PackageDetails' => '0',
        'Crypt::Rijndael' => '0',
        'Data::Constraint' => '0',
        'Distribution::Cooker' => '0',
        'Distribution::Guess::BuildSystem' => '0',
        'Dumbbench' => '0',
        'File::Find::Closures' => '0',
        'File::Fingerprint' => '0',
        'Geo::GeoNames' => '0',
        'HTML::SimpleLinkExtor' => '0',
        'HTTP::Cookies::Chrome' => '0',
        'HTTP::Cookies::Mozilla' => '0',
        'HTTP::Cookies::Safari' => '0',
        'HTTP::Size' => '0',
        'IO::Interactive' => '0',
        'Log::Log4perl::Appender::ScreenColoredLevels::UsingMyColors' => '0',
        'Mac::Errors' => '0',
        'Mac::OSVersion' => '0',
        'Mac::PropertyList' => '0',
        'MacOSX::Alias' => '0',
        'Math::NoCarry' => '0',
        'Module::Extract::DeclaredMinimumPerl' => '0',
        'Module::Extract::Namespaces' => '0',
        'Module::Extract::Use' => '0',
        'Module::Extract::VERSION' => '0',
        'Module::Release' => '0',
        'Module::Release::Git' => '0',
        'Module::Starter::AddModule' => '0',
        'Modulino::Demo' => '0',
        'MyCPAN::App::DPAN' => '0',
        'MyCPAN::Indexer' => '0',
        'Net::MAC::Vendor' => '0',
        'Net::SSH::Perl::ProxiedIPC' => '0',
        'Net::SSH::Perl::WithSocks' => '0',
        'Object::Iterate' => '0',
        'PeGS::PDF' => '0',
        'Perl::MinimumVersion::Fast' => '0',
        'Perl::Version' => '0',
        'perlbench' => '0',
        'PerlPowerTools' => '0',
        'Pod::Perldoc::ToToc' => '0',
        'Pod::PseudoPod::DocBook' => '0',
        'Pod::PseudoPod::PerlTricks' => '0',
        'Pod::WordML' => '0',
        'Polyglot' => '0',
        'PPI::App::ppi_version::BDFOY' => '0',
        'ReturnValue' => '0',
        'Roman::Unicode' => '0',
        'Set::CrossProduct' => '0',
        'SourceCode::LineCounter::Perl' => '0',
        'String::Sprintf' => '0',
        'Surveyor::App' => '0',
        'Surveyor::Benchmark::HTMLEntities' => '0',
        'Surveyor::Benchmark::SchwartzianTransform::SortFilesBySize' => '0',
        'Task::MasteringPerl' => '0',
        'Task::MojoLearningEnvironment' => '0',
        'Test::Data' => '0',
        'Test::Env' => '0',
        'Test::File' => '0',
        'Test::ISBN' => '0',
        'Test::Manifest' => '0',
        'Test::Output' => '0',
        'Test::Prereq' => '0',
        'Test::URI' => '0',
        'Tie::BoundedInteger' => '0',
        'Tie::Cycle' => '0',
        'Tie::StringArray' => '0',
        'Tie::Timely' => '0',
        'Tie::Toggle' => '0',
        'Unicode::Casing' => '0',
        'Unicode::Support' => '0',
        'Unicode::Tussle' => '0',
        'WordPress::Grep' => '0',
        },

	'META_MERGE' => {
		'meta-spec' => { version => 2 },
		resources => {
			repository => {
				type => 'git',
				url  => "$github.git",
				web  => $github,
				},
			bugtracker => {
				web    => "$github/issues",
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


no warnings;
__PACKAGE__;
