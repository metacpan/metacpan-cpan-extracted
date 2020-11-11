use strict;
use ExtUtils::MakeMaker 6.17;

my $EUMM = eval( $ExtUtils::MakeMaker::VERSION );

my $meta = {
  "abstract"       => "ask your users about stuff",
  "author"         => ["Toby Inkster (TOBYINK) <tobyink\@cpan.org>"],
  "dynamic_config" => 1,
  "generated_by"   => "Dist::Inkt::Profile::TOBYINK version 0.024, CPAN::Meta::Converter version 2.150010",
  "keywords"       => [],
  "license"        => ["perl_5"],
  "meta-spec"      => {
                        url => "http://search.cpan.org/perldoc?CPAN::Meta::Spec",
                        version => 2,
                      },
  "name"           => "Ask",
  "no_index"       => { directory => ["eg", "examples", "inc", "t", "xt"] },
  "prereqs"        => {
                        configure => { requires => { "ExtUtils::MakeMaker" => 6.17 } },
                        runtime => {
                          recommends => {
                                          "Caroline" => 0,
                                          "File::Which" => 0,
                                          "Gtk2" => 0,
                                          "System::Command" => 0,
                                          "Term::ANSIColor" => 0,
                                          "Term::Clui" => 0,
                                          "Tk" => 0,
                                        },
                          requires   => {
                                          "Exporter::Shiny" => 0,
                                          "Lingua::Boolean::Tiny" => 0.003,
                                          "Module::Pluggable" => 0,
                                          "Module::Runtime" => 0,
                                          "Moo" => 1.000006,
                                          "namespace::autoclean" => 0,
                                          "Path::Tiny" => 0,
                                          "perl" => 5.008008,
                                          "Type::Utils" => 0,
                                        },
                          suggests   => { Prima => 0, Wx => 0 },
                        },
                        test => { requires => { "Test::More" => 0.98 } },
                      },
  "provides"       => {
                        "Ask"            => { file => "lib/Ask.pm", version => 0.015 },
                        "Ask::API"       => { file => "lib/Ask/API.pm", version => 0.015 },
                        "Ask::Callback"  => { file => "lib/Ask/Callback.pm", version => 0.015 },
                        "Ask::Caroline"  => { file => "lib/Ask/Caroline.pm", version => 0.015 },
                        "Ask::Clui"      => { file => "lib/Ask/Clui.pm", version => 0.015 },
                        "Ask::Fallback"  => { file => "lib/Ask/Fallback.pm", version => 0.015 },
                        "Ask::Functions" => { file => "lib/Ask/Functions.pm", version => 0.015 },
                        "Ask::Gtk"       => { file => "lib/Ask/Gtk.pm", version => 0.015 },
                        "Ask::Prima"     => { file => "lib/Ask/Prima.pm", version => 0.015 },
                        "Ask::Question"  => { file => "lib/Ask/Question.pm", version => 0.015 },
                        "Ask::STDIO"     => { file => "lib/Ask/STDIO.pm", version => 0.015 },
                        "Ask::Tk"        => { file => "lib/Ask/Tk.pm", version => 0.015 },
                        "Ask::Wx"        => { file => "lib/Ask/Wx.pm", version => 0.015 },
                        "Ask::Zenity"    => { file => "lib/Ask/Zenity.pm", version => 0.015 },
                        "AskX::AutoLang" => { file => "lib/AskX/AutoLang.pm", version => 0.015 },
                      },
  "release_status" => "stable",
  "resources"      => {
                        bugtracker   => { web => "http://rt.cpan.org/Dist/Display.html?Queue=Ask" },
                        homepage     => "https://metacpan.org/release/Ask",
                        license      => ["http://dev.perl.org/licenses/"],
                        repository   => {
                                          type => "git",
                                          url  => "git://github.com/tobyink/p5-ask.git",
                                          web  => "https://github.com/tobyink/p5-ask",
                                        },
                        x_identifier => "http://purl.org/NET/cpan-uri/dist/Ask/project",
                      },
  "version"        => 0.015,
  "x_contributors" => ["Graham Knop (HAARG) <haarg\@cpan.org>"],
};

my %dynamic_config;
do {
if ( $ENV{'TRAVIS'} ) {
	delete $meta->{prereqs}{runtime}{recommends}{'Gtk2'};
	delete $meta->{prereqs}{runtime}{recommends}{'Tk'};
	delete $meta->{prereqs}{runtime}{recommends}{'Wx'};
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

