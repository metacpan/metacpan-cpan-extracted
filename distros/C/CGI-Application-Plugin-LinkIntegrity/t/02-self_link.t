
use Test::More 'no_plan';
use strict;
$ENV{CGI_APP_RETURN_ONLY} = 1;

{
    package WebApp;
    use CGI::Application;
    use vars qw(@ISA);
    use URI;
    @ISA = ('CGI::Application');

    use Test::More;
    use CGI::Application::Plugin::LinkIntegrity;

    sub setup {
        my $self = shift;
        $self->run_modes([qw/start/]);
        $self->link_integrity_config(
            'secret'           => 'foo',
            'disable'          => 1,
        );
    }

    sub start {
        my $self = shift;

        my $self_url             = URI->new($self->query->url);
        my $self_url_w_path_info = URI->new($self->query->url(-path_info => 1));

        $self->link_integrity_config(
            secret        => 'foo',
        );

        # Plain self_link
        my $link = $self->self_link;

        my $uri = URI->new($link);
        my %params = $uri->query_form;

        is($uri->path, $self_url_w_path_info->path,  '[plain checksum] URI path');
        ok(keys %params == 1,                        '[plain checksum] URI params');
        ok(length $params{'_checksum'},              '[plain checksum] URI checksum');

        # Test keeping path_info
        $link = $self->self_link(wubba => 'woo', 'foo' => 'bar', bar=> 'baz');

        $uri = URI->new($link);
        %params = $uri->query_form;

        is($uri->path, $self_url_w_path_info->path, '[keep path_info] URI path');
        ok(keys %params == 4,                '[keep path_info] URI params');
        ok(length $params{'_checksum'},      '[keep path_info] URI checksum');
        is($params{'foo'}, 'bar',            '[keep path_info] URI param:foo');
        is($params{'bar'}, 'baz',            '[keep path_info] URI param:bar');
        is($params{'wubba'}, 'woo',          '[keep path_info] URI param:wubba');


    }
}

$ENV{'REQUEST_METHOD'} = 'POST';
$ENV{'SERVER_PORT'}    = '80';
$ENV{'SCRIPT_NAME'}    = '/cgi-bin/app.cgi';
$ENV{'SERVER_NAME'}    = 'www.example.com';
$ENV{'PATH_INFO'}      = '/my/happy/pathy/info';
$ENV{'QUERY_STRING'}   = 'zap=zoom&zap=zub&guff=gubbins&zap=zuzzu';


WebApp->new->run;





