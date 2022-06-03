use strict;
use warnings;
use Test::More;
use HTTP::SecureHeaders;

{
    package MyApp::Web::WithSecureHeaders;
    use parent qw(Amon2 Amon2::Web);
    __PACKAGE__->load_plugins('Web::CpanelJSON', {
        secure_headers => {
            strict_transport_security => 'max-age=12345',
        }
    });
    sub encoding { 'utf-8' }
}

{
    package MyApp::Web::Default;
    use parent qw(Amon2 Amon2::Web);
    __PACKAGE__->load_plugins('Web::CpanelJSON');
    sub encoding { 'utf-8' }
}

{
    package MyApp::Web::None;
    use parent qw(Amon2 Amon2::Web);
    __PACKAGE__->load_plugins('Web::CpanelJSON', {
        secure_headers => undef,
    });
    sub encoding { 'utf-8' }
}

subtest 'MyApp::Web::WithSecureHeaders' => sub {
    my $c = MyApp::Web::WithSecureHeaders->new(request => Amon2::Web::Request->new({}));

    my $res = $c->render_json({});
    is $res->header('Strict-Transport-Security'), 'max-age=12345', 'NOT DEFAULT VALUE';

    is $res->header('Content-Security-Policy'), "default-src 'none'";
    is $res->header('X-Content-Type-Options'), 'nosniff';
    is $res->header('X-Download-Options'), undef;
    is $res->header('X-Frame-Options'), 'DENY';
    is $res->header('X-Permitted-Cross-Domain-Policies'), 'none';
    is $res->header('X-XSS-Protection'), '1; mode=block';
    is $res->header('Referrer-Policy'), 'no-referrer';
};

subtest 'Default' => sub {
    my $c = MyApp::Web::Default->new(request => Amon2::Web::Request->new({}));

    my $res = $c->render_json({});
    is $res->header('Content-Security-Policy'), "default-src 'none'";
    is $res->header('Strict-Transport-Security'), 'max-age=631138519';
    is $res->header('X-Content-Type-Options'), 'nosniff';
    is $res->header('X-Download-Options'), undef;
    is $res->header('X-Frame-Options'), 'DENY';
    is $res->header('X-Permitted-Cross-Domain-Policies'), 'none';
    is $res->header('X-XSS-Protection'), '1; mode=block';
    is $res->header('Referrer-Policy'), 'no-referrer';
};

subtest 'None' => sub {
    my $c = MyApp::Web::None->new(request => Amon2::Web::Request->new({}));

    my $res = $c->render_json({});
    is $res->header('Content-Security-Policy'), undef;
    is $res->header('Strict-Transport-Security'), undef;
    is $res->header('X-Content-Type-Options'), undef;
    is $res->header('X-Download-Options'), undef;
    is $res->header('X-Frame-Options'), undef;
    is $res->header('X-Permitted-Cross-Domain-Policies'), undef;
    is $res->header('X-XSS-Protection'), undef;
    is $res->header('Referrer-Policy'), undef;
};

done_testing;
