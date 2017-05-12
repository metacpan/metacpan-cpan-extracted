use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Catalyst::Plugin::Redirect',
    AUTHOR         => 'Shota Takayam <shot@bindstorm.jp>',
    VERSION_FROM      => 'lib/Catalyst/Plugin/Redirect.pm', # finds $VERSION
    PREREQ_PM         => {
	Catalyst => 0}
);
