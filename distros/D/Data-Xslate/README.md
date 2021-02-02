# NAME

Data::Xslate - Templatize your data.

# SYNOPSIS

```perl
use Data::Xslate;

my $xslate = Data::Xslate->new();

my $output = $xslate->render( $input );
```

Given this input data structure:

```perl
{
    color_names => ['red', 'blue', 'orange'],
    email => {
        message => 'Do you like the color <: $user.color_name :>?',
        subject => 'Hello <: $user.name :>!',
        to      => '=user.email',
    },
    'email.from=' => 'george@example.com',
    user => {
        color_id => 2,
        color_name => '<: node("color_names")[$color_id] :>',
        email => '<: $login :>@example.com',
        login => 'john',
        name  => 'John',
    },
}
```

This data will be output:

```perl
{
    color_names => ['red', 'blue', 'orange'],
    email => {
        from => 'george@example.com',
        message => 'Do you like the color orange?',
        subject => 'Hello John!',
        to => 'john@example.com',
    },
    user => {
        color_id => '2',
        color_name => 'orange',
        email => 'john@example.com',
        login => 'john',
        name => 'John',
    },
}
```

# DESCRIPTION

This module provides a syntax for templatizing data structures.

## Templating

The most powerful feature by far is templating, where you can
use [Text::Xslate](https://metacpan.org/pod/Text%3A%3AXslate) in your values.

```perl
{
    foo => 'green',
    bar => 'It is <: $foo :>!',
}
# { foo=>'green', bar=>'It is green!' }
```

There is a lot you can do with this beyond simply including values
from other keys:

```perl
{
    prod => 1,
    memcached_host => '<: if $prod { :>memcached.example.com<: } else { :>127.0.0.1<: } :>',
}
# { prod=>1, memcached_host=>'memcached.example.com' }
```

Values in arrays are also processed for templating:

```perl
{
    ceo_name => 'Sara',
    employees => [
        '<: $ceo_name :>',
        'Fred',
        'Alice',
    ],
}
# {
#     ceo_name => 'Sara',
#     employees => [
#         'Sara',
#         'Fred',
#         'Alice',
#     ],
# }
```

As well as using array values in a template:

```perl
{ foo=>'<: $bar.1 :>', bar=>[4,5,6] }
# { foo=>5, bar=>[4,5,6] }
```

Data structures of any arbitrary depth and complexity are handled
correctly, and keys from any level can be referred to following
the ["Scope"](#scope) rules.

## Substitution

Substituion allows you to retrieve a value from one key and use it
as the value for the current key.  To do this your hash or array
value must start with the ["substitution\_tag"](#substitution_tag) (defaults to `=`):

```perl
{
    foo => 14,
    bar => '=foo',
}
# { foo=>14, bar=>14 }
```

Templating could be used instead of substitution:

```perl
{
    foo => 14,
    bar => '<: $foo :>',
}
```

But, templating only works with strings.  Substitutions become vital
when you want to substitute an array or hash:

```perl
{
    foo => [1,2,3],
    bar => '=foo',
}
# { foo=>[1,2,3], bar=>[1,2,3] }
```

The keys in substitution follow the ["Scope"](#scope) rules.

## Nested Keys

When setting a key value the key can point deeper into the structure by
separating keys with the ["key\_separator"](#key_separator) (defaults to a dot, `.`),
and ending the key with the ["nested\_key\_tag"](#nested_key_tag) (defaults to `=`).
Consider this:

```perl
{ a=>{ b=>1 }, 'a.b=' => 2 }
# { a=>{ b=>2 } }
```

So, nested keys are a way to set values in other data structures.  This
feature is very handy when you are merging data structures from different
sources and one data structure will override a subset of values in the
other.

## Key Paths

When referring to other values in ["Templating"](#templating), ["Substitution"](#substitution), or
["Nested Keys"](#nested-keys) you are specifying a path made up of keys for this module
to walk and find a value to retrieve.

So, when you specify a key path such as `foo.bar` you are looking for a hash
with the key `foo` who's value is a hash and then retrieving the value
of the `bar` key in it.

Arrays are fully supported in these key paths so that if you specify
a key path such as `bar.0` you are looking for a hash with the `bar`
key whose value is an array, and then the first value in the array is
fetched.

Note that the above examples assume that ["key\_separator"](#key_separator) is a dot (`.`),
the default.

## Scope

When using either ["Substitution"](#substitution) or ["Templating"](#templating) you specify a key to be
acted on.  This key is found using scope-aware rules where the key is searched for
in a similar fashion to how you'd expect when dealing with lexical variables in
programming.

For example, you can refer to a key in the same scope:

```perl
{ a=>1, b=>'=a' }
```

You may refer to a key in a lower scope:

```perl
{ a=>{ b=>1 }, c=>'=a.b' }
```

You may refer to a key in a higher scope:

```perl
{ a=>{ b=>'=c' }, c=>1 }
```

You may refer to a key in a higher scope that is nested:

```perl
{ a=>{ b=>'=c.d' }, c=>{ d=>1 } }
```

The logic behind this is pretty flexible, so more complex use cases will
just work like you would expect.

If you'd rather avoid this scoping you can prepend any key with the ["key\_separator"](#key_separator)
(defaults to a dot, `.`), and it will be looked for at the root of the config data
only.

In the case of templating a special `node` function is provided which
will allow you to retrieve an absolute key.  For example these two lines
would do the same thing (printing out a relative key value):

```
<: $foo.bar :>
<: node("foo.bar") :>
```

But if you wanted to refer to an absolute key you'd have to do this:

```
<: node(".foo.bar") :>
```

# ARGUMENTS

Any arguments you pass to `new`, which this class does not directly
handle, will be used when creating the underlying [Text::Xslate](https://metacpan.org/pod/Text%3A%3AXslate) object.
So, any arguments which [Text::Xslate](https://metacpan.org/pod/Text%3A%3AXslate) supports may be set.  For example:

```perl
my $xslate = Data::Xslate->new(
    substitution_tag => ']]', # A Data::Xslate argument.
    verbose          => 2,    # A Text::Xslate argument.
);
```

## substitution\_tag

The string to look for at the beginning of any string value which
signifies ["Substitution"](#substitution).  Defaults to `=`.  This is used in
data like this:

```perl
{ a=>{ b=>2 }, c => '=a.b' }
# { a=>{ b=>2 }, c => 2 }
```

## nested\_key\_tag

The string to look for at the end of any key which signifies
["Nested Keys"](#nested-keys).  Defaults to `=`.  This is used in data
like this:

```perl
{ a=>{ b=>2 }, 'a.c=' => 3 }
# { a=>{ b=>2, c=>3 } }
```

## key\_separator

The string which will be used between keys.  The default is a dot (`.`)
which looks like this:

```perl
{ a=>{ b=>2 }, c => '=a.b' }
```

Whereas, for example, if you changed the `key_separator` to a forward
slash it would look like this:

```perl
{ a=>{ b=>2 }, c => '=a/b' }
```

Which looks rather good with absolute keys:

```perl
{ a=>{ b=>2 }, c => '=/a/b' }
```

# METHODS

## render

```perl
my $data_out = $xslate->render( $data_in );
```

Processes the data and returns new data.  The passed in data is not
modified.

# SUPPORT

Please submit bugs and feature requests to the
Data-Xslate GitHub issue tracker:

[https://github.com/bluefeet/Data-Xslate/issues](https://github.com/bluefeet/Data-Xslate/issues)

# AUTHORS

```
Aran Clary Deltac <bluefeet@gmail.com>
Mohammad S Anwar <mohammad.anwar@yahoo.com>
```

# ACKNOWLEDGEMENTS

Thanks to [ZipRecruiter](https://www.ziprecruiter.com/)
for encouraging their employees to contribute back to the open
source ecosystem.  Without their dedication to quality software
development this distribution would not exist.

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
