use v5.10;

use strict;

use ExtUtils::MakeMaker;


my %args = (
    NAME => 'Bio::Regexp',
    VERSION_FROM => 'lib/Bio/Regexp.pm',
    PREREQ_PM => {
      'common::sense' => 0,
      'Regexp::Exhaustive' => 0,
      'Regexp::Grammars' => 0,
      'List::MoreUtils' => 0,
      'Data::Alias' => 0,
    },
    LIBS => [],
    DEFINE => '',
    LICENSE => 'perl',
    dist => {
      PREOP => 'perldoc -uT lib/Bio/Regexp.pm > README.pod; pod2text README.pod > $(DISTVNAME)/README',
    },
);


my $eummv = eval ($ExtUtils::MakeMaker::VERSION);
if ($eummv >= 6.45) {
    $args{META_MERGE} = {
        resources => {
            repository => 'git://github.com/hoytech/Bio-Regexp.git',
            bugtracker => 'https://github.com/hoytech/Bio-Regexp/issues',
        },
    };
}

WriteMakefile(%args);
