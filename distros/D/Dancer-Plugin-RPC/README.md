# NAME

Dancer::Plugin::RPC - Configure endpoints for XMLRPC, JSONRPC and RESTRPC procedures

# DESCRIPTION

This module contains plugins for [Dancer](https://metacpan.org/pod/Dancer): [Dancer::Plugin::RPC::XMLRPC](https://metacpan.org/pod/Dancer%3A%3APlugin%3A%3ARPC%3A%3AXMLRPC),
[Dancer::Plugin::RPC::JSONRPC](https://metacpan.org/pod/Dancer%3A%3APlugin%3A%3ARPC%3A%3AJSONRPC) and [Dancer::Plugin::RPC::RESTRPC](https://metacpan.org/pod/Dancer%3A%3APlugin%3A%3ARPC%3A%3ARESTRPC).

## Dancer::Plugin::RPC::XMLRPC

This plugin exposes the new keyword `xmlrpc` that is followed by 2 arguments:
the endpoint and the arguments to configure the xmlrpc-calls at this endpoint.

## Dancer::Plugin::RPC::JSONRPC

This plugin exposes the new keyword `jsonrpc` that is followed by 2 arguments:
the endpoint and the arguments to configure the jsonrpc-calls at this endpoint.

## Dancer::Plugin::RPC::RESTRPC

This plugin exposes the new keyword `restrpc` that is followed by 2 arguments:
the endpoint and the arguments to configure the restrpc-calls at this endpoint.

## General arguments to xmlrpc/jsonrpc/restrpc

The dispatch table is build by endpoint.

### publish => &lt;config|pod|$coderef>

- publish => **config**

    The **arguments** argument should be empty for this publishing type.  
    The dispatch table is build from the YAML-config:

```yaml
        plugins:
            'RPC::XMLRPC':
                '/endpoint1':
                    'Module::Name1':
                        method1: sub1
                        method2: sub2
                    'Module::Name2':
                        method3: sub3
                '/endpoint2':
                    'Module::Name3':
                        method4: sub4
```

- publish => **pod**

    The **arguments** argument must be an Arrayref with module names. The
    POD-directive must be in the same file as the code!  
    The dispatch table is build by parsing the POD for `=for xmlrpc`,
    `=for jsonrpc` or `=for restrpc`.

```perl
        =for xmlrpc <method_name> <sub_name>
```

- publish => **$coderef**

    The **arguments** argument should be empty for this publishing type.  
    With this publishing type, you will need to build your own dispatch table and return it.

```perl
        use Dancer::RPCPlugin::DispatchItem;
        return {
            method1 => dispatch_item(
                package => 'Module::Name1',
                code => Module::Name1->can('sub1'),
            ),
            method2 => dispatch_item(
                package => 'Module::Name1',
                code    => Module::Name1->can('sub2'),
            ),
            method3 => dispatch_item(
                pacakage => 'Module::Name2',
                code     => Module::Name2->can('sub3'),
            ),
        };
```

### arguments => $list

This argumument is needed for publishing type **pod** and must be a list of
module names that contain the pod (and code).

### callback => $coderef

The **callback** argument may contain a `$coderef` that does additional checks
and should return a [Dancer::RPCPlugin::CallbackResult](https://metacpan.org/pod/Dancer%3A%3ARPCPlugin%3A%3ACallbackResult) object.

```perl
    $callback->($request, $method_name, @method_args);
```

Returns for success: `callback_success()`

Returns for failure: `callback_fail(error_code => $code, error_message => $msg)`

This is useful for eg ACL checking.

In the scope of the callback-function you will have the variable
`$Dancer::RPCPlugin::ROUTE_INFO`, a hashref:

```perl
    local $Dancer::RPCPlugin::ROUTE_INFO = {
        plugin        => PLUGIN_NAME,
        endpoint      => $endpoint,
        rpc_method    => $method_name,
        full_path     => request->path,
        http_method   => $http_method,
    };
```

Other plugins may want to put extra information in there to help you decide if
this request should even be honoured.

### code\_wrapper => $coderef

The **code\_wrapper** argument can be used to wrap the code (from the dispatch table).

```perl
    my $wrapper = sub {
        my $code   = shift;
        my $pkg    = shift;
        my $method = shift;
        my $instance = $pkg->new();
        $instance->$code(@_);
    };
```

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

See:

- [http://www.perl.com/perl/misc/Artistic.html](http://www.perl.com/perl/misc/Artistic.html)
- [http://www.gnu.org/copyleft/gpl.html](http://www.gnu.org/copyleft/gpl.html)

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

# COPYRIGHT

&copy; MMXVI - Abe Timmerman <abeltje@cpan.org>
