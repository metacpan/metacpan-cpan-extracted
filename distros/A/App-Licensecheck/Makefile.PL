use strict;
use ExtUtils::MakeMaker 6.17;

my $EUMM = eval( $ExtUtils::MakeMaker::VERSION );

my $meta = {
  "abstract"           => "simple license checker for source files",
  "author"             => ["Jonas Smedegaard (JONASS) <jonass\@cpan.org>"],
  "dynamic_config"     => 0,
  "generated_by"       => "Dist::Inkt::Profile::TOBYINK version 0.024, CPAN::Meta::Converter version 2.150010",
  "keywords"           => ["Licensing", "Sourcecode"],
  "license"            => ["agpl_3"],
  "meta-spec"          => {
                            url => "http://search.cpan.org/perldoc?CPAN::Meta::Spec",
                            version => 2,
                          },
  "name"               => "App-Licensecheck",
  "no_index"           => { directory => ["eg", "examples", "inc", "t", "xt"] },
  "prereqs"            => {
                            configure => { requires => { "ExtUtils::MakeMaker" => 6.17 } },
                            runtime => {
                              requires => {
                                "autodie"                   => 0,
                                "Encode"                    => 2.93,
                                "Fcntl"                     => 0,
                                "Feature::Compat::Class"    => 0.04,
                                "Feature::Compat::Try"      => 0,
                                "Getopt::Long"              => 2.24,
                                "IO::Interactive"           => 0,
                                "List::Util"                => 1.45,
                                "Log::Any"                  => 0,
                                "Log::Any::Adapter::Screen" => 0,
                                "namespace::clean"          => 0,
                                "Path::Iterator::Rule"      => 0,
                                "Path::Tiny"                => 0.062,
                                "perl"                      => "5.012000",
                                "Pod::Constants"            => 0,
                                "Pod::Usage"                => "1.60",
                                "String::Copyright"         => 0.003,
                                "String::Escape"            => 0,
                                "String::License"           => 0,
                              },
                            },
                            test => {
                              recommends => { "Regexp::Pattern::License" => "v3.9.0" },
                              requires   => {
                                              "Encode" => 0,
                                              "Encode::Locale" => 0,
                                              "Test2::Tools::Command" => 0,
                                              "Test2::V0" => "0.000060",
                                              "Test::Without::Module" => 0,
                                            },
                            },
                          },
  "provides"           => {
                            "App::Licensecheck" => { file => "lib/App/Licensecheck.pm", version => "v3.3.7" },
                          },
  "release_status"     => "stable",
  "resources"          => {
                            bugtracker   => {
                                              web => "https://bugs.debian.org/cgi-bin/pkgreport.cgi?pkg=licensecheck",
                                            },
                            homepage     => "https://metacpan.org/pod/App::Licensecheck",
                            license      => ["http://www.gnu.org/licenses/agpl-3.0.txt"],
                            repository   => {
                                              type => "git",
                                              web  => "https://salsa.debian.org/build-common-team/licensecheck.git",
                                            },
                            x_identifier => "http://purl.org/NET/cpan-uri/dist/App-Licensecheck/project",
                          },
  "version"            => "v3.3.7",
  "x_contributors"     => ["Paul Wise <pabs\@debian.org>"],
  "x_help_wanted"      => ["tester", "documenter"],
  "x_provides_scripts" => { licensecheck => { file => "bin/licensecheck" } },
};

my %dynamic_config;

my %WriteMakefileArgs = (
	ABSTRACT   => $meta->{abstract},
	AUTHOR     => ($EUMM >= 6.5702 ? $meta->{author} : $meta->{author}[0]),
	DISTNAME   => $meta->{name},
	VERSION    => $meta->{version},
	EXE_FILES  => [ map $_->{file}, values %{ $meta->{x_provides_scripts} || {} } ],
	NAME       => do { my $n = $meta->{name}; $n =~ s/-/::/g; $n },
	test       => { TESTS => "t/*.t" },
	%dynamic_config,
);

$WriteMakefileArgs{LICENSE} = $meta->{license}[0] if $EUMM >= 6.3001;

sub deps
{
	my %r;
	for my $stage (@_)
	{
		for my $dep (keys %{$meta->{prereqs}{$stage}{requires}})
		{
			next if $dep eq 'perl';
			my $ver = $meta->{prereqs}{$stage}{requires}{$dep};
			$r{$dep} = $ver if !exists($r{$dep}) || $ver >= $r{$dep};
		}
	}
	\%r;
}

my ($build_requires, $configure_requires, $runtime_requires, $test_requires);
if ($EUMM >= 6.6303)
{
	$WriteMakefileArgs{BUILD_REQUIRES}     ||= deps('build');
	$WriteMakefileArgs{CONFIGURE_REQUIRES} ||= deps('configure');
	$WriteMakefileArgs{TEST_REQUIRES}      ||= deps('test');
	$WriteMakefileArgs{PREREQ_PM}          ||= deps('runtime');
}
elsif ($EUMM >= 6.5503)
{
	$WriteMakefileArgs{BUILD_REQUIRES}     ||= deps('build', 'test');
	$WriteMakefileArgs{CONFIGURE_REQUIRES} ||= deps('configure');
	$WriteMakefileArgs{PREREQ_PM}          ||= deps('runtime');	
}
elsif ($EUMM >= 6.52)
{
	$WriteMakefileArgs{CONFIGURE_REQUIRES} ||= deps('configure');
	$WriteMakefileArgs{PREREQ_PM}          ||= deps('runtime', 'build', 'test');	
}
else
{
	$WriteMakefileArgs{PREREQ_PM}          ||= deps('configure', 'build', 'test', 'runtime');	
}

{
	my ($minperl) = reverse sort(
		grep defined && /^[0-9]+(\.[0-9]+)?$/,
		map $meta->{prereqs}{$_}{requires}{perl},
		qw( configure build runtime )
	);
	
	if (defined($minperl))
	{
		die "Installing $meta->{name} requires Perl >= $minperl"
			unless $] >= $minperl;
		
		$WriteMakefileArgs{MIN_PERL_VERSION} ||= $minperl
			if $EUMM >= 6.48;
	}
}


my $mm = WriteMakefile(%WriteMakefileArgs);

exit(0);

