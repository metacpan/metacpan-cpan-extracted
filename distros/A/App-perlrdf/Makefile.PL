use strict;
use ExtUtils::MakeMaker 6.17;

my $EUMM = eval( $ExtUtils::MakeMaker::VERSION );

my $meta = {
  "abstract"           => "perlrdf command line utils",
  "author"             => ["Toby Inkster (TOBYINK) <tobyink\@cpan.org>"],
  "dynamic_config"     => 0,
  "generated_by"       => "Dist::Inkt::Profile::TOBYINK version 0.016, CPAN::Meta::Converter version 2.140640",
  "keywords"           => [],
  "license"            => ["perl_5"],
  "meta-spec"          => {
                            url => "http://search.cpan.org/perldoc?CPAN::Meta::Spec",
                            version => 2,
                          },
  "name"               => "App-perlrdf",
  "no_index"           => { directory => ["eg", "examples", "inc", "t", "xt"] },
  "prereqs"            => {
                            configure => { requires => { "ExtUtils::MakeMaker" => 6.17 } },
                            runtime => {
                              recommends => {
                                              "App::perlrdf::Command::Query" => 0,
                                              "App::perlrdf::Command::Void"  => 0,
                                            },
                              requires   => {
                                              "App::Cmd"                     => 0,
                                              "App::Cmd::Plugin::Prompt"     => 0,
                                              "Data::UUID"                   => 0,
                                              "IO::Scalar"                   => 0,
                                              "JSON"                         => "2.00",
                                              "LWP::UserAgent"               => 0,
                                              "match::simple"                => 0,
                                              "Moose"                        => 0,
                                              "namespace::clean"             => 0,
                                              "Path::Class"                  => 0,
                                              "PerlX::Maybe"                 => 0,
                                              "RDF::NS"                      => 0,
                                              "RDF::TriN3"                   => 0,
                                              "RDF::Trine"                   => 0,
                                              "RDF::TrineX::Functions"       => 0.004,
                                              "RDF::TrineX::Parser::Pretdsl" => 0,
                                              "RDF::TrineX::Parser::RDFa"    => 0,
                                              "URI"                          => 0,
                                              "URI::file"                    => 0,
                                            },
                            },
                            test => {
                              requires => { "Test::Exception" => 0, "Test::More" => 0.61, "Test::RDF" => "1.00" },
                            },
                          },
  "provides"           => {
                            "App::perlrdf"                         => { file => "lib/App/perlrdf.pm", version => 0.006 },
                            "App::perlrdf::Command"                => { file => "lib/App/perlrdf/Command.pm", version => 0.006 },
                            "App::perlrdf::Command::About"         => { file => "lib/App/perlrdf/Command/About.pm", version => 0.006 },
                            "App::perlrdf::Command::Aliases"       => { file => "lib/App/perlrdf/Command/Aliases.pm", version => 0.006 },
                            "App::perlrdf::Command::Canonicalize"  => { file => "lib/App/perlrdf/Command/Canonicalize.pm", version => 0.006 },
                            "App::perlrdf::Command::Commands"      => { file => "lib/App/perlrdf/Command/Commands.pm", version => 0.006 },
                            "App::perlrdf::Command::FileSpec"      => { file => "lib/App/perlrdf/Command/FileSpec.pm", version => 0.006 },
                            "App::perlrdf::Command::Isomorphic"    => { file => "lib/App/perlrdf/Command/Isomorphic.pm", version => 0.006 },
                            "App::perlrdf::Command::MakeStore"     => { file => "lib/App/perlrdf/Command/MakeStore.pm", version => 0.006 },
                            "App::perlrdf::Command::Prefix"        => { file => "lib/App/perlrdf/Command/Prefix.pm", version => 0.006 },
                            "App::perlrdf::Command::StoreDescribe" => {
                                                                        file => "lib/App/perlrdf/Command/StoreDescribe.pm",
                                                                        version => 0.006,
                                                                      },
                            "App::perlrdf::Command::StoreDump"     => { file => "lib/App/perlrdf/Command/StoreDump.pm", version => 0.006 },
                            "App::perlrdf::Command::StoreLoad"     => { file => "lib/App/perlrdf/Command/StoreLoad.pm", version => 0.006 },
                            "App::perlrdf::Command::StoreTruncate" => {
                                                                        file => "lib/App/perlrdf/Command/StoreTruncate.pm",
                                                                        version => 0.006,
                                                                      },
                            "App::perlrdf::Command::Translate"     => { file => "lib/App/perlrdf/Command/Translate.pm", version => 0.006 },
                            "App::perlrdf::Command::Validate"      => { file => "lib/App/perlrdf/Command/Validate.pm", version => 0.006 },
                            "App::perlrdf::DummyModel"             => { file => "lib/App/perlrdf/DummyModel.pm", version => 0.006 },
                            "App::perlrdf::FileSpec"               => { file => "lib/App/perlrdf/FileSpec.pm", version => 0.006 },
                            "App::perlrdf::FileSpec::InputFile"    => { file => "lib/App/perlrdf/FileSpec/InputFile.pm", version => 0.006 },
                            "App::perlrdf::FileSpec::InputRDF"     => { file => "lib/App/perlrdf/FileSpec/InputRDF.pm", version => 0.006 },
                            "App::perlrdf::FileSpec::OutputFile"   => { file => "lib/App/perlrdf/FileSpec/OutputFile.pm", version => 0.006 },
                            "App::perlrdf::FileSpec::OutputRDF"    => { file => "lib/App/perlrdf/FileSpec/OutputRDF.pm", version => 0.006 },
                          },
  "release_status"     => "stable",
  "resources"          => {
                            bugtracker   => { web => "http://rt.cpan.org/Dist/Display.html?Queue=App-perlrdf" },
                            homepage     => "https://metacpan.org/release/App-perlrdf",
                            license      => ["http://dev.perl.org/licenses/"],
                            repository   => {
                                              type => "git",
                                              url  => "git://github.com/tobyink/p5-app-perlrdf.git",
                                              web  => "https://github.com/tobyink/p5-app-perlrdf",
                                            },
                            x_identifier => "http://purl.org/NET/cpan-uri/dist/App-perlrdf/project",
                          },
  "version"            => 0.006,
  "x_provides_scripts" => { perlrdf => { file => "bin/perlrdf" } },
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

