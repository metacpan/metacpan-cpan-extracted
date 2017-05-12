use strict;
use ExtUtils::MakeMaker 6.17;

my $EUMM = eval( $ExtUtils::MakeMaker::VERSION );

my $meta = {
  "abstract"           => "simple license checker for source files",
  "author"             => ["Jonas Smedegaard (JONASS) <jonass\@cpan.org>"],
  "dynamic_config"     => 0,
  "generated_by"       => "Dist::Inkt::Profile::TOBYINK version 0.023, CPAN::Meta::Converter version 2.150010",
  "keywords"           => ["Licensing", "Sourcecode"],
  "license"            => ["gpl_3"],
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
                                "Encode"                    => 0,
                                "experimental"              => 0,
                                "Fcntl"                     => 0,
                                "Getopt::Long::Descriptive" => 0,
                                "List::Util"                => 1.45,
                                "Moo"                       => "1.001000",
                                "namespace::clean"          => 0,
                                "Path::Iterator::Rule"      => 0,
                                "Path::Tiny"                => 0.062,
                                "perl"                      => "5.014000",
                                "Pod::Constants"            => 0,
                                "Sort::Key::Multi"          => 1.25,
                                "strictures"                => 2,
                                "String::Copyright"         => 0.003,
                                "String::Escape"            => 0,
                                "Try::Tiny"                 => 0,
                              },
                            },
                            test => {
                              recommends => { "Software::License" => 0.103008 },
                              requires   => {
                                              "Test::More"         => 0.98,
                                              "Test::Requires"     => 0,
                                              "Test::Roo"          => 0,
                                              "Test::Script"       => 1.09,
                                              "UNIVERSAL::require" => 0,
                                            },
                            },
                          },
  "provides"           => {
                            "App::Licensecheck"               => { file => "lib/App/Licensecheck.pm", version => "v3.0.29" },
                            "Regexp::Pattern::License"        => { file => "lib/Regexp/Pattern/License.pm", version => "v3.0.29" },
                            "Regexp::Pattern::License::Parts" => { file => "lib/Regexp/Pattern/License/Parts.pm", version => "v3.0.29" },
                          },
  "release_status"     => "stable",
  "resources"          => {
                            bugtracker   => {
                                              web => "https://bugs.debian.org/cgi-bin/pkgreport.cgi?pkg=licensecheck",
                                            },
                            homepage     => "https://metacpan.org/release/App-Licensecheck",
                            license      => ["http://www.gnu.org/licenses/gpl-3.0.txt"],
                            repository   => {
                                              type => "git",
                                              web  => "https://anonscm.debian.org/cgit/build-common/licensecheck.git",
                                            },
                            x_identifier => "http://purl.org/NET/cpan-uri/dist/App-Licensecheck/project",
                          },
  "version"            => "v3.0.29",
  "x_contributors"     => ["Paul Wise <pabs\@debian.org>"],
  "x_help_wanted"      => ["documenter", "tester"],
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

sub FixMakefile
{
	return unless -d 'inc';
	my $file = shift;
	
	local *MAKEFILE;
	open MAKEFILE, "< $file" or die "FixMakefile: Couldn't open $file: $!; bailing out";
	my $makefile = do { local $/; <MAKEFILE> };
	close MAKEFILE or die $!;
	
	$makefile =~ s/\b(test_harness\(\$\(TEST_VERBOSE\), )/$1'inc', /;
	$makefile =~ s/( -I\$\(INST_ARCHLIB\))/ -Iinc$1/g;
	$makefile =~ s/( "-I\$\(INST_LIB\)")/ "-Iinc"$1/g;
	$makefile =~ s/^(FULLPERL = .*)/$1 "-Iinc"/m;
	$makefile =~ s/^(PERL = .*)/$1 "-Iinc"/m;
	
	open  MAKEFILE, "> $file" or die "FixMakefile: Couldn't open $file: $!; bailing out";
	print MAKEFILE $makefile or die $!;
	close MAKEFILE or die $!;
}

my $mm = WriteMakefile(%WriteMakefileArgs);
FixMakefile($mm->{FIRST_MAKEFILE} || 'Makefile');
exit(0);

