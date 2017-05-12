use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Authen::ModAuthPubTkt',
    AUTHOR              => q{Assaf Gordon <gordon@cshl.edu>},
    VERSION_FROM        => 'lib/Authen/ModAuthPubTkt.pm',
    ABSTRACT_FROM       => 'lib/Authen/ModAuthPubTkt.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    EXE_FILES           => [ 'eg/mod_auth_pubtkt.pl' ],
    PL_FILES            => {},
    PREREQ_PM => {
	'Test::More'  => 0,
        'File::Temp' => 0,
        'IPC::Run3' => 0,
        'MIME::Base64' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Authen-ModAuthPubTkt-*' },
);
