use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
	NAME             => 'App::FuguSeed',
	VERSION          => '0.1.0',
	ABSTRACT         => 'make BIP39 seed words with dice, and turn them into a SeedQR',
	LICENSE          => 'open_source',
	MIN_PERL_VERSION => '5.034',
	EXE_FILES        => [
		'bin/fuguseed-words',
		'bin/fuguseed-qr'
	],
	PREREQ_PM        => {
		'Fugu' => 0
	},
	PM               => {
		'lib/App/FuguSeed.pm' => '$(INST_LIB)/App/FuguSeed.pm',
		'lib/App/FuguSeed.pod' => '$(INST_LIB)/App/FuguSeed.pod',
		'lib/App/FuguSeed/Check.pm' => '$(INST_LIB)/App/FuguSeed/Check.pm',
		'lib/App/FuguSeed/Check.pod' => '$(INST_LIB)/App/FuguSeed/Check.pod',
		'lib/App/FuguSeed/Codewords.pm' => '$(INST_LIB)/App/FuguSeed/Codewords.pm',
		'lib/App/FuguSeed/Codewords.pod' => '$(INST_LIB)/App/FuguSeed/Codewords.pod',
		'lib/App/FuguSeed/List.pm' => '$(INST_LIB)/App/FuguSeed/List.pm',
		'lib/App/FuguSeed/List.pod' => '$(INST_LIB)/App/FuguSeed/List.pod',
		'lib/App/FuguSeed/ListFile.pm' => '$(INST_LIB)/App/FuguSeed/ListFile.pm',
		'lib/App/FuguSeed/ListFile.pod' => '$(INST_LIB)/App/FuguSeed/ListFile.pod',
		'lib/App/FuguSeed/Matrix.pm' => '$(INST_LIB)/App/FuguSeed/Matrix.pm',
		'lib/App/FuguSeed/Matrix.pod' => '$(INST_LIB)/App/FuguSeed/Matrix.pod',
		'lib/App/FuguSeed/Mnemonic.pm' => '$(INST_LIB)/App/FuguSeed/Mnemonic.pm',
		'lib/App/FuguSeed/Mnemonic.pod' => '$(INST_LIB)/App/FuguSeed/Mnemonic.pod',
		'lib/App/FuguSeed/QR.pm' => '$(INST_LIB)/App/FuguSeed/QR.pm',
		'lib/App/FuguSeed/QR.pod' => '$(INST_LIB)/App/FuguSeed/QR.pod',
		'lib/App/FuguSeed/Sheet.pm' => '$(INST_LIB)/App/FuguSeed/Sheet.pm',
		'lib/App/FuguSeed/Sheet.pod' => '$(INST_LIB)/App/FuguSeed/Sheet.pod',
		'lib/App/FuguSeed/Text.pm' => '$(INST_LIB)/App/FuguSeed/Text.pm',
		'lib/App/FuguSeed/Text.pod' => '$(INST_LIB)/App/FuguSeed/Text.pod',
		'lib/App/FuguSeed/Words.pm' => '$(INST_LIB)/App/FuguSeed/Words.pm',
		'lib/App/FuguSeed/Words.pod' => '$(INST_LIB)/App/FuguSeed/Words.pod',
		'share/fuguseed/english.txt' => '$(INST_LIB)/auto/share/dist/App-FuguSeed/fuguseed/english.txt',
		'share/fuguseed/sheet.css' => '$(INST_LIB)/auto/share/dist/App-FuguSeed/fuguseed/sheet.css',
		'share/fuguseed/sheet.html' => '$(INST_LIB)/auto/share/dist/App-FuguSeed/fuguseed/sheet.html',
		't/fuguseed/fixtures/qr/vector4.output' => '$(INST_LIB)/auto/share/dist/App-FuguSeed/t/fuguseed/fixtures/qr/vector4.output',
		't/fuguseed/fixtures/qr/vector4.picture' => '$(INST_LIB)/auto/share/dist/App-FuguSeed/t/fuguseed/fixtures/qr/vector4.picture',
		't/fuguseed/fixtures/sheet.html' => '$(INST_LIB)/auto/share/dist/App-FuguSeed/t/fuguseed/fixtures/sheet.html'
	},
	test             => { TESTS => 't/fuguseed/*.t' },
);
