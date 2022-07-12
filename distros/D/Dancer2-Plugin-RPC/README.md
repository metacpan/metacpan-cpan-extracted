# NAME

Dancer2::Plugin::RPC - Namespace for XMLRPC, JSONRPC2 and RESTRPC plugins

# DESCRIPTION

This module contains plugins for [Dancer2](https://metacpan.org/pod/Dancer2): [Dancer2::Plugin::RPC::XML](https://metacpan.org/pod/Dancer2%3A%3APlugin%3A%3ARPC%3A%3AXML),
[Dancer2::Plugin::RPC::JSON](https://metacpan.org/pod/Dancer2%3A%3APlugin%3A%3ARPC%3A%3AJSON) and [Dancer2::Plugin::RPC::REST](https://metacpan.org/pod/Dancer2%3A%3APlugin%3A%3ARPC%3A%3AREST).

## Dancer2::Plugin::RPC::XML

This plugin exposes the new keyword `xmlrpc` that is followed by 2 arguments:
the endpoint and the arguments to configure the xmlrpc-calls at this endpoint.

## Dancer2::Plugin::RPC::JSON

This plugin exposes the new keyword `jsonrpc` that is followed by 2 arguments:
the endpoint and the arguments to configure the jsonrpc-calls at this endpoint.

## Dancer2::Plugin::RPC::REST

This plugin exposes the new keyword `restrpc` that is followed by 2 arguments:
the endpoint and the arguments to configure the restrpc-calls at this endpoint.

## General arguments to xmlrpc/jsonrpc/restrpc

The dispatch table is build by endpoint.

### publish => &lt;config|pod|$coderef>

- publish => **config**

    The dispatch table is build from the YAML-config:
```yaml
        plugins:
            'RPC::XML':
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
    The **arguments** argument should be empty for this publishing type.

- publish => **pod**

    The dispatch table is build by parsing the POD for `=for xmlrpc`,
    `=for jsonrpc` or `=for restrpc`.
```perl
        =for xmlrpc <method_name> <sub_name>
```
    The **arguments** argument must be an Arrayref with module names. The
    POD-directive must be in the same file as the code!

- publish => **$coderef**

    With this publishing type, you will need to build your own dispatch table and return it.
```perl
        use Dancer2::RPCPlugin::DispatchItem;
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
and should return a [Dancer2::RPCPlugin::CallbackResult](https://metacpan.org/pod/Dancer2%3A%3ARPCPlugin%3A%3ACallbackResult) object.

    $callback->($request, $method_name, @method_args);

Returns for success: `callback_success()`

Returns for failure: `callback_fail(error_code => $code, error_message => $msg)`

This is useful for ACL checking.

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

# AUTHOR

E<copy> MMXVII - Abe Timmerman <abeltje@cpan.org>
