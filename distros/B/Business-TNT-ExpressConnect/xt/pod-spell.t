use Test::More;

eval 'use Test::Spelling;';

plan skip_all => "Test::Spelling required for testing POD spelling"
    if $@;

add_stopwords(qw(
        Jozef Kutej
        OFC
        API
        JSON
        TBD
        html
        RT
        CPAN
        AnnoCPAN
        http
        GitHub
        GLOBs
        ExpressConnect
        Pavlovic
        cachedir
        datadir
        lockdir logdir
        sharedstatedir srvdir sysconfdir
        )
);
all_pod_files_spelling_ok();
