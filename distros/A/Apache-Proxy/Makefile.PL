use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

use ExtUtils::testlib;
use lib qw(../blib/lib ../blib/arch ../lib);

use Apache::src ();
my $src = Apache::src->new;

WriteMakefile(
    'NAME'	=> 'Apache::Proxy',
    'VERSION_FROM' => 'Proxy.pm', # finds $VERSION
    'LIBS'	=> [''],   # e.g., '-lm' 
    'DEFINE'	=> '',     # e.g., '-DHAVE_SOMETHING' 
    'INC'	=> $src->inc,     # e.g., '-I/usr/include/other' 
    'TYPEMAPS'  => $src->typemaps,
    'dist'    => {
        COMPRESS=> 'gzip -9f', SUFFIX=>'gz',
        CI => qq(ci -u -m\\"See Changes file\\"),
        PREOP => 'co -l README && pod2text Proxy.pm > README && ci -u README',
    },         
);
