use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'AMF::Connection',
    VERSION_FROM      => 'lib/AMF/Connection.pm', # finds $VERSION
    PREREQ_PM         => {
		'Storable::AMF' => 0.71, # 0.71 for AMF3 Externalizable Object basic support
		'LWP::UserAgent' => 5.829 # we want a minimum sane working version
		},
    ($] >= 5.005 ?
      (ABSTRACT_FROM  => 'lib/AMF/Connection.pm',
       AUTHOR         => 'Alberto Attilio Reggiori, <areggiori@cpan.org>') : ()),
);
