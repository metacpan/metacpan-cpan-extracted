use strict;
use warnings;
use ExtUtils::MakeMaker;

my %params = (
    NAME          => 'Archive::Any::Plugin::Bzip2',
    AUTHOR        => 'Kenichi Ishigaki <ishigaki@cpan.org>',
    VERSION_FROM  => 'lib/Archive/Any/Plugin/Bzip2.pm',
    ABSTRACT_FROM => 'lib/Archive/Any/Plugin/Bzip2.pm',
    LICENSE       => 'perl',
    PREREQ_PM     => {
        'Archive::Any' => 0,
        'IO::Compress::Bzip2' => 0,
        'Test::More'          => '0.47',
        'Test::UseAllModules' => '0.10',
    },
);

my $eumm = $ExtUtils::MakeMaker::VERSION;
delete $params{LICENSE} if $eumm < 6.31;

WriteMakefile(%params);
