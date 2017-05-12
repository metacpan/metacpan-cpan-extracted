# NAME

CatalystX::AppBuilder - Build Your Application Instance Programatically

# SYNOPSIS

    # In MyApp.pm
    my $builder = CatalystX::AppBuilder->new(
        appname => 'MyApp',
        plugins => [ ... ],
    )
    $builder->bootstrap();

# DESCRIPTION

WARNING: YMMV regarding this module.

This module gives you a programatic interface to _configuring_ Catalyst
applications.

The main motivation to write this module is: to write reusable Catalyst
appllications. For instance, if you build your MyApp::Base and you wanted to
create a new application afterwards that is _mostly_ like MyApp::Base, 
but slightly tweaked. Perhaps you want to add or remove a plugin or two.
Perhaps you want to tweak just a single parameter.

Traditionally, your option then was to use catalyst.pl and create another
scaffold, and copy/paste the necessary bits, and tweak what you need.

After testing several approaches, it proved that the current Catalyst 
architecture (which is Moose based, but does not allow us to use Moose-ish 
initialization, since the Catalyst app instance does not materialize until 
dispatch time) did not allow the type of inheritance behavior we wanted, so
we decided to create a builder module around Catalyst to overcome this.
Therefore, if/when these obstacles (to us) are gone, this module may
simply dissappear from CPAN. You've been warned.

# HOW TO USE

## DEFINING A CATALYST APP

This module is NOT a "just-execute-this-command-and-you-get-catalyst-running"
module. For the simple applications, please just follow what the Catalyst
manual gives you.

However, if you _really_ wanted to, you can define a simple Catalyst
app like so:

    # in MyApp.pm
    use strict;
    use CatalystX::AppBuilder;
    
    my $builder = CatalystX::AppBuilder->new(
        debug  => 1, # if you want
        appname => "MyApp",
        plugins => [ qw(
            Authentication
            Session
            # and others...
        ) ],
        config  => { ... }
    );

    $builder->bootstrap();

## DEFINING YOUR CatalystX::AppBuilder SUBCLASS

The originally intended approach to using this module is to create a
subclass of CatalystX::AppBuilder and configure it to your own needs,
and then keep reusing it.

To build your own MyApp::Builder, you just need to subclass it:

    package MyApp::Builder;
    use Moose;

    extends 'CatalystX::AppBuilder';

Then you will be able to give it defaults to the various configuration
parameters:

    override _build_config => sub {
        my $config = super(); # Get what CatalystX::AppBuilder gives you
        $config->{ SomeComponent } = { ... };
        return $config;
    };

    override _build_plugins => sub {
        my $plugins = super(); # Get what CatalystX::AppBuilder gives you

        push @$plugins, qw(
            Unicode
            Authentication
            Session
            Session::Store::File
            Session::State::Cookie
        );

        return $plugins;
    };

Then you can simply do this instead of giving parameters to 
CatalystX::AppBuilder every time:

    # in MyApp.pm
    use MyApp::Builder;
    MyApp::Builder->new()->bootstrap();

## EXTENDING A CATALYST APP USING CatalystX::AppBuilder

Once you created your own MyApp::Builder, you can keep inheriting it to 
create custom Builders which in turn create more custom Catalyst applications:

    package MyAnotherApp::Builder;
    use Moose;

    extends 'MyApp::Builder';

    override _build_superclasses => sub {
        return [ 'MyApp' ]
    }

    ... do your tweaking ...

    # in MyAnotherApp.pm
    use MyAnotherApp::Builder;

    MyAnotherApp::Builder->new()->bootstrap();

Voila, you just reused every inch of Catalyst app that you created via
inheritance!

## INCLUDING EVERY PATH FROM YOUR INHERITANCE HIERARCHY

Components like Catalyst::View::TT, which in turn uses Template Toolkit
inside, allows you to include multiple directories to look for the 
template files.

This can be used to recycle the templates that you used in a base application.

CatalystX::AppBuilder gives you a couple of tools to easily include
paths that are associated with all of the Catalyst applications that are
inherited. For example, if you have MyApp::Base and MyApp::Extended,
and MyApp::Extended is built using MyApp::Extended::Builder, you can do 
something like this:

    package MyApp::Extended::Builder;
    use Moose;

    extends 'CatalystX::AppBuilder'; 

    override _build_superclasses => sub {
        return [ 'MyApp::Base' ]
    };

    override _build_config => sub {
        my $self = shift;
        my $config = super();

        $config->{'View::TT'}->{INCLUDE_PATH} = 
            [ $self->inherited_path_to('root') ];
        # Above is equivalent to 
        #    [ MyApp::Extended->path_to('root'), MyApp::Base->path_to('root') ]
    };

So now you can refer to some template, and it will first look under the
first app, then the base app, thus allowing you to reuse the templates.

# ATTRIBUTES

## appname 

The module name of the Catalyst application. Required.

## appmeta 

The metaclass object of the Catalyst application. Users cannot set this.

## debug

Boolean flag to enable debug output in the application

## version

The version string to use (probably meaningless...)

## superclasses

The list of superclasses of the Catalyst application.

## config

The config hash to give to the Catalyst application.

## plugins

The list of plugins to give to the Catalyst application.

# METHODS

## bootstrap($runsetup)

Bootstraps the Catalyst app.

## inherited\_path\_to(@pathspec)

Calls path\_to() on all Catalyst applications in the inheritance tree.

## app\_path\_to(@pathspec);

Calls path\_to() on the curent Catalyst application.

# TODO

Documentation. Samples. Tests.

# AUTHOR

Daisuke Maki `<daisuke@endeworks.jp>`

# LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html
