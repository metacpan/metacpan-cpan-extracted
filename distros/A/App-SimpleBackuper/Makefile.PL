#!/usr/bin/perl

use strict;
use warnings;
use ExtUtils::MakeMaker;
use ExtUtils::Manifest qw(mkmanifest);

die "OS unsupported\n" if $^O eq "MSWin32";

mkmanifest();

WriteMakefile(
    NAME            => 'App::SimpleBackuper',
	ABSTRACT		=> 'Just simple backuper app with incremental compressed encrypted backups stored on remote ssh server',
  	AUTHOR			=> 'Dmitry Novozhilov <Dmitry@Novozhilov.ru>',
    VERSION_FROM    => 'lib/App/SimpleBackuper.pm',
	LICENSE			=> 'gpl_3',
	test			=> {TESTS => 't/*.t t/*/*.t'},
	TEST_REQUIRES	=> {'Test::Spec' => 0},
	EXE_FILES		=> ['bin/simple-backuper'],
	MIN_PERL_VERSION=> 5.014,
	PREREQ_PM		=> {
		'Crypt::Rijndael'		=> 0,
		'Crypt::OpenSSL::RSA'	=> 0,
		'Compress::Raw::Lzma'	=> 0,
		'Digest::SHA'			=> 0,
		'Text::Glob'			=> 0,
		'Try::Tiny'				=> 0,
		'Net::SFTP::Foreign'	=> 0,
		'Const::Fast'			=> 0,
		'MIME::Base64'			=> 0,
		'JSON::PP'				=> 0,
		'POSIX'					=> 0,
	},
	META_MERGE		=> {
		'meta-spec'		=> { version => 2 },
		resources		=> {
			repository		=> {
				type	=> 'git',
				url		=> 'git://github.com/dmitry-novozhilov/simple-backuper.git',
				web		=> 'https://github.com/dmitry-novozhilov/simple-backuper',
			},
		},
	},
);
