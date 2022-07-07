use strict;
use ExtUtils::MakeMaker 6.17;

my $EUMM = eval( $ExtUtils::MakeMaker::VERSION );

my $meta = {
  "abstract"       => "example of distributing instance data on CPAN",
  "author"         => ["Toby Inkster (TOBYINK) <tobyink\@cpan.org>"],
  "dynamic_config" => 1,
  "generated_by"   => "Dist::Inkt::Profile::TOBYINK version 0.024, CPAN::Meta::Converter version 2.150010",
  "keywords"       => [],
  "license"        => ["perl_5"],
  "meta-spec"      => {
                        url => "http://search.cpan.org/perldoc?CPAN::Meta::Spec",
                        version => 2,
                      },
  "name"           => "Acme-Marvel-CinematicUniverse-Characters",
  "no_index"       => { directory => ["eg", "examples", "inc", "t", "xt"] },
  "prereqs"        => {
                        configure => { requires => { "ExtUtils::MakeMaker" => 6.17 } },
                        develop   => { recommends => { "Dist::Inkt" => 0.001 } },
                        runtime   => { requires => { "Module::Pluggable" => 0, "perl" => 5.008001 } },
                        test      => { requires => { "Test::More" => 0.96 } },
                      },
  "provides"       => {
                        "Acme::Marvel::CinematicUniverse::Character"                             => {
                                                                                                      file => "lib/Acme/Marvel/CinematicUniverse/Character.pm",
                                                                                                      version => 0.003,
                                                                                                    },
                        "Acme::Marvel::CinematicUniverse::Character::Instance::Bruce_Banner"     => {
                                                                                                      file => "lib/Acme/Marvel/CinematicUniverse/Character/Instance/Bruce_Banner.pm",
                                                                                                      version => 0.003,
                                                                                                    },
                        "Acme::Marvel::CinematicUniverse::Character::Instance::Clint_Barton"     => {
                                                                                                      file => "lib/Acme/Marvel/CinematicUniverse/Character/Instance/Clint_Barton.pm",
                                                                                                      version => 0.003,
                                                                                                    },
                        "Acme::Marvel::CinematicUniverse::Character::Instance::Natasha_Romanoff" => {
                                                                                                      file => "lib/Acme/Marvel/CinematicUniverse/Character/Instance/Natasha_Romanoff.pm",
                                                                                                      version => 0.003,
                                                                                                    },
                        "Acme::Marvel::CinematicUniverse::Character::Instance::Steve_Rogers"     => {
                                                                                                      file => "lib/Acme/Marvel/CinematicUniverse/Character/Instance/Steve_Rogers.pm",
                                                                                                      version => 0.003,
                                                                                                    },
                        "Acme::Marvel::CinematicUniverse::Character::Instance::Thor_Odinson"     => {
                                                                                                      file => "lib/Acme/Marvel/CinematicUniverse/Character/Instance/Thor_Odinson.pm",
                                                                                                      version => 0.003,
                                                                                                    },
                        "Acme::Marvel::CinematicUniverse::Character::Instance::Tony_Stark"       => {
                                                                                                      file => "lib/Acme/Marvel/CinematicUniverse/Character/Instance/Tony_Stark.pm",
                                                                                                      version => 0.003,
                                                                                                    },
                        "Acme::Marvel::CinematicUniverse::Characters"                            => {
                                                                                                      file => "lib/Acme/Marvel/CinematicUniverse/Characters.pm",
                                                                                                      version => 0.003,
                                                                                                    },
                        "Acme::Marvel::CinematicUniverse::Mite"                                  => { file => "lib/Acme/Marvel/CinematicUniverse/Mite.pm" },
                      },
  "release_status" => "stable",
  "resources"      => {
                        bugtracker   => {
                                          web => "http://rt.cpan.org/Dist/Display.html?Queue=Acme-Marvel-CinematicUniverse-Characters",
                                        },
                        homepage     => "https://metacpan.org/release/Acme-Marvel-CinematicUniverse-Characters",
                        license      => ["http://dev.perl.org/licenses/"],
                        repository   => {
                                          type => "git",
                                          url  => "git://github.com/tobyink/p5-acme-marvel-cinematicuniverse-characters.git",
                                          web  => "https://github.com/tobyink/p5-acme-marvel-cinematicuniverse-characters",
                                        },
                        x_identifier => "http://purl.org/NET/cpan-uri/dist/Acme-Marvel-CinematicUniverse-Characters/project",
                      },
  "version"        => 0.003,
};

my %dynamic_config;
do {
if ($] < 5.010000) {
	$meta->{prereqs}{runtime}{requires}{'MRO::Compat'} = 0;
}

if ($] < 5.014000) {
        $meta->{prereqs}{runtime}{requires}{'Devel::GlobalDestruction'} = 0;
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

