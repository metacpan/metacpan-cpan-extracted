use 5.006002;	# for 'our'.

use strict;
use warnings;

use lib qw{ inc };

use My::Module::Meta;
use My::Module::Recommend;
use Config;
use ExtUtils::MakeMaker qw{WriteMakefile prompt};
use FileHandle;
use Getopt::Std;

my %opt;
getopts ('ny', \%opt) or die <<eod;
The only legal options are
  -n = answer all questions 'no'.
  -y = answer all questions 'yes'.
You may not assert both of these at once - it is too confusing.
eod

my @exe_files;
my @clean_files;

My::Module::Recommend->recommend();

print <<"EOD";

The following executable can be installed:

  satpass is a scriptable program to predict satellite passes
    over a given observer.

If you do not want this, run Makefile.PL with the -n option. If you want
to install without being asked, run Makefile.PL with the -y option.

>>>> NOTICE <<<<\a\a\a

As of release 0.066, this script no longer asks whether
the satpass script should be installed, since it is being deprecated
(slowly) in favor of Astro::App::Satpass2. If you want the satpass
script installed, you should run this script with the -y option. You can
make this the default in your CPAN client by installing the preferences
file eg/Astro-Coord-ECI.yml in .cpan/prefs.

EOD

my @possible_exes = qw{satpass};
if ( $opt{n} ) {
    print "Because you have asserted -n, the executables will not be installed.\n\n";
} elsif ( $opt{y} ) {
    print "Because you have asserted -y, the executables will be installed.\n\n";
    @exe_files = @possible_exes;
}

if (@exe_files) {
    if ($^O eq 'MSWin32') {
	@exe_files = map {"script/$_"} @exe_files;
	foreach (@exe_files) {`pl2bat $_`}
	@clean_files = @exe_files =
	    grep {-e $_} map {"$_.bat"} @exe_files;
    } elsif ($^O eq 'VMS') {
	foreach my $fni (map {"[.script]$_"} @exe_files) {
	    my $fno = "$fni.com";
	    my $fhi = FileHandle->new ("<$fni") or die <<eod;
Error - Unable to open $fni
        $!
eod
	    my $fho = FileHandle->new (">$fno") or die <<eod;
Error - Unable to open $fno
        $!
eod
	    print $fho "$Config{startperl}\n";
	    while (<$fhi>) {print $fho $_}
	    }
	@clean_files = @exe_files = map {"[.script]$_.com"} @exe_files;
    } else {
	@exe_files = map {"script/$_"} @exe_files;
    }
}

##my $vers = $] >= 5.008 ? '-5.8' : '';
my $vers = '';

(my $mmv = ExtUtils::MakeMaker->VERSION) =~ s/_//g;

my $meta = My::Module::Meta->new();

my %attr = (
    NAME => 'Astro::Coord::ECI',
    DISTNAME => 'Astro-satpass',
    VERSION_FROM => 'lib/Astro/Coord/ECI.pm',
    PREREQ_PM => $meta->requires(),
    PL_FILES => {},	# Prevent old MakeMaker from running Build.PL
    EXE_FILES => \@exe_files,
    'dist' => {COMPRESS => 'gzip', SUFFIX => 'gz'},
    realclean => {FILES => join ' ', @clean_files},
    AUTHOR => 'Tom Wyant (wyant at cpan dot org)',
    ABSTRACT => 'Classes and app to compute satellite visibility',
#   BINARY_LOCATION => "$Config{archname}$vers/Astro-satpass.tar.gz",
    realclean	=> { FILES => 'cover_db xt/author/optionals' },
);

$mmv >= 6.31 and $attr{LICENSE} = 'perl';

$mmv >= 6.4501
    and $attr{META_MERGE} = $meta->meta_merge(
	$meta->provides(),
    );

$mmv >= 6.4701 and $attr{MIN_PERL_VERSION} = $meta->requires_perl();

$mmv >= 6.5501
    and $attr{BUILD_REQUIRES} = $meta->build_requires()
    or $mmv >= 6.4501
    and $attr{META_MERGE}{build_requires} = $meta->build_requires();

WriteMakefile (%attr);

sub MY::postamble {
    my ( $self, @args ) = @_;

    my $authortest = $self->test_via_harness(
	'$(FULLPERLRUN)', '$(AUTHORTEST_FILES)' );
    $authortest =~ s/ \s+ \z //smx;
    $authortest =~ s/ \A \s+ //smx;
    chomp $authortest;

    return <<"EOD";

AUTHORTEST_FILES = t/*.t xt/author/*.t xt/author/optionals/*.t

authortest :: pure_all
	\$(FULLPERLRUN) "-Iinc" "-MMy::Module::Recommend" "-e" "My::Module::Recommend->make_optional_modules_tests()"
	AUTHOR_TESTING=1 $authortest

testcover :: pure_all
	cover -test -ignore_re=inc/
EOD
}

# ex: set textwidth=72 :
