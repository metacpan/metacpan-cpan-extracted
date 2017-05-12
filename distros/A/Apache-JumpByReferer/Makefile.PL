package Apache::JumpByReferer;

use ExtUtils::MakeMaker;

WriteMakefile(
	NAME => __PACKAGE__,
	VERSION_FROM => 'lib/Apache/JumpByReferer.pm', # finds $VERSION
	PREREQ_PM => {
		mod_perl               => 0,
		'Apache::Log'          => 0,
		'Apache::Constants'    => 0,
		'Text::ParseWords'     => 0,
	},
);

__END__
