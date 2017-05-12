
use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile being created.
WriteMakefile(
	'NAME' => 'Callback',
	'DISTNAME' => 'Callback',
	'VERSION_FROM' => 'Callback.pm',
	($] >= 5.005 ?
	    ('ABSTRACT' => 'Create function callback objects',
	     'AUTHOR'	=> 'David Muir Sharnoff <muir@idiom.com>') : ()),
	'dist'   => {COMPRESS=>'gzip', SUFFIX=>'gz'}
);

package MY;

sub postamble {
    <<"END_OF_POSTAMBLE";

pm_to_blib: README

README: Callback.pod
\tCOLUMNS=80 pod2text Callback.pod >README

END_OF_POSTAMBLE
}
