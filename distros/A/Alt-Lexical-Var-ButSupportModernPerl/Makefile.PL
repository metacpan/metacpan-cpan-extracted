use strict;
use ExtUtils::MakeMaker 6.17;

my $EUMM = eval( $ExtUtils::MakeMaker::VERSION );

my $meta = {
  "abstract"       => "alternative distribution of Lexical::Var, with support for more modern versions of Perl",
  "author"         => ["Andrew Main (Zefram) <zefram\@fysh.org>"],
  "dynamic_config" => 1,
  "generated_by"   => "Dist::Inkt::Profile::Simple version 0.026, CPAN::Meta::Converter version 2.150010",
  "license"        => ["perl_5"],
  "meta-spec"      => {
                        url => "http://search.cpan.org/perldoc?CPAN::Meta::Spec",
                        version => 2,
                      },
  "name"           => "Alt-Lexical-Var-ButSupportModernPerl",
  "no_index"       => {
                        directory => ["eg", "examples", "inc", "t", "xt"],
                        package   => ["Lexical::Var", "Lexical::Var", "Lexical::Sub"],
                      },
  "prereqs"        => {
                        configure => {
                                       recommends => { "CPAN::Meta::Requirements" => "2.000" },
                                       requires   => { "ExtUtils::MakeMaker" => 6.17 },
                                     },
                        runtime   => {
                                       conflicts => { "B::Hooks::OP::Check" => "< 0.19" },
                                       requires  => {
                                                      "Lexical::SealRequireHints" => 0.006,
                                                      "perl" => 5.008001,
                                                      "strict" => 0,
                                                      "warnings" => 0,
                                                      "XSLoader" => 0,
                                                    },
                                     },
                      },
  "provides"       => {
                        "Alt::Lexical::Var::ButSupportModernPerl" => {
                          file => "lib/Alt/Lexical/Var/ButSupportModernPerl.pm",
                          version => 0.001,
                        },
                      },
  "release_status" => "stable",
  "version"        => 0.001,
};

my %dynamic_config;
do {
$meta->{name}           = 'Lexical-Var';
$meta->{version}        = '0.009';
$dynamic_config{LIBS}   = [''];
$dynamic_config{DEFINE} = '';
$dynamic_config{INC}    = '-I.';

};
for my $stage (keys %{$meta->{prereqs}})
{
	my $conflicts = $meta->{prereqs}{$stage}{conflicts} or next;
	eval { require CPAN::Meta::Requirements } or last;
	$conflicts = 'CPAN::Meta::Requirements'->from_string_hash($conflicts);
	
	for my $module ($conflicts->required_modules)
	{
		eval "require $module" or next;
		my $installed = eval(sprintf('$%s::VERSION', $module));
		$conflicts->accepts_module($module, $installed) or next;
		
		my $message = "\n".
			"** This version of $meta->{name} conflicts with the version of\n".
			"** module $module ($installed) you have installed.\n";
		die($message . "\n" . "Bailing out")
			if $stage eq 'build' || $stage eq 'configure';
		
		$message .= "**\n".
			"** It's strongly recommended that you update it after\n".
			"** installing this version of $meta->{name}.\n";
		warn("$message\n");
	}
}

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

