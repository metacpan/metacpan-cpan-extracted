use ExtUtils::MakeMaker;

use Config;
my $define='';
if ($Config{longsize} ne '4') { $define='-DMY_64bit_FIX_NEEDED'; }

WriteMakefile(
	NAME      => 'Crypt::Tea_JS',
	VERSION_FROM => 'Tea_JS.pm',
	EXE_FILES => [ glob "bin/*" ],
	AUTHOR    => 'PJB, Peter Billam, www.pjb.com.au/comp/contact.html',
	ABSTRACT  => 'The New Tiny Encryption Algorithm in Perl and JS',
	dist      => {COMPRESS=>'gzip -9f', SUFFIX => 'gz'},
	LIBS      => [''], # e.g., '-lm'
	DEFINE    => $define, # e.g., '-DHAVE_SOMETHING'
	INC       => '-I.', # e.g., '-I. -I/usr/include/other'
);

#do './Tea_JS.pm';   # this fails when installing with cpan :-(
# now incuded in tarball
#if (open(F, '>Tea_JS.js')) { 
#	print F Crypt::Tea_JS::tea_in_javascript();
#	close F;
#}
