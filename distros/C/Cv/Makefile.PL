# -*- mode: perl; coding: utf-8; tab-width: 4; -*-

use 5.008008;
use ExtUtils::MakeMaker;

our %CONFIGURE_REQUIRES = (
	'ExtUtils::ParseXS'   => '2.220',
	'ExtUtils::PkgConfig' => '1.120',
	$^O eq 'cygwin' ? ('ExtUtils::MM_Cygwin' => '6.620') : (),
);

our %TEST_REQUIRES = (
	'Test::Number::Delta' => '1.030',
	'Test::Exception'     => '0.310',
	);

our %PREREQ_PM = ( %CONFIGURE_REQUIRES );

use lib qw(inc);
use Devel::CheckLib;
my $cv1 = check_lib(lib => 'cv');			# OpenCV-1.x
my $cv2 = check_lib(lib => 'opencv_core');	# OpenCV-2.x
check_lib_or_exit(lib => 'opencv_core') unless $cv1 + $cv2;

use lib qw(lib);
eval "use Cv::Config";
if ($@) {
	warn "=" x 60, "\n";
	warn "See README to install this module\n";
	warn "=" x 60, "\n";
	exit 0;
}

my $cf = new Cv::Config;

my @perl_h = qw(perl.h sv.h pp.h);

# patch CORE/*ph
{
	use Config;
	my $CORE = join('/', $Config{archlib}, 'CORE');
	foreach my $h (@perl_h) {
		if (open(PHI, "<$CORE/$h")) {
			my $patched = "lib/Cv/$h";
			open(PHO, ">$patched");
			while (<PHI>) {
				s/\bstruct\s+cv\b/struct STRUCT_CV/g;
				s/\bNORMAL\b/Perl_NORMAL/g;
				print PHO;
			}
			close PHO;
			close PHI;
			push(@perl_h_patched, $patched);
		}
	}
}

# make lib/Cv/Constant.pm
{
	use version;
	my $dst = "lib/Cv/Constant.pm";
	my $tmp = "a.pm";
	my @inc = map { substr($_, 2) } grep /^-I/, split(/\s+/, $cf->ccflags);
	unless (&dumpconst('-v', '-o', $tmp, @inc) == 0) {
		my $fallback = 'fallback/Constant.pm';
		my $ver = $cf->_version;
		my @ver = sort { $b <=> $a } grep { ref $_ && $_ <= $ver } map {
			/-([\d\.]+)$/ && version->parse($1) } glob("$fallback-*");
		die "$0: can't make $dst\n" unless @ver;
		&cp("$fallback-$ver[0]", $tmp);
	}
	if (!-f $dst || &cmp('-s', $tmp, $dst) != 0) {
		&mv($dst, "$dst.bak") if -f $dst;
		&cp($tmp, $dst);
	}
	&rm('-f', $tmp);
}

# make lib/Cv/typemap
{
	my $src = 'typemap.in';
	my $dst = 'lib/Cv/typemap';
	my $tmp = 'a.map';
	unless (&fixtypemap('-o', $tmp, $src) == 0) {
		die "can't make typemap\n";
	}
	if (!-f $dst || &cmp('-s', $tmp, $dst) != 0) {
		&mv($dst, "$dst.bak") if -f $dst;
		&cp($tmp, $dst);
	}
	&rm('-f', $tmp);
}


my @dir = qw();
push(@dir, qw(BGCodeBookModel));
push(@dir, qw(Histogram));
push(@dir, qw(Subdiv2D));
push(@dir, qw(Qt)) if $cf->hasqt;

WriteMakefile(
	NAME => 'Cv',
	VERSION_FROM => "lib/Cv.pm", # finds $VERSION
	ABSTRACT_FROM => "lib/Cv.pm",
	AUTHOR => 'MASUDA Yuta <yuta.cpan@gmail.com>',
	CONFIGURE_REQUIRES => \%CONFIGURE_REQUIRES,
	TEST_REQUIRES => \%TEST_REQUIRES,
	PREREQ_PM => \%PREREQ_PM,
	%Cv::Config::MM,
	INC => '-I.',
	XSOPT => '-C++ -hiertype',
	dynamic_lib => $cf->dynamic_lib,
	DIR => [ @dir ],
	LICENSE => 'perl',
	depend => { 'Cv.xs' => 'lib/Cv/Cv.inc' },
	clean => {
		FILES => [
			@perl_h_patched, 'lib/Cv/Constant.pm*', 'Test.bs', 'a.pm', '*.tmp',
			't/ref-*.pm', 't/auto', 'camera.xml', 'contours.xml', 'sample.avi',
			'_Inline', 'cover_db',
			] },
	);

sub MY::dynamic {
    my($self) = shift;
    '
dynamic :: $(FIRST_MAKEFILE) $(INST_DYNAMIC) $(INST_BOOT)
	$(NOECHO) $(NOOP)
	@if [ $(FULLEXT) = Cv -a -f t.xs ]; then \
		make INST_ARCHLIB=t BASEEXT=t FULLEXT=Cv/t dynamic; \
	fi

';
}

sub MY::postamble {
	"

ref:
	./tools/ref2pl-all.pl |sh -x

const:
	./tools/dumpconst-all.pl |sh -x

cover:
	cover -delete
	-HARNESS_PERL_SWITCHES=-MDevel::Cover make test
	cover
	find cover_db -type d |xargs chmod +rx

";
}

sub AUTOLOAD {
	our $AUTOLOAD;
	(my $program = $AUTOLOAD) =~ s/.*:://;
	my @program = grep { -x $_ } (
		"./tools/$program.pl",
		"/usr/local/bin/$program",
		"/usr/bin/$program",
		"/bin/$program",
	);
	if (@program) {
		print STDERR join(' ', $program[0], @_), "\n";
		return system($program[0], @_);
	}
	die "$0: ?$program\n";
}
