use strict;
use warnings;
use Test::More;
use Cpanel::JSON::XS qw(decode_json);

{
    package MyApp::Web::Off;
    use parent qw(Amon2 Amon2::Web);
    __PACKAGE__->load_plugins('Web::CpanelJSON', { json_escape_filter => undef });
    sub encoding { 'utf-8' }
}

{
    package MyApp::Web::PartialOff;
    use parent qw(Amon2 Amon2::Web);
    __PACKAGE__->load_plugins(
        'Web::CpanelJSON', {
            json_escape_filter => {
                '+' => undef,
                '<' => '\\u003c',
                '>' => '\\u003e',
            }
        }
    );
    sub encoding { 'utf-8' }
}

{
    package MyApp::Web::Default;
    use parent qw(Amon2 Amon2::Web);
    __PACKAGE__->load_plugins('Web::CpanelJSON');
    sub encoding { 'utf-8' }
}

my $src = { key => '<script>alert("HELLO"+"WORLD")</script>' };

subtest 'json_escape default is on' => sub {
    my $c = MyApp::Web::Default->new(request => Amon2::Web::Request->new({}));
    my $res = $c->render_json($src);
    is $res->code, 200;
    is $res->content, '{"key":"\u003cscript\u003ealert(\"HELLO\"\u002b\"WORLD\")\u003c/script\u003e"}';
    is_deeply decode_json($res->content), $src;
};

subtest 'json_escape off' => sub {
    my $c = MyApp::Web::Off->new(request => Amon2::Web::Request->new({}));
    my $res = $c->render_json($src);
    is $res->code, 200;
    is $res->content, '{"key":"<script>alert(\"HELLO\"+\"WORLD\")</script>"}';
    is_deeply decode_json($res->content), $src;
};

subtest 'json_escape partial off' => sub {
    my $c = MyApp::Web::PartialOff->new(request => Amon2::Web::Request->new({}));
    my $res = $c->render_json($src);
    is $res->code, 200;
    is $res->content, '{"key":"\u003cscript\u003ealert(\"HELLO\"+\"WORLD\")\u003c/script\u003e"}';
    is_deeply decode_json($res->content), $src;
};

done_testing;
