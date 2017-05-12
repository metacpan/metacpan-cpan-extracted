use 5.014000;
use ExtUtils::MakeMaker;

WriteMakefile(
	NAME              => 'App::Web::VPKBuilder',
	VERSION_FROM      => 'lib/App/Web/VPKBuilder.pm',
	ABSTRACT_FROM     => 'lib/App/Web/VPKBuilder.pm',
	AUTHOR            => 'Marius Gavrilescu <marius@ieval.ro>',
	MIN_PERL_VERSION  => '5.14.0',
	LICENSE           => 'perl',
	SIGN              => 1,
	PREREQ_PM         => {
		qw/File::Basename        0
		   File::Find            0
		   File::Path            0
		   File::Spec::Functions 0
		   File::Temp            0
		   IO::Compress::Zip     2.039
		   sigtrap               0

		   Data::Diver       0
		   File::Slurp       0
		   HTML::Element     0
		   HTML::TreeBuilder 0
		   Hash::Merge       0
		   List::MoreUtils   0
		   Plack::Builder    0
		   Plack::Component  0
		   Plack::Request    0
		   Sort::ByExample   0
		   YAML              0/,
	},
	META_MERGE         => {
		dynamic_config => 0,
		resources      => {
			repository   => 'https://git.ieval.ro/?p=app-web-vpkbuilder.git',
		}
	}
);
