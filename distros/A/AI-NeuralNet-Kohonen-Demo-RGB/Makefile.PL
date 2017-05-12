use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'AI::NeuralNet::Kohonen::Demo::RGB',
    'VERSION_FROM'	=> 'RGB.pm', # finds $VERSION
    'PREREQ_PM'		=> {
		AI::NeuralNet::Kohonen	=> 0.11,
		Tk						=> 0.1,
		Tk::Canvas				=> 0.1,
		Tk::Label				=> 0.1,
	},
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'RGB.pm', # retrieve abstract from module
       AUTHOR     => 'Lee Goddard <lgoddard@cpan.org>') : ()),
);


