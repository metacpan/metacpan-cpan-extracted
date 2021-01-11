use strict;
use warnings;

use 5.012002;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME		=> 'BSD::Socket::Splice',
    VERSION_FROM	=> 'lib/BSD/Socket/Splice.pm',
    PREREQ_PM		=> {},
    ABSTRACT_FROM	=> 'lib/BSD/Socket/Splice.pm',
    AUTHOR		=> 'Alexander Bluhm <bluhm@cpan.org>',
    LIBS		=> [''],
    LICENSE		=> 'perl_5',
    DEFINE		=> '',
    INC			=> '-I.',
    SIGN		=> 1,
    META_MERGE => {
	'meta-spec' => { version => 2 },
	resources => {
	    repository => {
		type => 'git',
		url  => 'git://github.com/bluhm/p5-bsd-socket-splice.git',
		web  => 'https://github.com/bluhm/p5-bsd-socket-splice',
	    },
	},
    },
);
