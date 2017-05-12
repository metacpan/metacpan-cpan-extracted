use strict;
use warnings;
use ExtUtils::MakeMaker;

sub ls($) 
{
	my $d = shift;
	opendir D, $d or die $!;
	map { "$d/$_" } grep { -f "$d/$_" } readdir D;
}

WriteMakefile(
    NAME	 => 'App::PLab',
    VERSION_FROM => 'lib/App/PLab.pm',
    EXE_FILES    => [ ls 'bin' ],
    PREREQ_PM    => {
    	Prima         => 0,
	'Prima::IPA'  => 0,
	'XML::Parser' => 0,
    },
    ABSTRACT     => 'Internal PLab image processing tools',
    AUTHOR       => 'Dmitry Karasik <dk@plab.ku.dk>, Anton Berezin <tobez@plab.ku.dk>, Vadim Belman <voland@plab.ku.dk>',
);


