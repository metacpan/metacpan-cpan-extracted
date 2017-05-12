use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME	=> 'DBZ_File',
    LIBS	=> ['-ldbz'],
    XSPROTOARG	=> '-noprototypes',		# XXX remove later?
    DEFINE	=> '',
    INC		=> '',
    VERSION_FROM => 'DBZ_File.pm',
);
