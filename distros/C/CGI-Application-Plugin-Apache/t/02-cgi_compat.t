use strict;
use warnings FATAL => 'all';
use Apache::Test qw(plan ok have_lwp);
use Apache::TestRequest qw(GET);
use Apache::TestUtil qw(t_cmp);
use HTML::Form;
use File::Spec::Functions qw(catfile);

plan( tests => 32, have_lwp() );

my $response;
my $content;
Apache::TestRequest::user_agent( cookie_jar => {});

# 1..3
# correct compat query obj
{
    $response = GET '/cgi_compat?rm=query_obj';
    ok($response->is_success);
    $content = $response->content();
    ok($content =~ /in runmode query_obj/);
    ok($content =~ /obj is CGI::Application::Plugin::Apache\d?::Request/);
}

# 4..9
# cookie()
{
    $response = GET '/cgi_compat?rm=cookie_set';
    ok($response->is_success);
    $content = $response->content();
    ok($content =~ /in runmode cookie_set/);
    ok($response->header('Set-Cookie') =~ /cgi_cookie=yum/);

    $response = GET '/cgi_compat?rm=cookie_get';
    ok($response->is_success);
    $content = $response->content();
    ok($content =~ /in runmode cookie_get/);
    ok($content =~ /cookie value = 'yum'/);
}

# 10..14
# Dump()
{
    $response = GET '/cgi_compat?rm=dump&<<var1=aa&<<var1=bb';
    ok($response->is_success);
    $content = $response->content();
    ok($content =~ /in runmode dump/);
    ok($content =~ m[<li><strong>rm</strong></li>\n<ul>\n<li>dump</li>]);
    ok($content =~ m[<li><strong>&lt;&lt;var1</strong></li>]);
    ok($content =~ m[<ul>\n<li>aa</li>\n<li>bb</li>\n</ul>\n]);
}

# 15..20
# Vars()
{
    $response = GET '/cgi_compat?rm=vars&var1=foo&var2=bar&var3=baz&var4=asdf&var4=qwer';
    ok($response->is_success);
    $content = $response->content();
    ok($content =~ /in runmode vars/);
    ok($content =~ /var1 => foo/);
    ok($content =~ /var2 => bar/);
    ok($content =~ /var3 => baz/);
    ok($content =~ /var4 => ARRAY/);
}

# 21..23
# escapeHTML()
{
    $response = GET '/cgi_compat?rm=escape';
    ok($response->is_success);
    $content = $response->content();
    ok($content =~ /in runmode escape/);
    ok($content =~ /This is a &lt; and a &amp;/);
}

# 24..26
# delete()
{
    $response = GET '/cgi_compat?rm=delete&aa=foo&bb=bar';
    ok($response->is_success);
    $content = $response->content();
    ok($content =~ /in runmode delete/);
    ok($content =~ /aa= bb=bar/);
}

# 27..29
# delete_all()
{
    $response = GET '/cgi_compat?rm=delete_all&aa=foo&bb=bar';
    ok($response->is_success);
    $content = $response->content();
    ok($content =~ /in runmode delete/);
    ok($content =~ /aa= bb=/);
}

# 30..32
# upload()
{
    my ($scheme, $addr, $port, $serverroot) = Apache::Test::vars(qw(scheme remote_addr port serverroot));
    my $form = HTML::Form->parse(
        qq(
            <form action="/cgi_compat" method="post" enctype="multipart/form-data">
            <input type="hidden" name="rm" value="upload">
            <input type="file" name="test_file">
            </form>
        ),
        "$scheme://$addr:$port"
    );
    $form->value(test_file => catfile($serverroot, '02-cgi_compat.t'));
    my $request = $form->make_request();
    $response = LWP::UserAgent->new()->request($form->make_request);
    $content = $response->content();
    ok($content =~ /in runmode upload/);
    ok($content =~ /file_name = .*cgi_compat\.t/);
    ok($content =~ /file_handle = (Apache::Upload=)?GLOB/);
}


