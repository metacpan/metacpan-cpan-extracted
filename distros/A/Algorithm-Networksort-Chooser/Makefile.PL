use strict;

use ExtUtils::MakeMaker;


my %args = (
    NAME => 'Algorithm::Networksort::Chooser',
    VERSION_FROM => 'lib/Algorithm/Networksort/Chooser.pm',
    EXE_FILES => [ 'bin/algorithm-networksort-chooser', ],
    PREREQ_PM => {
      'common::sense' => 0,
      'Getopt::Long' => 0,
      'Math::Combinatorics' => 0,

      ## Assumes default when there is no best to be batcher, changed to this in 1.30
      'Algorithm::Networksort' => 1.30,
    },
    LIBS              => [],
    DEFINE            => '',
    LICENSE => 'perl',
    dist => {
      PREOP => 'pod2text bin/algorithm-networksort-chooser > $(DISTVNAME)/README',
    },
);


my $eummv = eval ($ExtUtils::MakeMaker::VERSION);
if ($eummv >= 6.45) {
    $args{META_MERGE} = {
        resources => {
            repository => 'git://github.com/hoytech/Algorithm-Networksort-Chooser.git',
            bugtracker => 'https://github.com/hoytech/Algorithm-Networksort-Chooser/issues',
        },
    };
}

WriteMakefile(%args);
