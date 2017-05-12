#!/usr/bin/perl

use strict;
use warnings;
use 5.006;
use ExtUtils::MakeMaker;

eval q{
    use Apache::TestMM qw(test clean);

    # accept the configs from command line
    Apache::TestMM::filter_args();
    Apache::TestMM::generate_script('t/TEST');
};

WriteMakefile(
    NAME              => 'CGI::JSONRPC',
    VERSION_FROM      => 'lib/CGI/JSONRPC.pm', # finds $VERSION
    PREREQ_PM         => {
        #'mod_perl2'     =>      2.000001,
        'JSON::Syck'    =>      0,
        'Apache::Test'  =>      0,
        'Test::Warn'    =>      0,
        'Test::Exception'   =>  0,
        'CGI'           =>      3.11,
    },
    clean             => { FILES => "@{ clean_files() }" },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/CGI/JSONRPC.pm', # retrieve abstract from module
       AUTHOR         => 'Tyler MacDonald <japh@crackerjack.net>') : ()),
);

            
sub clean_files {
    return [ 't/TEST' ];
}

sub MY::postamble {
    return qq{
README: lib/CGI/JSONRPC.pm
\tpod2text < lib/CGI/JSONRPC.pm > README.new && \$(MV) -vf README.new README

distmeta : README

distclean ::
\t\$(RM) -vf README

}
}
