use strict;
use warnings;
use ExtUtils::MakeMaker 6.52;

my %conf = (
    NAME               => 'App::RunStopRun',
    AUTHOR             => 'gray <gray@cpan.org>',
    LICENSE            => 'perl',
    VERSION_FROM       => 'lib/App/RunStopRun.pm',
    ABSTRACT_FROM      => 'lib/App/RunStopRun.pm',
    EXE_FILES          => ['bin/run-stop-run'],
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 6.52,
    },
    PREREQ_PM => {
        'IO::Pty'            => 0,
        'List::Util'         => 1.45,
        'Proc::ProcessTable' => 0,
        'Time::HiRes'        => 0,
    },
    TEST_REQUIRES => {
        'Capture::Tiny' => 0,
        'Test::More'    => 0.88,
    },
    META_MERGE => {
        resources => {
            repository => 'https://github.com/gray/app-runstoprun',
        },
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES    => 'App-RunStopRun-*' },
);

for ([BUILD_REQUIRES => 6.55_03], [TEST_REQUIRES => 6.64]) {
    my ($tag, $ver) = @$_;
    $conf{PREREQ_PM} = { %{ $conf{PREREQ_PM} }, %{ delete $conf{$tag} } }
        if $conf{$tag} and ! eval { ExtUtils::MakeMaker->VERSION($ver) };
}

WriteMakefile(%conf);


sub MY::postamble {
    return <<"    MAKE_FRAG";
authortest:
\t\$(MAKE) -e \$(TEST_TYPE) TEST_FILES="xt/*.t"
    MAKE_FRAG
}

sub MY::dist_test {
    my $self = shift;
    return $self->MM::dist_test . <<"    MAKE_FRAG";
\tcd \$(DISTVNAME) && \$(MAKE) authortest \$(PASTHRU)
    MAKE_FRAG
}
