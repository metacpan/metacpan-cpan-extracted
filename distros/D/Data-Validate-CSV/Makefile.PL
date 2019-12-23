use strict;
use ExtUtils::MakeMaker 6.17;

my $EUMM = eval( $ExtUtils::MakeMaker::VERSION );

my $meta = {
  "abstract"       => "read and validate CSV",
  "author"         => ["Toby Inkster (TOBYINK) <tobyink\@cpan.org>"],
  "dynamic_config" => 1,
  "generated_by"   => "Dist::Inkt::Profile::TOBYINK version 0.024, CPAN::Meta::Converter version 2.150010",
  "keywords"       => [],
  "license"        => ["perl_5"],
  "meta-spec"      => {
                        url => "http://search.cpan.org/perldoc?CPAN::Meta::Spec",
                        version => 2,
                      },
  "name"           => "Data-Validate-CSV",
  "no_index"       => { directory => ["eg", "examples", "inc", "t", "xt"] },
  "prereqs"        => {
                        configure => {
                                       requires => { "ExtUtils::HasCompiler" => 0.014, "ExtUtils::MakeMaker" => 6.17 },
                                     },
                        develop   => { recommends => { "Dist::Inkt" => 0.001 } },
                        runtime   => {
                                       recommends => { "Text::CSV_XS" => 0 },
                                       requires   => {
                                                       "DateTime" => 0,
                                                       "DateTime::Duration" => 0,
                                                       "DateTime::Format::CLDR" => 0,
                                                       "DateTime::Incomplete" => 0,
                                                       "JSON::PP" => 0,
                                                       "Moo" => 0,
                                                       "namespace::autoclean" => 0,
                                                       "Path::Tiny" => 0,
                                                       "perl" => "5.012000",
                                                       "PerlX::Maybe" => 0,
                                                       "Types::Path::Tiny" => 0,
                                                       "Types::Standard" => 0,
                                                       "Types::XSD" => 0,
                                                     },
                                     },
                        test      => { requires => { "Test::More" => 0.96 } },
                      },
  "provides"       => {
                        "Data::Validate::CSV"                  => { file => "lib/Data/Validate/CSV.pm", version => 0.003 },
                        "Data::Validate::CSV::Cell"            => { file => "lib/Data/Validate/CSV/Cell.pm", version => 0.003 },
                        "Data::Validate::CSV::Column"          => { file => "lib/Data/Validate/CSV/Column.pm", version => 0.003 },
                        "Data::Validate::CSV::MultiValueCell"  => { file => "lib/Data/Validate/CSV/MultiValueCell.pm", version => 0.003 },
                        "Data::Validate::CSV::Note"            => { file => "lib/Data/Validate/CSV/Note.pm", version => 0.003 },
                        "Data::Validate::CSV::Row"             => { file => "lib/Data/Validate/CSV/Row.pm", version => 0.003 },
                        "Data::Validate::CSV::Schema"          => { file => "lib/Data/Validate/CSV/Schema.pm", version => 0.003 },
                        "Data::Validate::CSV::SingleValueCell" => {
                                                                    file => "lib/Data/Validate/CSV/SingleValueCell.pm",
                                                                    version => 0.003,
                                                                  },
                        "Data::Validate::CSV::Table"           => { file => "lib/Data/Validate/CSV/Table.pm", version => 0.003 },
                        "Data::Validate::CSV::Types"           => { file => "lib/Data/Validate/CSV/Types.pm", version => 0.003 },
                      },
  "release_status" => "stable",
  "resources"      => {
                        bugtracker   => {
                                          web => "http://rt.cpan.org/Dist/Display.html?Queue=Data-Validate-CSV",
                                        },
                        homepage     => "https://metacpan.org/release/Data-Validate-CSV",
                        license      => ["http://dev.perl.org/licenses/"],
                        repository   => {
                                          type => "git",
                                          url  => "git://github.com/tobyink/p5-data-validate-csv.git",
                                          web  => "https://github.com/tobyink/p5-data-validate-csv",
                                        },
                        x_identifier => "http://purl.org/NET/cpan-uri/dist/Data-Validate-CSV/project",
                      },
  "version"        => 0.003,
};

my %dynamic_config;
do {
{
	sub parse_args {
		require ExtUtils::MakeMaker;
		require Text::ParseWords;
		ExtUtils::MakeMaker::parse_args(
			my $tmp = {},
			Text::ParseWords::shellwords($ENV{PERL_MM_OPT} || ''),
			@ARGV,
		);
		return $tmp->{ARGS} || {};
	}
	use ExtUtils::HasCompiler 0.014 'can_compile_loadable_object';
	my $can_xs;
	sub can_xs {
		return $can_xs if defined $can_xs;
		$can_xs = can_compile_loadable_object(quiet => 1) ? 1 : 0;
	}
	my $want_pp;
	sub want_pp {
		return $want_pp if defined $want_pp;
		$want_pp = parse_args()->{PUREPERL_ONLY} ? 1 : 0
	}
}

if (want_pp) {
	$meta->{prereqs}{test}{requires}{'Text::CSV'} = '0';
}
elsif (eval { require Text::CSV_XS; 1 }) {
	$meta->{prereqs}{test}{requires}{'Text::CSV_XS'} = '0';
}
elsif (eval { require Text::CSV; 1 }) {
	$meta->{prereqs}{test}{requires}{'Text::CSV'} = '0';
}
elsif (can_xs) {
	$meta->{prereqs}{test}{requires}{'Text::CSV_XS'} = '0';
}
else {
	$meta->{prereqs}{test}{requires}{'Text::CSV'} = '0';
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

