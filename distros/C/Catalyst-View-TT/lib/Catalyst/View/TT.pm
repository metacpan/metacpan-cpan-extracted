package Catalyst::View::TT;

use strict;
use warnings;

use base qw/Catalyst::View/;
use Data::Dump 'dump';
use Template;
use Template::Timer;
use MRO::Compat;
use Scalar::Util qw/blessed weaken/;

our $VERSION = '0.46';
$VERSION =~ tr/_//d;

__PACKAGE__->mk_accessors('template');
__PACKAGE__->mk_accessors('expose_methods');
__PACKAGE__->mk_accessors('include_path');
__PACKAGE__->mk_accessors('content_type');

*paths = \&include_path;

=head1 NAME

Catalyst::View::TT - Template View Class

=head1 SYNOPSIS

# use the helper to create your View

    myapp_create.pl view Web TT

# add custom configuration in View/Web.pm

    __PACKAGE__->config(
        # any TT configuration items go here
        TEMPLATE_EXTENSION => '.tt',
        CATALYST_VAR => 'c',
        TIMER        => 0,
        ENCODING     => 'utf-8'
        # Not set by default
        PRE_PROCESS        => 'config/main',
        WRAPPER            => 'site/wrapper',
        render_die => 1, # Default for new apps, see render method docs
        expose_methods => [qw/method_in_view_class/],
    );

# add include path configuration in MyApp.pm

    __PACKAGE__->config(
        'View::Web' => {
            INCLUDE_PATH => [
                __PACKAGE__->path_to( 'root', 'src' ),
                __PACKAGE__->path_to( 'root', 'lib' ),
            ],
        },
    );

# render view from lib/MyApp.pm or lib/MyApp::Controller::SomeController.pm

    sub message : Global {
        my ( $self, $c ) = @_;
        $c->stash->{template} = 'message.tt2';
        $c->stash->{message}  = 'Hello World!';
        $c->forward( $c->view('Web') );
    }

# access variables from template

    The message is: [% message %].

    # example when CATALYST_VAR is set to 'Catalyst'
    Context is [% Catalyst %]
    The base is [% Catalyst.req.base %]
    The name is [% Catalyst.config.name %]

    # example when CATALYST_VAR isn't set
    Context is [% c %]
    The base is [% base %]
    The name is [% name %]

=cut

sub _coerce_paths {
    my ( $paths, $dlim ) = shift;
    return () if ( !$paths );
    return @{$paths} if ( ref $paths eq 'ARRAY' );

    # tweak delim to ignore C:/
    unless ( defined $dlim ) {
        $dlim = ( $^O eq 'MSWin32' ) ? ':(?!\\/)' : ':';
    }
    return split( /$dlim/, $paths );
}

sub new {
    my ( $class, $c, $arguments ) = @_;
    my $config = {
        EVAL_PERL          => 0,
        TEMPLATE_EXTENSION => '',
        CLASS              => 'Template',
        %{ $class->config },
        %{$arguments},
    };
    if ( ! (ref $config->{INCLUDE_PATH} eq 'ARRAY') ) {
        my $delim = $config->{DELIMITER};
        my @include_path
            = _coerce_paths( $config->{INCLUDE_PATH}, $delim );
        if ( !@include_path ) {
            my $root = $c->config->{root};
            my $base = Path::Class::dir( $root, 'base' );
            @include_path = ( "$root", "$base" );
        }
        $config->{INCLUDE_PATH} = \@include_path;
    }

    # if we're debugging and/or the TIMER option is set, then we install
    # Template::Timer as a custom CONTEXT object, but only if we haven't
    # already got a custom CONTEXT defined

    if ( $config->{TIMER} ) {
        if ( $config->{CONTEXT} ) {
            $c->log->error(
                'Cannot use Template::Timer - a TT CONTEXT is already defined'
            );
        }
        else {
            $config->{CONTEXT} = Template::Timer->new(%$config);
        }
    }

    if ( $c->debug && $config->{DUMP_CONFIG} ) {
        $c->log->debug( "TT Config: ", dump($config) );
    }

    my $self = $class->next::method(
        $c, { %$config },
    );

    # Set base include paths. Local'd in render if needed
    $self->include_path($config->{INCLUDE_PATH});

    $self->expose_methods($config->{expose_methods});
    $self->config($config);

    # Creation of template outside of call to new so that we can pass [ $self ]
    # as INCLUDE_PATH config item, which then gets ->paths() called to get list
    # of include paths to search for templates.

    # Use a weakened copy of self so we don't have loops preventing GC from working
    my $copy = $self;
    Scalar::Util::weaken($copy);
    $config->{INCLUDE_PATH} = [ sub { $copy->paths } ];

    if ( $config->{PROVIDERS} ) {
        my @providers = ();
        if ( ref($config->{PROVIDERS}) eq 'ARRAY') {
            foreach my $p (@{$config->{PROVIDERS}}) {
                my $pname = $p->{name};
                my $prov = 'Template::Provider';
                if($pname eq '_file_')
                {
                    $p->{args} = { %$config };
                }
                else
                {
                    if($pname =~ s/^\+//) {
                        $prov = $pname;
                    }
                    else
                    {
                        $prov .= "::$pname";
                    }
                    # We copy the args people want from the config
                    # to the args
                    $p->{args} ||= {};
                    if ($p->{copy_config}) {
                        map  { $p->{args}->{$_} = $config->{$_}  }
                                   grep { exists $config->{$_} }
                                   @{ $p->{copy_config} };
                    }
                }
                local $@;
                eval "require $prov";
                if(!$@) {
                    push @providers, "$prov"->new($p->{args});
                }
                else
                {
                    $c->log->warn("Can't load $prov, ($@)");
                }
            }
        }
        delete $config->{PROVIDERS};
        if(@providers) {
            $config->{LOAD_TEMPLATES} = \@providers;
        }
    }

    $self->{template} =
        $config->{CLASS}->new($config) || do {
            my $error = $config->{CLASS}->error();
            $c->log->error($error);
            $c->error($error);
            return undef;
        };


    return $self;
}

sub process {
    my ( $self, $c ) = @_;

    my $template = $c->stash->{template}
      ||  $c->action . $self->config->{TEMPLATE_EXTENSION};

    unless (defined $template) {
        $c->log->debug('No template specified for rendering') if $c->debug;
        return 0;
    }

    local $@;
    my $output = eval { $self->render($c, $template) };
    if (my $err = $@) {
        return $self->_rendering_error($c, $template . ': ' . $err);
    }
    if (blessed($output) && $output->isa('Template::Exception')) {
        $self->_rendering_error($c, $output);
    }

    unless ( $c->response->content_type ) {
        my $default = $self->content_type || 'text/html; charset=UTF-8';
        $c->response->content_type($default);
    }

    $c->response->body($output);

    return 1;
}

sub _rendering_error {
    my ($self, $c, $err) = @_;
    my $error = qq/Couldn't render template "$err"/;
    $c->log->error($error);
    $c->error($error);
    return 0;
}

sub render {
    my ($self, $c, $template, $args) = @_;

    $c->log->debug(qq/Rendering template "$template"/) if $c && $c->debug;

    my $output;
    my $vars = {
        (ref $args eq 'HASH' ? %$args : %{ $c->stash() }),
        $self->template_vars($c)
    };

    local $self->{include_path} =
        [ @{ $vars->{additional_template_paths} }, @{ $self->{include_path} } ]
        if ref $vars->{additional_template_paths};

    unless ( $self->template->process( $template, $vars, \$output ) ) {
        if (exists $self->{render_die}) {
            die $self->template->error if $self->{render_die};
            return $self->template->error;
        }
        $c->log->debug('The Catalyst::View::TT render() method will start dying on error in a future release. Unless you are calling the render() method manually, you probably want the new behaviour, so set render_die => 1 in config for ' . blessed($self) . '. If you wish to continue to return the exception rather than throwing it, add render_die => 0 to your config.') if $c && $c->debug;
        return $self->template->error;
    }
    return $output;
}

sub template_vars {
    my ( $self, $c ) = @_;

    return  () unless $c;
    my $cvar = $self->config->{CATALYST_VAR};

    my %vars = defined $cvar
      ? ( $cvar => $c )
      : (
        c    => $c,
        base => $c->req->base,
        name => $c->config->{name}
      );

    if ($self->expose_methods) {
        my $meta = $self->meta;
        foreach my $method_name (@{$self->expose_methods}) {
            my $method = $meta->find_method_by_name( $method_name );
            unless ($method) {
                Catalyst::Exception->throw( "$method_name not found in TT view" );
            }
            my $method_body = $method->body;
            my $weak_ctx = $c;
            weaken $weak_ctx;
            my $sub = sub {
                my @args = @_;
                my $ret;
                eval {
                    $ret = $self->$method_body($weak_ctx, @args);
                };
                if ($@) {
                    if (blessed($@)) {
                        die $@;
                    } else {
                        Catalyst::Exception->throw($@);
                    }
                }
                return $ret;
            };
            $vars{$method_name} = $sub;
        }
    }
    return %vars;
}

1;

__END__

=head1 DESCRIPTION

This is the Catalyst view class for the L<Template Toolkit|Template>.
Your application should defined a view class which is a subclass of
this module. Throughout this manual it will be assumed that your application
is named F<MyApp> and you are creating a TT view named F<Web>; these names
are placeholders and should always be replaced with whatever name you've
chosen for your application and your view. The easiest way to create a TT
view class is through the F<myapp_create.pl> script that is created along
with the application:

    $ script/myapp_create.pl view Web TT

This creates a F<MyApp::View::Web.pm> module in the F<lib> directory (again,
replacing C<MyApp> with the name of your application) which looks
something like this:

    package FooBar::View::Web;
    use Moose;

    extends 'Catalyst::View::TT';

    __PACKAGE__->config(DEBUG => 'all');

Now you can modify your action handlers in the main application and/or
controllers to forward to your view class.  You might choose to do this
in the end() method, for example, to automatically forward all actions
to the TT view class.

    # In MyApp or MyApp::Controller::SomeController

    sub end : Private {
        my( $self, $c ) = @_;
        $c->forward( $c->view('Web') );
    }

But if you are using the standard auto-generated end action, you don't even need
to do this!

    # in MyApp::Controller::Root
    sub end : ActionClass('RenderView') {} # no need to change this line

    # in MyApp.pm
    __PACKAGE__->config(
        ...
        default_view => 'Web',
    );

This will Just Work.  And it has the advantages that:

=over 4

=item *

If you want to use a different view for a given request, just set 
<< $c->stash->{current_view} >>.  (See L<Catalyst>'s C<< $c->view >> method
for details.

=item *

<< $c->res->redirect >> is handled by default.  If you just forward to 
C<View::Web> in your C<end> routine, you could break this by sending additional
content.

=back

See L<Catalyst::Action::RenderView> for more details.

=head2 CONFIGURATION

There are a three different ways to configure your view class.  The
first way is to call the C<config()> method in the view subclass.  This
happens when the module is first loaded.

    package MyApp::View::Web;
    use Moose;
    extends 'Catalyst::View::TT';

    __PACKAGE__->config({
        PRE_PROCESS  => 'config/main',
        WRAPPER      => 'site/wrapper',
    });

You may also override the configuration provided in the view class by adding
a 'View::Web' section to your application config.

This should generally be used to inject the include paths into the view to
avoid the view trying to load the application to resolve paths.

    .. inside MyApp.pm ..
    __PACKAGE__->config(
        'View::Web' => {
            INCLUDE_PATH => [
                __PACKAGE__->path_to( 'root', 'templates', 'lib' ),
                __PACKAGE__->path_to( 'root', 'templates', 'src' ),
            ],
        },
    );

You can also configure your view from within your config file if you're
using L<Catalyst::Plugin::ConfigLoader>. This should be reserved for
deployment-specific concerns. For example:

    # MyApp_local.conf (Config::General format)

    <View Web>
      WRAPPER "custom_wrapper"
      INCLUDE_PATH __path_to('root/templates/custom_site')__
      INCLUDE_PATH __path_to('root/templates')__
    </View>

might be used as part of a simple way to deploy different instances of the
same application with different themes.

=head2 DYNAMIC INCLUDE_PATH

Sometimes it is desirable to modify INCLUDE_PATH for your templates at run time.

Additional paths can be added to the start of INCLUDE_PATH via the stash as
follows:

    $c->stash->{additional_template_paths} =
        [$c->config->{root} . '/test_include_path'];

If you need to add paths to the end of INCLUDE_PATH, there is also an
include_path() accessor available:

    push( @{ $c->view('Web')->include_path }, qw/path/ );

Note that if you use include_path() to add extra paths to INCLUDE_PATH, you
MUST check for duplicate paths. Without such checking, the above code will add
"path" to INCLUDE_PATH at every request, causing a memory leak.

A safer approach is to use include_path() to overwrite the array of paths
rather than adding to it. This eliminates both the need to perform duplicate
checking and the chance of a memory leak:

    @{ $c->view('Web')->include_path } = qw/path another_path/;

If you are calling C<render> directly then you can specify dynamic paths by
having a C<additional_template_paths> key with a value of additional directories
to search. See L</CAPTURING TEMPLATE OUTPUT> for an example showing this.

=head2 Unicode (pre Catalyst v5.90080)

B<NOTE> Starting with L<Catalyst> v5.90080 unicode and encoding has been
baked into core, and the default encoding is UTF-8.  The following advice
is for older versions of L<Catalyst>.

Be sure to set C<< ENCODING => 'utf-8' >> and use
L<Catalyst::Plugin::Unicode::Encoding> if you want to use non-ascii
characters (encoded as utf-8) in your templates.  This is only needed if
you actually have UTF8 literals in your templates and the BOM is not
properly set.  Setting encoding here does not magically encode your
template output.  If you are using this version of L<Catalyst> you need
to all the Unicode plugin, or upgrade (preferred)

=head2 Unicode (Catalyst v5.90080+)

This version of L<Catalyst> will automatically encode your body output
to UTF8. This means if your variables contain multibyte characters you don't
need top do anything else to get UTF8 output.  B<However> if your templates
contain UTF8 literals (like, multibyte characters actually in the template
text), then you do need to either set the BOM mark on the template file or
instruct TT to decode the templates at load time via the ENCODING configuration
setting.  Most of the time you can just do:

    MyApp::View::HTML->config(
        ENCODING => 'UTF-8');

and that will just take care of everything.  This configuration setting will
force L<Template> to decode all files correctly, so that when you hit
the finalize_encoding step we can properly encode the body as UTF8.  If you
fail to do this you will get double encoding issues in your output (but again,
only for the UTF8 literals in your actual template text.)

Again, this ENCODING configuration setting only instructs template toolkit
how (and if) to decode the contents of your template files when reading them from
disk.  It has no other effect.

=head2 RENDERING VIEWS

The view plugin renders the template specified in the C<template>
item in the stash.

    sub message : Global {
        my ( $self, $c ) = @_;
        $c->stash->{template} = 'message.tt2';
        $c->forward( $c->view('Web') );
    }

If a stash item isn't defined, then it instead uses the
stringification of the action dispatched to (as defined by $c->action)
in the above example, this would be C<message>, but because the default
is to append '.tt', it would load C<root/message.tt>.

The items defined in the stash are passed to the Template Toolkit for
use as template variables.

    sub default : Private {
        my ( $self, $c ) = @_;
        $c->stash->{template} = 'message.tt2';
        $c->stash->{message}  = 'Hello World!';
        $c->forward( $c->view('Web') );
    }

A number of other template variables are also added:

    c      A reference to the context object, $c
    base   The URL base, from $c->req->base()
    name   The application name, from $c->config->{ name }

These can be accessed from the template in the usual way:

<message.tt2>:

    The message is: [% message %]
    The base is [% base %]
    The name is [% name %]


The output generated by the template is stored in C<< $c->response->body >>.

=head2 CAPTURING TEMPLATE OUTPUT

If you wish to use the output of a template for some other purpose than
displaying in the response, e.g. for sending an email, this is possible using
other views, such as L<Catalyst::View::Email::Template>.

=head2 TEMPLATE PROFILING

See L</C<TIMER>> property of the L</config> method.

=head1 METHODS

=head2 new

The constructor for the TT view. Sets up the template provider,
and reads the application config.

=head2 process($c)

Renders the template specified in C<< $c->stash->{template} >> or
C<< $c->action >> (the private name of the matched action).  Calls
L<render|/render($c, $template, \%args)> to
perform actual rendering. Output is stored in C<< $c->response->body >>.

It is possible to forward to the process method of a TT view from inside
Catalyst like this:

    $c->forward('View::Web');

N.B. This is usually done automatically by L<Catalyst::Action::RenderView>.

=head2 render($c, $template, \%args)

Renders the given template and returns output. Throws a L<Template::Exception>
object upon error.

The template variables are set to C<%$args> if C<$args> is a hashref, or
C<< $c->stash >> otherwise. In either case the variables are augmented with
C<base> set to C<< $c->req->base >>, C<c> to C<$c>, and C<name> to
C<< $c->config->{name} >>. Alternately, the C<CATALYST_VAR> configuration item
can be defined to specify the name of a template variable through which the
context reference (C<$c>) can be accessed. In this case, the C<c>, C<base>, and
C<name> variables are omitted.

C<$template> can be anything that Template::process understands how to
process, including the name of a template file or a reference to a test string.
See L<Template::process|Template/process> for a full list of supported formats.

To use the render method outside of your Catalyst app, just pass a undef context.
This can be useful for tests, for instance.

It is possible to forward to the render method of a TT view from inside Catalyst
to render page fragments like this:

    my $fragment = $c->forward("View::Web", "render", $template_name, $c->stash->{fragment_data});

=head3 Backwards compatibility note

The render method used to just return the Template::Exception object, rather
than just throwing it. This is now deprecated and instead the render method
will throw an exception for new applications.

This behaviour can be activated (and is activated in the default skeleton
configuration) by using C<< render_die => 1 >>. If you rely on the legacy
behaviour then a warning will be issued.

To silence this warning, set C<< render_die => 0 >>, but it is recommended
you adjust your code so that it works with C<< render_die => 1 >>.

In a future release, C<< render_die => 1 >> will become the default if
unspecified.

=head2 template_vars

Returns a list of keys/values to be used as the catalyst variables in the
template.

=head2 config

This method allows your view subclass to pass additional settings to
the TT configuration hash, or to set the options as below:

=head2 paths

The list of paths TT will look for templates in.

=head2 expose_methods

The list of methods in your View class which should be made available to the templates.

For example:

  expose_methods => [qw/uri_for_css/],

  ...

  sub uri_for_css {
    my ($self, $c, $filename) = @_;

    # additional complexity like checking file exists here

    return $c->uri_for('/static/css/' . $filename);
  }

Then in the template:

  [% uri_for_css('home.css') %]

=head2 content_type

This lets you override the default content type for the response.  If you do
not set this and if you do not set the content type in your controllers, the
default is C<text/html; charset=utf-8>.

Use this if you are creating alternative view responses, such as text or JSON
and want a global setting.

Any content type set in your controllers before calling this view are respected
and have priority.

=head2 C<CATALYST_VAR>

Allows you to change the name of the Catalyst context object. If set, it will also
remove the base and name aliases, so you will have access them through <context>.

For example, if CATALYST_VAR has been set to "Catalyst", a template might
contain:

    The base is [% Catalyst.req.base %]
    The name is [% Catalyst.config.name %]

=head2 C<TIMER>

If you have configured Catalyst for debug output, and turned on the TIMER setting,
C<Catalyst::View::TT> will enable profiling of template processing
(using L<Template::Timer>). This will embed HTML comments in the
output from your templates, such as:

    <!-- TIMER START: process mainmenu/mainmenu.ttml -->
    <!-- TIMER START: include mainmenu/cssindex.tt -->
    <!-- TIMER START: process mainmenu/cssindex.tt -->
    <!-- TIMER END: process mainmenu/cssindex.tt (0.017279 seconds) -->
    <!-- TIMER END: include mainmenu/cssindex.tt (0.017401 seconds) -->

    ....

    <!-- TIMER END: process mainmenu/footer.tt (0.003016 seconds) -->


=head2 C<TEMPLATE_EXTENSION>

a suffix to add when looking for templates bases on the C<match> method in L<Catalyst::Request>.

For example:

  package MyApp::Controller::Test;
  sub test : Local { .. }

Would by default look for a template in <root>/test/test. If you set TEMPLATE_EXTENSION to '.tt', it will look for
<root>/test/test.tt.

=head2 C<PROVIDERS>

Allows you to specify the template providers that TT will use.

    MyApp->config(
        name     => 'MyApp',
        root     => MyApp->path_to('root'),
        'View::Web' => {
            PROVIDERS => [
                {
                    name    => 'DBI',
                    args    => {
                        DBI_DSN => 'dbi:DB2:books',
                        DBI_USER=> 'foo'
                    }
                }, {
                    name    => '_file_',
                    args    => {}
                }
            ]
        },
    );

The 'name' key should correspond to the class name of the provider you
want to use.  The _file_ name is a special case that represents the default
TT file-based provider.  By default the name is will be prefixed with
'Template::Provider::'.  You can fully qualify the name by using a unary
plus:

    name => '+MyApp::Provider::Foo'

You can also specify the 'copy_config' key as an arrayref, to copy those keys
from the general config, into the config for the provider:

    DEFAULT_ENCODING    => 'utf-8',
    PROVIDERS => [
        {
            name    => 'Encoding',
            copy_config => [qw(DEFAULT_ENCODING INCLUDE_PATH)]
        }
    ]

This can prove useful when you want to use the additional_template_paths hack
in your own provider, or if you need to use Template::Provider::Encoding

=head2 C<CLASS>

Allows you to specify a custom class to use as the template class instead of
L<Template>.

    package MyApp::View::Web;
    use Moose;
    extends 'Catalyst::View::TT';

    use Template::AutoFilter;

    __PACKAGE__->config({
        CLASS => 'Template::AutoFilter',
    });

This is useful if you want to use your own subclasses of L<Template>, so you
can, for example, prevent XSS by automatically filtering all output through
C<| html>.

=head2 HELPERS

The L<Catalyst::Helper::View::TT> and
L<Catalyst::Helper::View::TTSite> helper modules are provided to create
your view module.  There are invoked by the F<myapp_create.pl> script:

    $ script/myapp_create.pl view Web TT

    $ script/myapp_create.pl view Web TTSite

The L<Catalyst::Helper::View::TT> module creates a basic TT view
module.  The L<Catalyst::Helper::View::TTSite> module goes a little
further.  It also creates a default set of templates to get you
started.  It also configures the view module to locate the templates
automatically.

=head1 NOTES

If you are using the L<CGI> module inside your templates, you will
experience that the Catalyst server appears to hang while rendering
the web page. This is due to the debug mode of L<CGI> (which is
waiting for input in the terminal window). Turning off the
debug mode using the "-no_debug" option solves the
problem, eg.:

    [% USE CGI('-no_debug') %]

=head1 SEE ALSO

L<Catalyst>, L<Catalyst::Helper::View::TT>,
L<Catalyst::Helper::View::TTSite>, L<Template::Manual>

=head1 AUTHORS

Sebastian Riedel, C<sri@cpan.org>

Marcus Ramberg, C<mramberg@cpan.org>

Jesse Sheidlower, C<jester@panix.com>

Andy Wardley, C<abw@cpan.org>

Luke Saunders, C<luke.saunders@gmail.com>

=head1 COPYRIGHT

This program is free software. You can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
