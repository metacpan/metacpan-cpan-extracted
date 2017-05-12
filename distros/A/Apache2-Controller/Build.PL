
my @requires = qw(
    Apache2::CmdParms
    Apache2::Connection
    Apache2::Const
    Apache2::Cookie
    Apache2::Directive
    Apache2::Module
    Apache2::Request
    Apache2::RequestIO
    Apache2::RequestRec
    Apache2::RequestUtil
    Apache::Session
    Apache::Session::File
    DateTime
    Digest::SHA
    English
    Exception::Class
    ExtUtils::MakeMaker
    File::Spec
    File::Temp
    FindBin
    HTTP::Status
    List::MoreUtils
    Log::Dispatch
    Log::Log4perl
    Net::OpenID::Consumer
    Readonly
    Scalar::Util
    Template
    Test::More
    URI
    YAML::Syck
    version
);

my @build_requires = qw(
    Apache::TestMM
    Apache::TestRequest
    Apache::TestRunPerl
    Apache::TestUtil
    Net::OpenID::Server
    HTTP::Server::Simple::CGI
    Math::BigInt::GMP
    URI::Escape
    LWP
    HTTP::Cookies
);

my @recommends = qw(
    LWPx::ParanoidAgent
    IPC::Open3
);

use Module::Build;

my $build_pkg = eval { require Apache::TestMB }
    ? 'Apache::TestMB' : 'Module::Build';

my $build = $build_pkg->new(
    module_name         => 'Apache2::Controller',
    license             => 'perl',
    build_requires      => { 
        'Apache::Test' => '1.12',
        (map {($_ => 0)} @build_requires)
    },
    requires            => { map {($_ => 0)} @requires },
    recommends          => { map {($_ => 0)} @recommends },
    create_makefile_pl  => 'passthrough',
    dist_author         => 'Mark Hedges <hedges@formdata.biz>',
    dist_version_from   => 'lib/Apache2/Controller.pm',
    add_to_cleanup      => [qw( t/TEST )],
);

$build->create_build_script;

