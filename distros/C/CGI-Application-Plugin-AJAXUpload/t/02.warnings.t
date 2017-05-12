#!/usr/bin/perl -wT
use strict;
use warnings;
use Carp;
use Test::More tests=>12;
use Test::NoWarnings;
use Test::CGI::Multipart;
use lib qw(t/lib);
use Perl6::Slurp;
use Readonly;
use File::Temp;
use TestWebApp;

Readonly my $CONTENT_RE =>
    qr{
        \A
        Encoding:\s+utf-8\s+Content-Type:\s+text/javascript
        (?:;\s+charset=utf-8)?
    }xms;

my $profile = TestWebApp->ajax_upload_default_profile();
$profile->{constraint_methods}->{mime_type} = qr{^text/plain$};
$profile->{required} = [qw(value file_name data_size)];
$profile->{optional} = [qw(mime_type)];

sub nonexistent_dir {
    my $new_dir = File::Temp->newdir;
    return $new_dir->dirname;
}

sub valid_dir {
    my $tmpdir = File::Temp->newdir;
    my $tmpdir_name = $tmpdir->dirname;
    mkdir "$tmpdir_name/img";
    mkdir "$tmpdir_name/img/uploads";
    return $tmpdir;
}

my $tcm = Test::CGI::Multipart->new;
$tcm->set_param(name=>'rm', value=>'ajax_upload_rm');
$tcm->upload_file(name=>'file', value=>'This is a test!',file=>'test.txt');

subtest 'httpdocs_dir not specified' => sub{
    plan tests => 3;
    my $app = TestWebApp->new(
        QUERY=>$tcm->create_cgi(),
        PARAMS=>{
            document_root=>sub {},
            ajax_spec=> {
                dfv_profile=>$profile
            },
        },
    );
    isa_ok($app, 'CGI::Application');
    $app->response_like(
        $CONTENT_RE,
        qr/{"status":"No document root specified"}/,
        'httpdocs_dir not specified'
    );
};

subtest 'httpdocs_dir does not exist' => sub{
    plan tests => 3;
    my $app = TestWebApp->new(
        QUERY=>$tcm->create_cgi(),
        PARAMS=>{
            document_root=>sub {
                my $c = shift;
                $c->ajax_upload_httpdocs(nonexistent_dir());
            },
            ajax_spec=> {
                dfv_profile=>$profile
            },
        },
    );
    isa_ok($app, 'CGI::Application');
    $app->query->param(validate=>1);
    $app->response_like(
        $CONTENT_RE,
        qr/{"status":"Document root is not a directory"}/,
        'httpdocs_dir does not exist'
    );
};

subtest 'httpdocs_dir not a directory' => sub{
    plan tests => 3;
    my $actually_a_file = File::Temp->new;
    my $app = TestWebApp->new(
        QUERY=>$tcm->create_cgi(),
        PARAMS=>{
            document_root=>sub {
                my $c = shift;
                $c->ajax_upload_httpdocs($actually_a_file->filename);
            },
            ajax_spec=> {
                dfv_profile=>$profile
            },
        },
    );
    isa_ok($app, 'CGI::Application');
    $app->query->param(rm=>'ajax_upload_rm');
    $app->query->param(validate=>1);
    $app->response_like(
        $CONTENT_RE,
        qr/{"status":"Document root is not a directory"}/,
        'httpdocs_dir not a directory'
    );
};

subtest 'upload_subdir does not exist' => sub{
    plan tests => 3;
    my $tmpdir = File::Temp->newdir;
    my $app = TestWebApp->new(
        QUERY=>$tcm->create_cgi(),
        PARAMS=>{
            document_root=>sub {
                my $c = shift;
                $c->ajax_upload_httpdocs($tmpdir->dirname);
            },
            ajax_spec=> {
                dfv_profile=>$profile
            },
        },
    );
    isa_ok($app, 'CGI::Application');
    $app->query->param(validate=>1);
    $app->response_like(
        $CONTENT_RE,
        qr/{"status":"Upload folder is not a directory"}/,
        'upload folder does not exist'
    );
};

subtest 'upload_subdir is not writeable' => sub{
    plan tests => 3;
    my $tmpdir = valid_dir();
    my $tmpdir_name = $tmpdir->dirname;
    chmod 300, "$tmpdir_name/img/uploads";
    my $app = TestWebApp->new(
        QUERY=>$tcm->create_cgi(),
        PARAMS=>{
            document_root=>sub {
                my $c = shift;
                $c->ajax_upload_httpdocs($tmpdir_name);
            },
            ajax_spec=> {
                dfv_profile=>$profile
            },
        },
    );
    isa_ok($app, 'CGI::Application');
    $app->query->param(validate=>1);
    $app->response_like(
        $CONTENT_RE,
        qr/{"status":"Upload folder is not writeable"}/,
        'Upload folder is not writeable'
    );
};

my $tcm2 = Test::CGI::Multipart->new;
$tcm2->set_param(name=>'rm', value=>'ajax_upload_rm');
subtest 'no file parameter' => sub{
    plan tests => 3;
    my $tmpdir = valid_dir();
    my $tmpdir_name = $tmpdir->dirname;
    my $app = TestWebApp->new(
        QUERY=>$tcm2->create_cgi(),
        PARAMS=>{
            document_root=>sub {
                my $c = shift;
                $c->ajax_upload_httpdocs($tmpdir_name);
            },
            ajax_spec=> {
                dfv_profile=>$profile
            },
        },
    );
    isa_ok($app, 'CGI::Application');
    $app->response_like(
        $CONTENT_RE,
        qr/{"status":"No file handle obtained"}/,
        'no file parameter'
    );
};

my $tcm4 = Test::CGI::Multipart->new;
$tcm4->set_param(name=>'rm', value=>'ajax_upload_rm');
$tcm4->upload_file(name=>'file', value=>'This is a test!',file=>'test*blah.txt');
subtest 'DFV messages' => sub{
    plan tests => 3;
    my $tmpdir = valid_dir();
    my $tmpdir_name = $tmpdir->dirname;
    my $app = TestWebApp->new(
        QUERY=>$tcm4->create_cgi(),
        PARAMS=>{
            document_root=>sub {
                my $c = shift;
                $c->ajax_upload_httpdocs($tmpdir_name);
            },
            ajax_spec=> {
                dfv_profile=>$profile
            },
        },
    );
    isa_ok($app, 'CGI::Application');
    $app->response_like(
        $CONTENT_RE,
        qr/{"status":"file_name: Invalid, "}/,
        'DFV messages'
    );
};

subtest 'internal error' => sub{
    plan  tests => 4;
    my $tmpdir = valid_dir();
    my $tmpdir_name = $tmpdir->dirname;
    local $profile->{field_filters} = {
        file_name => [
            sub {croak "Help!"},
        ],
    };
    my $app = TestWebApp->new(
        QUERY=>$tcm->create_cgi(),
        PARAMS=>{
            document_root=>sub {
                my $c = shift;
                $c->ajax_upload_httpdocs($tmpdir_name);
            },
            ajax_spec=> {
                dfv_profile=>$profile
            },
        },
    );
    isa_ok($app, 'CGI::Application');
    $app->response_like(
        $CONTENT_RE,
        qr/{"status":"Internal Error"}/,
        'Internal Error',
        qr/Help!/
    );
};

my $tcm5 = Test::CGI::Multipart->new;
$tcm5->set_param(name=>'rm', value=>'ajax_upload_rm');
$tcm5->upload_file(name=>'file', value=>'',file=>'test.txt');
subtest 'no data' => sub{
    plan  tests => 3;
    my $tmpdir = valid_dir();
    my $tmpdir_name = $tmpdir->dirname;
    local $profile->{constraint_methods} = {
        value => qr/^.{0,100}$/,
    };
    local $profile->{required} = [
        qw(file_name data_size)
    ];
    local $profile->{optional} = [
        qw(mime_type value)
    ];
    my $app = TestWebApp->new(
        QUERY=>$tcm5->create_cgi(),
        PARAMS=>{
            document_root=>sub {
                my $c = shift;
                $c->ajax_upload_httpdocs($tmpdir_name);
            },
            ajax_spec=> {
                dfv_profile=>$profile
            },
        },
    );
    isa_ok($app, 'CGI::Application');
    $app->query->param(validate=>1);
    $app->response_like(
        $CONTENT_RE,
        qr/{"status":"No data uploaded"}/,
        'No data uploaded'
    );
};

my $tcm3 = Test::CGI::Multipart->new;
$tcm3->set_param(name=>'rm', value=>'file_upload');
$tcm3->upload_file(name=>'file', value=>'This is a test!',file=>'test.txt');
subtest 'options' => sub{
    plan tests => 4;
    my $upload_subdir = '/images';
    my $tmpdir = File::Temp->newdir;
    my $tmpdir_name = $tmpdir->dirname;
    mkdir "$tmpdir_name$upload_subdir";
    my $app = TestWebApp->new(
        QUERY=>$tcm3->create_cgi(),
        PARAMS=>{
            document_root=>sub {
                my $c = shift;
                $c->ajax_upload_httpdocs($tmpdir_name);
            },
            ajax_spec=> {
                run_mode=>'file_upload',
                dfv_profile=>$profile,
                upload_subdir=>$upload_subdir,
            },
        },
    );
    isa_ok($app, 'CGI::Application');
    $app->response_like(
        $CONTENT_RE,
        qr!{"status":"UPLOADED","image_url":"$upload_subdir/test.txt"}!xms,
        'UPLOADED'
    );
    is(slurp("$tmpdir_name$upload_subdir/test.txt"), "This is a test!", 'file contents');
};

subtest 'UPLOADED' => sub{
    plan tests => 4;
    my $tmpdir = valid_dir();
    my $tmpdir_name = $tmpdir->dirname;
    my $app = TestWebApp->new(
        QUERY=>$tcm->create_cgi(),
        PARAMS=>{
            document_root=>sub {
                my $c = shift;
                $c->ajax_upload_httpdocs($tmpdir_name);
            },
            ajax_spec=> {
                dfv_profile=>$profile
            },
        },
    );
    isa_ok($app, 'CGI::Application');
    $app->query->param(validate=>1);
    $app->response_like(
        $CONTENT_RE,
        qr!{"status":"UPLOADED","image_url":"/img/uploads/test.txt"}!xms,
        'UPLOADED'
    );
    is(slurp("$tmpdir_name/img/uploads/test.txt"), "This is a test!", 'file contents');
};






