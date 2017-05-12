use strict;

use ExtUtils::MakeMaker;


my %args = (
    NAME => 'App::Session::Token',
    VERSION_FROM => 'lib/App/Session/Token.pm',
    EXE_FILES => [ 'bin/session-token', ],
    PREREQ_PM => {
      'Session::Token' => 0,
      'Getopt::Long' => 0,
    },
    LIBS => [],
    DEFINE => '',
    LICENSE => 'perl',
    dist => {
      PREOP => 'pod2text bin/session-token > $(DISTVNAME)/README',
    },
);


my $eummv = eval ($ExtUtils::MakeMaker::VERSION);
if ($eummv >= 6.45) {
    $args{META_MERGE} = {
        resources => {
            repository => 'git://github.com/hoytech/App-Session-Token.git',
            bugtracker => 'https://github.com/hoytech/App-Session-Token/issues',
        },
    };
}

WriteMakefile(%args);
