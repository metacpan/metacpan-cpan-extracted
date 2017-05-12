use 5.006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Aut::UI::Wx',
    'VERSION_FROM'	=> 'lib/Aut/UI/Wx.pm', 
    'PREREQ_PM'		=> { Wx => 0.18, Aut => 0.05 },
    'ABSTRACT_FROM'     => 'lib/Aut/UI/Wx.pm',
    'AUTHOR'            => 'Hans Oesterholt-Dijkema <oesterhol@cpan.org>'
);

