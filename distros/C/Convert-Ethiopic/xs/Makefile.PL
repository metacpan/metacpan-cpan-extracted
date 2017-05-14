
print STDERR "Using compatibility macros/routines for Perl 5.004\n"
    if ($] < 5.0045);


use ExtUtils::MakeMaker;

my $INC = "-I" . prompt ( 'Where is your libeth source tree?' );

die ( 'Build aborted, the libeth headers are required for the Convert::Ethiopic package.' ) if ( $INC eq "-I" );

my $DEFLANG = "-DDEFAULTLANG=";

my %Langs = ( a => 'amh', g => 'geez', t => 'tigrigna' );

my $lang  = $Langs { lc ( prompt ( 'What default language should be used [a]mharic, [g]eez, [t]igrigna?' ) ) };

die ( 'Build aborted, unrecognized language.' ) unless ( $lang );

$DEFLANG .= $lang;


WriteMakefile(
	NAME			=> 'Convert::Ethiopic',
	DISTNAME		=> 'Convert-Ethiopic',
	VERSION_FROM		=> '../lib/Convert/Ethiopic.pm', # finds $VERSION
	LIBS			=> ['-lm -leth'],
	INC			=> $INC,
	DEFINE			=> $DEFLANG,

	AUTHOR          => "Daniel Yacob <Yacob\@EthiopiaOnine.Net>",
	ABSTRACT        => "Interface to the ActiveWorks Libraries.",
);
