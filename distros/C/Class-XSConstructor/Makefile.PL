use strict;
use ExtUtils::MakeMaker 6.17;

my $EUMM = eval( $ExtUtils::MakeMaker::VERSION );

my $meta = {
  "abstract"       => "a super-fast (but limited) constructor in XS",
  "author"         => ["Toby Inkster (TOBYINK) <tobyink\@cpan.org>"],
  "dynamic_config" => 1,
  "generated_by"   => "Dist::Inkt::Profile::TOBYINK version 0.024, CPAN::Meta::Converter version 2.150010",
  "keywords"       => [],
  "license"        => ["perl_5"],
  "meta-spec"      => {
                        url => "http://search.cpan.org/perldoc?CPAN::Meta::Spec",
                        version => 2,
                      },
  "name"           => "Class-XSConstructor",
  "no_index"       => { directory => ["eg", "examples", "inc", "t", "xt"] },
  "prereqs"        => {
                        configure => {
                                       recommends => { "Devel::PPPort" => 3.42 },
                                       requires   => { "ExtUtils::MakeMaker" => 6.17 },
                                     },
                        develop   => { recommends => { "Dist::Inkt" => 0.001 } },
                        runtime   => {
                                       recommends => { "Type::Tiny::XS" => 0, "Types::Standard" => "1.000000" },
                                       requires   => {
                                                       "Exporter::Tiny" => "1.000000",
                                                       "List::Util" => 1.45,
                                                       "perl" => 5.008008,
                                                     },
                                     },
                        test      => {
                                       recommends => { "Types::Standard" => "1.000000" },
                                       requires   => {
                                                       "parent"         => 0,
                                                       "Test::Fatal"    => 0,
                                                       "Test::More"     => 0.96,
                                                       "Test::Requires" => 0,
                                                     },
                                     },
                      },
  "provides"       => {
                        "Class::XSConstructor" => { file => "lib/Class/XSConstructor.pm", version => 0.016001 },
                        "Class::XSDelegation"  => { file => "lib/Class/XSDelegation.pm", version => 0.016001 },
                        "Class::XSDestructor"  => { file => "lib/Class/XSDestructor.pm", version => 0.016001 },
                      },
  "release_status" => "stable",
  "resources"      => {
                        bugtracker   => {
                                          web => "https://github.com/tobyink/p5-class-xsconstructor/issues",
                                        },
                        homepage     => "https://metacpan.org/release/Class-XSConstructor",
                        license      => ["http://dev.perl.org/licenses/"],
                        repository   => {
                                          type => "git",
                                          url  => "git://github.com/tobyink/p5-class-xsconstructor.git",
                                          web  => "https://github.com/tobyink/p5-class-xsconstructor",
                                        },
                        x_identifier => "http://purl.org/NET/cpan-uri/dist/Class-XSConstructor/project",
                      },
  "version"        => 0.016001,
};

my %dynamic_config;
do {
$meta->{prereqs}{runtime}{requires}{'MRO::Compat'}   = '0'  if $] < 5.010;

if ($ENV{EXTENDED_TESTING}) {
	$meta->{prereqs}{test}{requires}{'Types::Standard'} = '1.002000';
}

# Only overwrite bundled version of ppport.h if newer than 3.42.
if (eval "use Devel::PPPort 3.42; 1") {
	Devel::PPPort::WriteFile();
}

};

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

