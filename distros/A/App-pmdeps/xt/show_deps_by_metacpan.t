#!perl

use strict;
use warnings;
use utf8;
use Capture::Tiny qw/capture/;
use App::pmdeps;

use Test::More;

BEGIN {
    $ENV{ANSI_COLORS_DISABLED} = 1;
}

subtest 'Plack version 1.0027' => sub {
    subtest 'with perl-5.008001' => sub {
        my ($got) = capture {
            App::pmdeps->new->run( '-p', '5.008001', 'Plack', '1.0027' );
        };

        is $got, <<EOS;
Target: perl-5.008001
Depends on 3 core modules:
\tExtUtils::MakeMaker
\tPod::Usage
\tTest::More
Depends on 29 non-core modules:
\tApache::LogFormat::Compiler
\tAuthen::Simple::Passwd
\tCGI::Compile
\tCGI::Emulate::PSGI
\tDevel::StackTrace
\tDevel::StackTrace::AsHTML
\tFCGI
\tFCGI::ProcManager
\tFile::ShareDir
\tFile::ShareDir::Install
\tFilesys::Notify::Simple
\tHTTP::Body
\tHTTP::Message
\tHTTP::Request::AsCGI
\tHTTP::Server::Simple::PSGI
\tHTTP::Tiny
\tHash::MultiValue
\tIO::Handle::Util
\tLWP::Protocol::http10
\tLWP::UserAgent
\tLog::Log4perl
\tMIME::Types
\tStream::Buffered
\tTest::Pod
\tTest::Requires
\tTest::TCP
\tTry::Tiny
\tURI
\tparent
EOS
    };

    subtest 'with perl-5.016003' => sub {
        subtest 'all' => sub {
            my ($got) = capture {
                App::pmdeps->new->run( '-p', '5.016003', 'Plack', '1.0027' );
            };

            is $got, <<EOS;
Target: perl-5.016003
Depends on 5 core modules:
\tExtUtils::MakeMaker
\tHTTP::Tiny
\tPod::Usage
\tTest::More
\tparent
Depends on 27 non-core modules:
\tApache::LogFormat::Compiler
\tAuthen::Simple::Passwd
\tCGI::Compile
\tCGI::Emulate::PSGI
\tDevel::StackTrace
\tDevel::StackTrace::AsHTML
\tFCGI
\tFCGI::ProcManager
\tFile::ShareDir
\tFile::ShareDir::Install
\tFilesys::Notify::Simple
\tHTTP::Body
\tHTTP::Message
\tHTTP::Request::AsCGI
\tHTTP::Server::Simple::PSGI
\tHash::MultiValue
\tIO::Handle::Util
\tLWP::Protocol::http10
\tLWP::UserAgent
\tLog::Log4perl
\tMIME::Types
\tStream::Buffered
\tTest::Pod
\tTest::Requires
\tTest::TCP
\tTry::Tiny
\tURI
EOS
        };
        subtest 'without some phases' => sub {
            my ($got) = capture {
                App::pmdeps->new->run( '-p', '5.016003', '--without-phase', 'configure,develop,test', 'Plack', '1.0027' );
            };

            is $got, <<EOS;
Target: perl-5.016003
Depends on 3 core modules:
\tHTTP::Tiny
\tPod::Usage
\tparent
Depends on 18 non-core modules:
\tApache::LogFormat::Compiler
\tCGI::Compile
\tCGI::Emulate::PSGI
\tDevel::StackTrace
\tDevel::StackTrace::AsHTML
\tFCGI
\tFCGI::ProcManager
\tFile::ShareDir
\tFilesys::Notify::Simple
\tHTTP::Body
\tHTTP::Message
\tHash::MultiValue
\tIO::Handle::Util
\tLWP::UserAgent
\tStream::Buffered
\tTest::TCP
\tTry::Tiny
\tURI
EOS
        };
        subtest 'without some type' => sub {
            my ($got) = capture {
                App::pmdeps->new->run( '-p', '5.016003', '--without-type', 'suggests,recommends', 'Plack', '1.0027' );
            };

            is $got, <<EOS;
Target: perl-5.016003
Depends on 5 core modules:
\tExtUtils::MakeMaker
\tHTTP::Tiny
\tPod::Usage
\tTest::More
\tparent
Depends on 15 non-core modules:
\tApache::LogFormat::Compiler
\tDevel::StackTrace
\tDevel::StackTrace::AsHTML
\tFile::ShareDir
\tFile::ShareDir::Install
\tFilesys::Notify::Simple
\tHTTP::Body
\tHTTP::Message
\tHash::MultiValue
\tStream::Buffered
\tTest::Pod
\tTest::Requires
\tTest::TCP
\tTry::Tiny
\tURI
EOS
        };
    };
};

subtest 'Plack version 1.0000' => sub {
    my ($got) = capture {
        App::pmdeps->new->run( '-p', '5.008001', 'Plack', '1.0000' );
    };

    is $got, <<EOS;
Target: perl-5.008001
Depends on 3 core modules:
\tExtUtils::MakeMaker
\tPod::Usage
\tTest::More
Depends on 13 non-core modules:
\tDevel::StackTrace
\tDevel::StackTrace::AsHTML
\tFile::ShareDir
\tFilesys::Notify::Simple
\tHTTP::Body
\tHTTP::Message
\tHash::MultiValue
\tLWP::UserAgent
\tTest::Requires
\tTest::TCP
\tTry::Tiny
\tURI
\tparent
EOS
};

done_testing;
