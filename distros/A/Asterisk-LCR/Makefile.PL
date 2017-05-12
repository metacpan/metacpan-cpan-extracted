use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Asterisk::LCR',
    'VERSION_FROM'	=> 'lib/Asterisk/LCR.pm', # finds $VERSION
    'EXE_FILES'         => [ qw (bin/asterisk-lcr-build bin/asterisk-lcr-import bin/asterisk-lcr-dialplan bin/asterisk-lcr-myroutes) ],
    'PREREQ_PM'		=> {
	'Config::Mini'  => '0.01',
        'FreezeThaw'    => '0.43',
        'Finance::Currency::Convert::XE' => '0.10',
    },
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'lib/Asterisk/LCR.pm',
       AUTHOR        => 'Jean-Michel Hiver') : ()),
);


1;


package MY;

sub postamble {
    return <<EOF;
cover ::
	\$(RM_RF) cover_db
	PERL5OPT=-MDevel::Cover \$(MAKE) test || true
	cover -report html cover_db > /dev/null

EOF

}


1;
