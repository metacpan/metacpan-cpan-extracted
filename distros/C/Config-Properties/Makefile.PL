use 5.006;

use ExtUtils::MakeMaker;

my %opts = ( NAME          => 'Config::Properties',
	     VERSION_FROM  => 'lib/Config/Properties.pm',
             ABSTRACT_FROM => 'lib/Config/Properties.pm',
	     PREREQ_PM     => { 'Test::More' => 0,
                                'File::Temp' => 0,
                                'Text::Wrap' => '2001.0929' });

$opts{META_MERGE} = { resources =>
                      { repository => 'https://github.com/salva/p5-Config-Properties' } }
    if $ExtUtils::MakeMaker::VERSION >= 6.46;

WriteMakefile(%opts);
