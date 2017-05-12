
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

        # Bare path_link - should remove the path_info
        my $link = $self->path_link;

        my $uri = URI->new($link);
        my %params = $uri->query_form;

        is($uri->path, $self_url->path,  '[plain checksum] URI path');
        ok(keys %params == 1,            '[plain checksum] URI params');
        ok(length $params{'_checksum'},  '[plain checksum] URI checksum');

        # Test explicitly passing url params (w/o path_info (empty_string))
        $link = $self->path_link('', wubba => 'woo', 'foo' => 'bar', bar=> 'baz');

        $uri = URI->new($link);
        %params = $uri->query_form;

        is($uri->path, $self_url->path,      '[params path_info=""] URI path');
        ok(keys %params == 4,                '[params path_info=""] URI params');
        ok(length $params{'_checksum'},      '[params path_info=""] URI checksum');
        is($params{'foo'}, 'bar',            '[params path_info=""] URI param:foo');
        is($params{'bar'}, 'baz',            '[params path_info=""] URI param:bar');
        is($params{'wubba'}, 'woo',          '[params path_info=""] URI param:wubba');

        # Test explicitly passing url params (w/o path_info (undef)
        $link = $self->path_link(undef, wubba => 'woo', 'foo' => 'bar', bar=> 'baz');

        $uri = URI->new($link);
        %params = $uri->query_form;

        is($uri->path, $self_url->path,      '[params path_info=undef] URI path');
        ok(keys %params == 4,                '[params path_info=undef] URI params');
        ok(length $params{'_checksum'},      '[params path_info=undef] URI checksum');
        is($params{'foo'}, 'bar',            '[params path_info=undef] URI param:foo');
        is($params{'bar'}, 'baz',            '[params path_info=undef] URI param:bar');
        is($params{'wubba'}, 'woo',          '[params path_info=undef] URI param:wubba');


        # Test with new path_info
        $link = $self->path_link('/sic/transit/gloria/mundi',
            wubba => 'woo','foo' => 'bar', bar=> 'baz'
        );

        $uri = URI->new($link);
        %params = $uri->query_form;

        my $u = $self_url->clone;
        $u->path_segments($u->path_segments, qw(sic transit gloria mundi));

        is($uri->path, $u->path,             '[new path_info] URI path');
        ok(keys %params == 4,                '[new path_info] URI params');
        ok(length $params{'_checksum'},      '[new path_info] URI checksum');
        is($params{'foo'}, 'bar',            '[new path_info] URI param:foo');
        is($params{'bar'}, 'baz',            '[new path_info] URI param:bar');
        is($params{'wubba'}, 'woo',          '[new path_info] URI param:wubba');

    }
}

$ENV{'REQUEST_METHOD'} = 'POST';
$ENV{'SERVER_PORT'}    = '80';
$ENV{'SCRIPT_NAME'}    = '/cgi-bin/app.cgi';
$ENV{'SERVER_NAME'}    = 'www.example.com';
$ENV{'PATH_INFO'}      = '/my/happy/pathy/info';
$ENV{'QUERY_STRING'}   = 'zap=zoom&zap=zub&guff=gubbins&zap=zuzzu';


WebApp->new->run;





