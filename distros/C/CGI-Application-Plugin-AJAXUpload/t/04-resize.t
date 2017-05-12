#!/usr/bin/perl -wT
use strict;
use warnings;
use Carp;
use Test::More tests=>12;
use Test::NoWarnings;
use Test::CGI::Multipart;
use Test::CGI::Multipart::Gen::Image;
use Test::Image::GD;
use lib qw(t/lib);
use Perl6::Slurp;
use Readonly;
use File::Temp;
use TestWebApp;
use Data::FormValidator::Filters::ImgData;

Readonly my $CONTENT_RE =>
    qr{
        \A
        Encoding:\s+utf-8\s+Content-Type:\s+text/javascript
        (?:;\s+charset=utf-8)?
    }xms;
    
Readonly my $IMAGE_INSTRUCTIONS => [
    ['bgcolor','red'],
    ['fgcolor','blue'],
    ['rectangle',30,30,100,100],
    ['moveTo',80,210],
    ['fontsize',20],
    ['string','Helloooooooooooo world!'],
]; 

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
$tcm->upload_file(
        name=>'file',
        width=>400,
        height=>250,
        instructions=>$IMAGE_INSTRUCTIONS,
        file=>'test.jpeg',
        type=>'image/jpeg'
);

my $profile = CGI::Application::Plugin::AJAXUpload->ajax_upload_default_profile;
$profile->{field_filters}->{value} = filter_resize(300,200);

subtest 'httpdocs_dir not specified' => sub{
    plan tests => 3;
    my $app = TestWebApp->new(
        QUERY=>$tcm->create_cgi(),
        PARAMS=>{
            document_root=>sub {},
            ajax_spec=>{
                dfv_profile=>$profile,
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
            ajax_spec=>{
                dfv_profile=>$profile,
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
            ajax_spec=>{
                dfv_profile=>$profile,
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
            ajax_spec=>{
                dfv_profile=>$profile,
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
            ajax_spec=>{
                dfv_profile=>$profile,
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
            ajax_spec=>{
                dfv_profile=>$profile,
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
$tcm4->upload_file(
        name=>'file',
        width=>400,
        height=>250,
        instructions=>$IMAGE_INSTRUCTIONS,
        file=>'test*blah.jpeg',
        type=>'image/jpeg'
);
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
            ajax_spec=>{
                dfv_profile=>$profile,
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

my $tcm3 = Test::CGI::Multipart->new;
$tcm3->set_param(name=>'rm', value=>'file_upload');
$tcm3->upload_file(
        name=>'file',
        width=>400,
        height=>250,
        instructions=>$IMAGE_INSTRUCTIONS,
        file=>'test.jpeg',
        type=>'image/jpeg'
);
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
                upload_subdir=>$upload_subdir,
                dfv_profile=>$profile,
            },
        },
    );
    isa_ok($app, 'CGI::Application');
    $app->response_like(
        $CONTENT_RE,
        qr!{"status":"UPLOADED","image_url":"$upload_subdir/test.jpeg"}!xms,
        'UPLOADED'
    );
    size_ok("$tmpdir_name$upload_subdir/test.jpeg", [300,int(250*300/400)], "size 300x200");
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
            ajax_spec=>{
                dfv_profile=>$profile,
            },
        },
    );
    isa_ok($app, 'CGI::Application');
    $app->query->param(validate=>1);
    $app->response_like(
        $CONTENT_RE,
        qr!{"status":"UPLOADED","image_url":"/img/uploads/test.jpeg"}!xms,
        'UPLOADED'
    );
    size_ok("$tmpdir_name/img/uploads/test.jpeg", [300,int(250*300/400)], "size 300x200");
};

subtest 'png' => sub{
    plan tests => 4;
    my $tmpdir = valid_dir();
    my $tmpdir_name = $tmpdir->dirname;
    local $profile->{field_filters}->{value} = filter_resize(300,200,'png');
    my $app = TestWebApp->new(
        QUERY=>$tcm->create_cgi(),
        PARAMS=>{
            document_root=>sub {
                my $c = shift;
                $c->ajax_upload_httpdocs($tmpdir_name);
            },
            ajax_spec=>{
                dfv_profile=>$profile,
            },
        },
    );
    isa_ok($app, 'CGI::Application');
    $app->query->param(validate=>1);
    $app->response_like(
        $CONTENT_RE,
        qr!{"status":"UPLOADED","image_url":"/img/uploads/test.jpeg"}!xms,
        'UPLOADED'
    );
    size_ok("$tmpdir_name/img/uploads/test.jpeg", [300,int(250*300/400)], "size 300x200");
};

subtest 'square' => sub{
    plan tests => 4;
    my $tmpdir = valid_dir();
    my $tmpdir_name = $tmpdir->dirname;
    local $profile->{field_filters}->{value} = filter_resize(300,50);
    my $app = TestWebApp->new(
        QUERY=>$tcm->create_cgi(),
        PARAMS=>{
            document_root=>sub {
                my $c = shift;
                $c->ajax_upload_httpdocs($tmpdir_name);
            },
            ajax_spec=>{
                dfv_profile=>$profile,
            },
        },
    );
    isa_ok($app, 'CGI::Application');
    $app->query->param(validate=>1);
    $app->response_like(
        $CONTENT_RE,
        qr!{"status":"UPLOADED","image_url":"/img/uploads/test.jpeg"}!xms,
        'UPLOADED'
    );
    size_ok("$tmpdir_name/img/uploads/test.jpeg", [80,50], "size 300x50");
};


