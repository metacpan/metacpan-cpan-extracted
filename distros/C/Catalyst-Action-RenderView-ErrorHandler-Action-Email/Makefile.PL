use 5.010001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Catalyst::Action::RenderView::ErrorHandler::Action::Email',
    VERSION_FROM      => 'lib/Catalyst/Action/RenderView/ErrorHandler/Action/Email.pm', # finds $VERSION
    PREREQ_PM         => {
		'Catalyst::Action::RenderView::ErrorHandler::Action' => 0,
		'Moose' => 0,
	},
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Catalyst/Action/RenderView/ErrorHandler/Action/Email.pm', # retrieve abstract from module
       AUTHOR         => 'Stefan Profanter <profanter@cpan.org>') : ()),
);
