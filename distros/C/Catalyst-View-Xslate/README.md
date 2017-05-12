# NAME

Catalyst::View::Xslate - Text::Xslate View Class

# SYNOPSIS

    package MyApp::View::Xslate;
    use Moose;
    extends 'Catalyst::View::Xslate';

    1;

# VIEW CONFIGURATION

You may specify the following configuration items in from your config file
or directly on the view object.

## catalyst\_var

The name used to refer to the Catalyst app object in the template

## template\_extension

The suffix used to auto generate the template name from the action name
(when you do not explicitly specify the template filename);

Do not confuse this with the `suffix` option, which is passed directly to
the Text::Xslate object instance. This option works on the filename used
for the initial request, while `suffix` controls what `cascade` and
`include` directives do inside Text::Xslate.

## content\_charset

The charset used to output the response body. The value defaults to 'UTF-8'.

## encode\_body

By default, output will be encoded to `content_charset`.
You can set it to 0 to disable this behavior.
(you need to do this if you're using `Catalyst::Plugin::Unicode::Encoding`)

__NOTE__ Starting with [Catalyst](https://metacpan.org/pod/Catalyst) version 5.90080 Catalyst will automatically
encode to UTF8 any text like body responses.  You should either turn off the
body encoding step in this view using this attribute OR disable this feature
in the application (your subclass of Catalyst.pm).

    MyApp->config(encoding => undef);

Failure to do so will result in double encoding.

## Text::Xslate CONFIGURATION

The following parameters are passed to the Text::Xslate constructor.
When reset during the life cyle of the Catalyst app, these parameters will
cause the previously created underlying Text::Xslate object to be cleared

## path

## cache\_dir

## cache

## header

## escape

## type

## footer

## function

## input\_layer

## module

## syntax

## verbose

## line\_start

## tag\_start

## tag\_end

## warn\_handler

## die\_handler

## pre\_process\_handler

## suffix

Use this to enable TT2 compatible variable methods via Text::Xslate::Bridge::TT2 or Text::Xslate::Bridge::TT2Like

    package MyApp::View::Xslate;
    use Moose;
    extends 'Catalyst::View::Xslate';

    has '+module' => (
        default => sub { [ 'Text::Xslate::Bridge::TT2Like' ] }
    );

# preload

Boolean flag indicating if templates should be preloaded. By default this is enabled.

Preloading templates will basically cutdown the cost of template compilation for the first hit.

## expose\_methods

Use this option to specify methods from the View object to be exposed in the
template. For example, if you have the following View:

    package MyApp::View::Xslate;
    use Moose;
    extends 'Catalyst::View::Xslate';

    sub foo {
        my ( $self, $c, @args ) = @_;
        return ...; # do something with $self, $c, @args
    }

then by setting expose\_methods, you will be able to use $foo() as a function in
the template:

    <: $foo("a", "b", "c") # calls $view->foo( $c, "a", "b", "c" ) :>

`expose_methods` takes either a list of method names to expose, or a hash reference, in order to alias it differently in the template.

    MyApp::View::Xslate->new(
        # exposes foo(), bar(), baz() in the template
        expose_methods => [ qw(foo bar baz) ]
    );

    MyApp::View::Xslate->new(
        # exposes $foo_alias(), $bar_alias(), $baz_alias() in the template,
        # but they will in turn call foo(), bar(), baz(), on the view object.
        expose_methods => {
            foo => "foo_alias",
            bar => "bar_alias",
            baz => "baz_alias",
        }
    );

NOTE: you can mangle the process of building the exposed methods, see `build_exposed_method`.

# METHODS

# `$view-`process($c)>

Called by Catalyst.

## `$view-`render($c, $template, \\%vars)>

Renders the given `$template` using variables \\%vars.

`$template` can be a template file name, or a scalar reference to a template
string.

    $view->render($c, "/path/to/a/template.tx", \%vars );

    $view->render($c, \'This is a xslate template!', \%vars );

## `$view-`preload\_templates>

Preloads templates in $view->path.

## `$view-`build\_exposed\_method>

Hook point for mangling the building process of exposed methods.

# AUTHOR

Copyright (c) 2010 Daisuke Maki `<daisuke@endeworks.jp>`

# LICENSE 

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html
