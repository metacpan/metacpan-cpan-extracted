use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Dancer::Plugin::FakeCGI',
    VERSION_FROM      => 'lib/Dancer/Plugin/FakeCGI.pm', # finds $VERSION
    PREREQ_PM         => {
						'Dancer' => 1.3098,
						'Dancer::Plugin' => 0,
						'Cwd' => 0,
						'CGI::Compile' => 0,
						'HTTP::Message' => 0,
						'Test::TinyMocker' => 0,
						'Symbol' => 0,
						'IO::File' => 0,
						'IO::Scalar' => 0,
						'File::Temp' => 0,
						'Fcntl' => 0,
						'File::Spec' => 0,
						'File::Find::Rule' => 0,
						'Capture::Tiny' => 0,
						}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Dancer/Plugin/FakeCGI.pm', # retrieve abstract from module
       AUTHOR         => 'Igor Bujna <igor.bujna@post.cz>') : ()),
);


