[![Actions Status](https://github.com/kfly8/p5-Amon2-Plugin-Web-CpanelJSON/actions/workflows/test.yml/badge.svg)](https://github.com/kfly8/p5-Amon2-Plugin-Web-CpanelJSON/actions) [![Coverage Status](http://codecov.io/github/kfly8/p5-Amon2-Plugin-Web-CpanelJSON/coverage.svg?branch=main)](https://codecov.io/github/kfly8/p5-Amon2-Plugin-Web-CpanelJSON?branch=main) [![MetaCPAN Release](https://badge.fury.io/pl/Amon2-Plugin-Web-CpanelJSON.svg)](https://metacpan.org/release/Amon2-Plugin-Web-CpanelJSON)
# NAME

Amon2::Plugin::Web::CpanelJSON - Cpanel::JSON::XS plugin

# SYNOPSIS

```perl
use Amon2::Lite;
use Cpanel::JSON::XS::Type;
use HTTP::Status qw(:constants);

__PACKAGE__->load_plugins(qw/Web::CpanelJSON/);

use constant HelloWorld => {
    message => JSON_TYPE_STRING,
};

get '/' => sub {
    my $c = shift;
    return $c->render_json(+{ message => 'HELLO!' }, HelloWorld, HTTP_OK);
};

__PACKAGE__->to_app();
```

# DESCRIPTION

This is a JSON plugin for Amon2.
The differences from Amon2::Plugin::Web::JSON are as follows.

\* Cpanel::JSON::XS::Type is available

\* HTTP status code can be specified

\* Flexible Configurations

# METHODS

- `$c->render_json($data, $json_spec, $status=200);`

    Generate JSON `$data` and `$json_spec` and returns instance of [Plack::Response](https://metacpan.org/pod/Plack%3A%3AResponse).
    `$json_spec` is a structure for JSON encoding defined in [Cpanel::JSON::XS::Type](https://metacpan.org/pod/Cpanel%3A%3AJSON%3A%3AXS%3A%3AType).

# CONFIGURATION

- json

    Parameters of [Cpanel::JSON::XS](https://metacpan.org/pod/Cpanel%3A%3AJSON%3A%3AXS). Default is as follows:

    ```perl
    ascii => !!1,
    ```

    Any parameters can be set:

    ```perl
     __PACKAGE__->load_plugins(
        'Web::CpanelJSON' => {
            json => {
                ascii     => 0,
                utf8      => 1,
                canonical => 1,
            }
        }
    );
    ```

- secure\_headers

    Parameters of [HTTP::SecureHeaders](https://metacpan.org/pod/HTTP%3A%3ASecureHeaders). Default is as follows:

    ```perl
    content_security_policy           => "default-src 'none'",
    strict_transport_security         => 'max-age=631138519',
    x_content_type_options            => 'nosniff',
    x_download_options                => undef,
    x_frame_options                   => 'DENY',
    x_permitted_cross_domain_policies => 'none',
    x_xss_protection                  => '1; mode=block',
    referrer_policy                   => 'no-referrer',
    ```

- json\_escape\_filter

    Escapes JSON to prevent XSS. Default is as follows:

    ```perl
    '+' => '\\u002b',
    '<' => '\\u003c',
    '>' => '\\u003e',
    ```

- name

    Name of method. Default: 'render\_json'

- unbless\_object

    Default: undef

    This option is preprocessing coderef encoding an blessed object in JSON.
    For example, the code using [Object::UnblessWithJSONSpec](https://metacpan.org/pod/Object%3A%3AUnblessWithJSONSpec) is as follows:

    ```perl
    use Object::UnblessWithJSONSpec ();

    __PACKAGE__->load_plugins(
        'Web::CpanelJSON' => {
            unbless_object => \&Object::UnblessWithJSONSpec::unbless_with_json_spec,
        }
    );

    ...

    package Some::Object {
        use Mouse;

        has message => (
            is => 'ro',
        );
    }

    my $object = Some::Object->new(message => 'HELLO');
    $c->render_json($object, { message => JSON_TYPE_STRING })
    # => {"message":"HELLO"}
    ```

- status\_code\_field

    Default: undef

    It specify the field name of JSON to be embedded in the `X-API-Status` header.
    Default is `undef`. If you set the `undef` to disable this `X-API-Status` header.

    ```perl
    __PACKAGE__->load_plugins(
        'Web::CpanelJSON' => { status_code_field => 'status' }
    );

    ...

    $c->render_json({ status => 200, message => 'ok' })
    # send response header 'X-API-Status: 200'
    ```

    In general JSON API error code embed in a JSON by JSON API Response body.
    But can not be logging the error code of JSON for the access log of a general Web Servers.
    You can possible by using the `X-API-Status` header.

- defence\_json\_hijacking\_for\_legacy\_browser

    Default: false

# LICENSE

Copyright (C) kfly8.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

kfly8 <kfly@cpan.org>
