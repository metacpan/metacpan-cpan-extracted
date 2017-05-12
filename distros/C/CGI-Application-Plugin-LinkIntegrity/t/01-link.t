
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
        );
    }

    sub start {
        my $self = shift;

        # Test bad digest module
        $self->link_integrity_config(
            digest_module => '',
            secret        => 'foo',
        );
        eval {
            $self->link('/fee/fie/foo');
        };
        ok($@, '[usage] bad digest_module caught');

        $self->link_integrity_config(secret => 'foo');  # this should reset the config


        # Test that the checksum is created
        my $link = $self->link('/foo/bar/baz');

        my $uri = URI->new($link);
        my %params = $uri->query_form;

        is($uri->path, '/foo/bar/baz',  '[basic checksum] URI path');
        ok(keys %params == 1,           '[basic checksum] URI params');
        ok(length $params{'_checksum'}, '[basic checksum] URI checksum');

        # Test that url params are retained
        $link = $self->link('/foo/bar/baz/boom?wubba=woo&foo=bar&bar=baz');

        $uri = URI->new($link);
        %params = $uri->query_form;

        is($uri->path, '/foo/bar/baz/boom',  '[params (qs)] URI path');
        ok(keys %params == 4,                '[params (qs)] URI params');
        ok(length $params{'_checksum'},      '[params (qs)] URI checksum');
        is($params{'foo'}, 'bar',            '[params (qs)] URI param:foo');
        is($params{'bar'}, 'baz',            '[params (qs)] URI param:bar');
        is($params{'wubba'}, 'woo',          '[params (qs)] URI param:wubba');

        # Test explicitly passing url params
        $link = $self->link('/fee/fie/foo?wubba=woo', 'foo' => 'bar', bar=> 'baz');

        $uri = URI->new($link);
        %params = $uri->query_form;

        is($uri->path, '/fee/fie/foo',       '[params] URI path');
        ok(keys %params == 4,                '[params] URI params');
        ok(length $params{'_checksum'},      '[params] URI checksum');
        is($params{'foo'}, 'bar',            '[params] URI param:foo');
        is($params{'bar'}, 'baz',            '[params] URI param:bar');
        is($params{'wubba'}, 'woo',          '[params] URI param:wubba');


        # Test changing the checksum param
        $self->link_integrity_config(
            checksum_param => 'gordon',
            secret         => 'sooper secret',
        );
        $link = $self->link('/foo/bar/baz');
        $uri = URI->new($link);
        %params = $uri->query_form;

        $uri = URI->new($link);
        %params = $uri->query_form;

        is($uri->path, '/foo/bar/baz',  '[checksum_param] URI path');
        ok(keys %params == 1,           '[checksum_param] URI params');
        ok(length $params{'gordon'},    '[checksum_param] URI checksum');

    }
}


WebApp->new->run;





