
my @libs = qw(ProxyPass);

use ExtUtils::MakeMaker;
WriteMakefile(
	NAME		=> 'Apache::ProxyPass',
	VERSION_FROM	=> 'ProxyPass.pm',
	PM		=> { map { ("$_.pm" => "\$(INST_LIBDIR)/$_.pm") } @libs },
	dist		=> { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
	);

