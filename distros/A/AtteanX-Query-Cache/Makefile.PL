use strict;
use ExtUtils::MakeMaker 6.17;

my $EUMM = eval( $ExtUtils::MakeMaker::VERSION );

my $meta = {
  "abstract"       => "Experimental prefetching SPARQL query cacher",
  "author"         => ["Kjetil Kjernsmo (KJETILK) <kjetilk\@cpan.org>"],
  "dynamic_config" => 0,
  "generated_by"   => "Dist::Inkt::Profile::TOBYINK version 0.023, CPAN::Meta::Converter version 2.150005",
  "keywords"       => [],
  "license"        => ["perl_5"],
  "meta-spec"      => {
                        url => "http://search.cpan.org/perldoc?CPAN::Meta::Spec",
                        version => 2,
                      },
  "name"           => "AtteanX-Query-Cache",
  "no_index"       => { directory => ["eg", "examples", "inc", "t", "xt"] },
  "prereqs"        => {
                        configure => { requires => { "ExtUtils::MakeMaker" => 6.17 } },
                        develop   => { recommends => { "Dist::Inkt" => 0.001 } },
                        runtime   => {
                                       requires => {
                                         "Attean" => 0.015,
                                         "AtteanX::Endpoint" => 0,
                                         "AtteanX::Store::LDF" => 0.02,
                                         "AtteanX::Store::SPARQL" => 0.008,
                                         "Class::Method::Modifiers" => 0,
                                         "Digest::MD4" => 0,
                                         "IRI" => 0.005,
                                         "List::MoreUtils" => 0,
                                         "LWP::UserAgent::CHICaching" => 0.04,
                                         "Moo" => "1.006000",
                                         "MooX::Log::Any" => 0,
                                         "namespace::clean" => 0,
                                         "perl" => 5.014,
                                         "Redis" => 0,
                                         "Types::Standard" => 0.008,
                                       },
                                     },
                        test      => {
                                       requires => {
                                         "autodie"              => 0,
                                         "Carp::Always"         => 0,
                                         "HTTP::Message::PSGI"  => 0,
                                         "LWP::Protocol::PSGI"  => 0,
                                         "RDF::Endpoint"        => 0,
                                         "RDF::Generator::Void" => 0.04,
                                         "RDF::LinkedData"      => 0,
                                         "Test::LWP::UserAgent" => 0.027,
                                         "Test::Modern"         => 0,
                                         "Test::RedisServer"    => 0,
                                       },
                                     },
                      },
  "provides"       => {
                        "AtteanX::Model::SPARQLCache"                   => { file => "lib/AtteanX/Model/SPARQLCache.pm" },
                        "AtteanX::Model::SPARQLCache::LDF"              => { file => "lib/AtteanX/Model/SPARQLCache/LDF.pm" },
                        "AtteanX::Plan::LDF::Triple::EnterCache"        => {
                                                                             file => "lib/AtteanX/Plan/LDF/Triple/EnterCache.pm",
                                                                             version => 0.002,
                                                                           },
                        "AtteanX::Query::AccessPlan::Cache"             => { file => "lib/AtteanX/Query/AccessPlan/Cache.pm", version => 0.002 },
                        "AtteanX::Query::AccessPlan::PrefetchLDF"       => {
                                                                             file => "lib/AtteanX/Query/AccessPlan/PrefetchLDF.pm",
                                                                             version => 0.002,
                                                                           },
                        "AtteanX::Query::Cache"                         => { file => "lib/AtteanX/Query/Cache.pm", version => 0.002 },
                        "AtteanX::Query::Cache::Analyzer"               => { file => "lib/AtteanX/Query/Cache/Analyzer.pm", version => 0.002 },
                        "AtteanX::Query::Cache::Analyzer::Model"        => { file => "lib/AtteanX/Query/Cache/Analyzer/Model.pm" },
                        "AtteanX::Query::Cache::Analyzer::QueryPlanner" => {
                                                                             file => "lib/AtteanX/Query/Cache/Analyzer/QueryPlanner.pm",
                                                                             version => 0.002,
                                                                           },
                        "AtteanX::Query::Cache::Retriever"              => { file => "lib/AtteanX/Query/Cache/Retriever.pm", version => 0.002 },
                        "AtteanX::QueryPlanner::Cache"                  => { file => "lib/AtteanX/QueryPlanner/Cache.pm", version => 0.002 },
                        "AtteanX::QueryPlanner::Cache::LDF"             => { file => "lib/AtteanX/QueryPlanner/Cache/LDF.pm", version => 0.002 },
                        "LWP::UserAgent::SemWebCache"                   => { file => "lib/LWP/UserAgent/SemWebCache.pm", version => 0.002 },
                        "Plack::App::AtteanX::Query::Cache"             => { file => "lib/Plack/App/AtteanX/Query/Cache.pm", version => 0.002 },
                      },
  "release_status" => "stable",
  "resources"      => {
                        bugtracker   => {
                                          web => "https://github.com/kjetilk/p5-atteanx-query-cache/issues",
                                        },
                        homepage     => "https://metacpan.org/release/AtteanX-Query-Cache",
                        license      => ["http://dev.perl.org/licenses/"],
                        repository   => {
                                          type => "git",
                                          url  => "git://github.com/kjetilk/p5-atteanx-query-cache.git",
                                          web  => "https://github.com/kjetilk/p5-atteanx-query-cache",
                                        },
                        x_identifier => "http://purl.org/NET/cpan-uri/dist/AtteanX-Query-Cache/project",
                      },
  "version"        => 0.002,
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

