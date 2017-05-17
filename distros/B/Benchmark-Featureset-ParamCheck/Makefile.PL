use strict;
use ExtUtils::MakeMaker 6.17;

my $EUMM = eval( $ExtUtils::MakeMaker::VERSION );

my $meta = {
  "abstract"         => "compare different parameter validation modules",
  "author"           => ["Toby Inkster (TOBYINK) <tobyink\@cpan.org>"],
  "dynamic_config"   => 0,
  "generated_by"     => "Dist::Inkt::Profile::TOBYINK version 0.024, CPAN::Meta::Converter version 2.150005",
  "keywords"         => [],
  "license"          => ["perl_5"],
  "meta-spec"        => {
                          url => "http://search.cpan.org/perldoc?CPAN::Meta::Spec",
                          version => 2,
                        },
  "name"             => "Benchmark-Featureset-ParamCheck",
  "no_index"         => { directory => ["eg", "examples", "inc", "t", "xt"] },
  "prereqs"          => {
                          configure => { requires => { "ExtUtils::MakeMaker" => 6.17 } },
                          develop   => { recommends => { "Dist::Inkt" => 0.001 } },
                          runtime   => {
                                         requires => {
                                           "Data::Validator" => 1.07,
                                           "IO::String" => 0,
                                           "Moose" => 2.2002,
                                           "Moose::Util::TypeConstraints" => 2.2002,
                                           "MooseX::Params::Validate" => 0.21,
                                           "Mouse" => "v2.4.7",
                                           "Mouse::Util::TypeConstraints" => 0,
                                           "namespace::autoclean" => 0,
                                           "Params::Check" => 0.38,
                                           "Params::Validate" => 1.26,
                                           "Params::ValidationCompiler" => 0.24,
                                           "perl" => 5.012,
                                           "Ref::Util" => 0.203,
                                           "Ref::Util::XS" => 0.116,
                                           "Specio::Declare" => 0.37,
                                           "Specio::Library::Builtins" => 0.37,
                                           "Type::Params" => "1.001_009",
                                           "Type::Tiny::XS" => 0.012,
                                           "Types::Standard" => "1.001_009",
                                         },
                                       },
                          test      => { requires => { "Module::Runtime" => 0, "Test::Modern" => 0.013 } },
                        },
  "provides"         => {
                          "Benchmark::Featureset::ParamCheck"                                          => { file => "lib/Benchmark/Featureset/ParamCheck.pm", version => 0.004 },
                          "Benchmark::Featureset::ParamCheck::Base"                                    => {
                                                                                                            file => "lib/Benchmark/Featureset/ParamCheck/Base.pm",
                                                                                                            version => 0.004,
                                                                                                          },
                          "Benchmark::Featureset::ParamCheck::Base::DataValidator"                     => {
                                                                                                            file => "lib/Benchmark/Featureset/ParamCheck/Base/DataValidator.pm",
                                                                                                            version => 0.004,
                                                                                                          },
                          "Benchmark::Featureset::ParamCheck::Base::MXPV"                              => {
                                                                                                            file => "lib/Benchmark/Featureset/ParamCheck/Base/MXPV.pm",
                                                                                                            version => 0.004,
                                                                                                          },
                          "Benchmark::Featureset::ParamCheck::Base::ParamsCheck"                       => {
                                                                                                            file => "lib/Benchmark/Featureset/ParamCheck/Base/ParamsCheck.pm",
                                                                                                            version => 0.004,
                                                                                                          },
                          "Benchmark::Featureset::ParamCheck::Base::PV"                                => {
                                                                                                            file => "lib/Benchmark/Featureset/ParamCheck/Base/PV.pm",
                                                                                                            version => 0.004,
                                                                                                          },
                          "Benchmark::Featureset::ParamCheck::Base::PVC"                               => {
                                                                                                            file => "lib/Benchmark/Featureset/ParamCheck/Base/PVC.pm",
                                                                                                            version => 0.004,
                                                                                                          },
                          "Benchmark::Featureset::ParamCheck::Implementation::DataValidator::Moose"    => {
                                                                                                            file => "lib/Benchmark/Featureset/ParamCheck/Implementation/DataValidator/Moose.pm",
                                                                                                            version => 0.004,
                                                                                                          },
                          "Benchmark::Featureset::ParamCheck::Implementation::DataValidator::Mouse"    => {
                                                                                                            file => "lib/Benchmark/Featureset/ParamCheck/Implementation/DataValidator/Mouse.pm",
                                                                                                            version => 0.004,
                                                                                                          },
                          "Benchmark::Featureset::ParamCheck::Implementation::DataValidator::TypeTiny" => {
                                                                                                            file => "lib/Benchmark/Featureset/ParamCheck/Implementation/DataValidator/TypeTiny.pm",
                                                                                                            version => 0.004,
                                                                                                          },
                          "Benchmark::Featureset::ParamCheck::Implementation::MXPV::Moose"             => {
                                                                                                            file => "lib/Benchmark/Featureset/ParamCheck/Implementation/MXPV/Moose.pm",
                                                                                                            version => 0.004,
                                                                                                          },
                          "Benchmark::Featureset::ParamCheck::Implementation::MXPV::TypeTiny"          => {
                                                                                                            file => "lib/Benchmark/Featureset/ParamCheck/Implementation/MXPV/TypeTiny.pm",
                                                                                                            version => 0.004,
                                                                                                          },
                          "Benchmark::Featureset::ParamCheck::Implementation::ParamsCheck::Perl"       => {
                                                                                                            file => "lib/Benchmark/Featureset/ParamCheck/Implementation/ParamsCheck/Perl.pm",
                                                                                                            version => 0.004,
                                                                                                          },
                          "Benchmark::Featureset::ParamCheck::Implementation::ParamsCheck::TypeTiny"   => {
                                                                                                            file => "lib/Benchmark/Featureset/ParamCheck/Implementation/ParamsCheck/TypeTiny.pm",
                                                                                                            version => 0.004,
                                                                                                          },
                          "Benchmark::Featureset::ParamCheck::Implementation::Perl"                    => {
                                                                                                            file => "lib/Benchmark/Featureset/ParamCheck/Implementation/Perl.pm",
                                                                                                            version => 0.004,
                                                                                                          },
                          "Benchmark::Featureset::ParamCheck::Implementation::PV"                      => {
                                                                                                            file => "lib/Benchmark/Featureset/ParamCheck/Implementation/PV.pm",
                                                                                                            version => 0.004,
                                                                                                          },
                          "Benchmark::Featureset::ParamCheck::Implementation::PV::TypeTiny"            => {
                                                                                                            file => "lib/Benchmark/Featureset/ParamCheck/Implementation/PV/TypeTiny.pm",
                                                                                                            version => 0.004,
                                                                                                          },
                          "Benchmark::Featureset::ParamCheck::Implementation::PVC::Moose"              => {
                                                                                                            file => "lib/Benchmark/Featureset/ParamCheck/Implementation/PVC/Moose.pm",
                                                                                                            version => 0.004,
                                                                                                          },
                          "Benchmark::Featureset::ParamCheck::Implementation::PVC::Specio"             => {
                                                                                                            file => "lib/Benchmark/Featureset/ParamCheck/Implementation/PVC/Specio.pm",
                                                                                                            version => 0.004,
                                                                                                          },
                          "Benchmark::Featureset::ParamCheck::Implementation::PVC::TypeTiny"           => {
                                                                                                            file => "lib/Benchmark/Featureset/ParamCheck/Implementation/PVC/TypeTiny.pm",
                                                                                                            version => 0.004,
                                                                                                          },
                          "Benchmark::Featureset::ParamCheck::Implementation::RefUtilXS"               => {
                                                                                                            file => "lib/Benchmark/Featureset/ParamCheck/Implementation/RefUtilXS.pm",
                                                                                                            version => 0.004,
                                                                                                          },
                          "Benchmark::Featureset::ParamCheck::Implementation::TypeParams"              => {
                                                                                                            file => "lib/Benchmark/Featureset/ParamCheck/Implementation/TypeParams.pm",
                                                                                                            version => 0.004,
                                                                                                          },
                        },
  "release_status"   => "stable",
  "resources"        => {
                          bugtracker   => {
                                            web => "http://rt.cpan.org/Dist/Display.html?Queue=Benchmark-Featureset-ParamCheck",
                                          },
                          homepage     => "https://metacpan.org/release/Benchmark-Featureset-ParamCheck",
                          license      => ["http://dev.perl.org/licenses/"],
                          repository   => {
                                            type => "git",
                                            url  => "git://github.com/tobyink/p5-benchmark-featureset-paramcheck.git",
                                            web  => "https://github.com/tobyink/p5-benchmark-featureset-paramcheck",
                                          },
                          x_identifier => "http://purl.org/NET/cpan-uri/dist/Benchmark-Featureset-ParamCheck/project",
                        },
  "version"          => 0.004,
  "x_static_install" => 1,
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

