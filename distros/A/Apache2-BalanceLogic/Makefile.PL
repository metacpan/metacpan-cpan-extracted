use 5.008008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Apache2::BalanceLogic',
    VERSION_FROM      => 'lib/Apache2/BalanceLogic.pm', # finds $VERSION
    PREREQ_PM         => {
	Apache2::RequestRec	=> 2.000002,
	Apache2::RequestIO	=> 2.000002,
	Apache2::Connection	=> 2.000002,
	APR::Table		=> 0.009000,
	Apache2::Const		=> 2.000002,
	YAML			=> 0.65,
	CGI::Cookie		=> 1.26,
	Net::CIDR::Lite		=> 0.20,
	UNIVERSAL::require	=> 0.11,
	},
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Apache2/BalanceLogic.pm', # retrieve abstract from module
       AUTHOR         => 'Takeshi Miki <miki@cpan.org>') : ()),
    LIBS              => [''], # e.g., '-lm'
    DEFINE            => '', # e.g., '-DHAVE_SOMETHING'
    INC               => '-I.', # e.g., '-I. -I/usr/include/other'
	# Un-comment this if you add C files to link with later:
    # OBJECT            => '$(O_FILES)', # link all the C files too
);
