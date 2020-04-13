use strict;
use warnings;
use ExtUtils::MakeMaker;

# Normalize version strings like 6.30_02 to 6.3002,
# so that we can do numerical comparisons on it.
my $eumm_version = $ExtUtils::MakeMaker::VERSION;
$eumm_version =~ s/_//;

WriteMakefile(
    NAME                => 'App::Mxpress::PDF',
    AUTHOR              => q{Robert Acock <email@lnation.org>},
    VERSION_FROM        => 'lib/App/Mxpress/PDF.pm',
    ABSTRACT            => 'A utility application for generating PDFs',
    "EXE_FILES" => [
	"bin/app-mxpress-pdf.psgi"
    ],
    ($eumm_version >= 6.3001
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'YAML'       => 0,
        'Dancer2'     => 0.300003,
	'Mxpress::PDF' => 0.21,
	'MetaCPAN::CLient::Pod::PDF' => 0.03,
	'Type::Tiny' => 0,
	'Crypt::SaltedHash' => 0,
	'Data::UUID' => 0
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'App-Mxpress-PDF-*' },
);
