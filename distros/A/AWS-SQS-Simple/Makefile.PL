use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'AWS::SQS::Simple',
    AUTHOR              => 'Ankita <sankita.11@gmail.com>',
    VERSION_FROM        => 'lib/AWS/SQS/Simple.pm',
    ABSTRACT_FROM       => 'lib/AWS/SQS/Simple.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'        => 0,
	'Data::Dump'        => 0,
	'Encode'            => 0,
	'MIME::Base64'      => 0,
	'Digest::SHA'       => 0,
	'Digest::HMAC_SHA1' => 0,
	'URI::Escape'       => 0,
	'Carp'              => 0,
	'LWP::UserAgent'    => 0,
	'HTTP::Headers'     => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'AWS-SQS-Simple-*' },
    META_MERGE        => {
	
	"meta-spec" => { version => 2 },

	resources => {
	    
	    repository => {
		type => 'git',
		url => 'git://github.com/sankita11/AWS-SQS-Simple.git',
		web => 'https://github.com/sankita11/AWS-SQS-Simple',
	    },

	},

    },
);
