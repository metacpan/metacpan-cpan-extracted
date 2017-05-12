use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Catalyst::Model::XML::Feed',
    AUTHOR              => 'Jonathan Rockway <jrockway@cpan.org>',
    VERSION_FROM        => 'lib/Catalyst/Model/XML/Feed.pm',
    ABSTRACT_FROM       => 'lib/Catalyst/Model/XML/Feed.pm',
    PL_FILES            => {},
    PREREQ_PM => {
		  'Catalyst::Model' => 0,
		  'XML::Feed'       => '0.11',
		  'Test::More'      => 0,
		  'MRO::Compat'     => 0,
		  'Carp'            => 0,
		  'URI'             => 0,
		  'Class::Accessor' => 0,
		 },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Catalyst-Model-XML-Feed-*' },
);
