use 5.008_001;
use strict;
use warnings;
use ExtUtils::MakeMaker;

use lib qw(lib);
use DBI::Test::Conf ();

my @generated_tests = DBI::Test::Conf->setup( AUTHOR_TESTS => 0, SKIP_FILE => "DBI-TEST.SKIP" );

my %eumm_opt = (
    MIN_PERL_VERSION => '5.008001',
    META_MERGE       => {
	resources => {
	    repository  => 'https://github.com/perl5-dbi/DBI-Test',
	    license     => 'http://dev.perl.org/licenses/',
	    },
	},
    NAME             => 'DBI::Test',
    VERSION_FROM     => 'lib/DBI/Test.pm',
    ABSTRACT_FROM    => 'lib/DBI/Test.pm',
    dist             => {
	SUFFIX          => '.gz',
	DIST_DEFAULT    => 'manifest tardist',
	COMPRESS        => 'gzip -9vf',
	},
    BUILD_REQUIRES   => {
	'Test::Simple'  => '0.90',
	},
    LICENSE          => 'perl',
    AUTHOR           => 'The DBI team <dbi-dev@perl.org>',
    clean            => {
	FILES           => join( " " => @generated_tests ),
    },
    test             => {
	TESTS           => join (' ' => 'xt/*.t', @generated_tests),
	},
    );

# Backward compatibility issues for EU::MM
{   my $eumm_version = $ExtUtils::MakeMaker::VERSION;
       $eumm_version =~ s/[^0-9.].*//; # Strip devel part
    $eumm_version < 6.5503 and #EUMM 6.5502 has problems with BUILD_REQUIRES
	$eumm_opt{PREREQ_PM} = {
	    %{$eumm_opt{PREREQ_PM} || {}},
	    %{delete $eumm_opt{BUILD_REQUIRES}},
	    };
    $eumm_version < 6.48 and delete $eumm_opt{MIN_PERL_VERSION};
    $eumm_version < 6.46 and delete $eumm_opt{META_MERGE};
    $eumm_version < 6.31 and delete $eumm_opt{LICENSE};
    }

WriteMakefile (%eumm_opt);

package MY;

sub postamble
{
    join "\n" =>
	'cover:',
	'	ccache -C',
	'	-@rm -f *.gc??',
	'	cover -test',
	'',
	'spellcheck:',
	'	pod-spell-check --aspell --ispell',
	'',
	'tgzdist:	spellcheck $(DISTVNAME).tar.gz distcheck',
	'	-@mv -f $(DISTVNAME).tar.gz $(DISTVNAME).tgz',
	'	-@cpants_lint.pl $(DISTVNAME).tgz',
	'	-@rm -f Debian_CPANTS.txt';
    } # postamble
