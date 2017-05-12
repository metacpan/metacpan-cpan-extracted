package Catalyst::View::TD;

use strict;
use warnings;
use base qw/Catalyst::View/;
use Template::Declare::Catalyst;
use MRO::Compat;

our $VERSION = '0.12';

__PACKAGE__->mk_accessors('init');
__PACKAGE__->mk_accessors('dispatch_to');
__PACKAGE__->mk_accessors('auto_alias');

=head1 Name

Catalyst::View::TD - Catalyst Template::Declare View Class

=head1 Synopsis

Use the helper to create your view:

    ./script/myapp_create.pl view HTML TD

Create a template by editing F<lib/MyApp/Templates/HTML.pm>:

    template hello => sub {
        my ($self, $vars) = @_;
        html {
            head { title { "Hello, $vars->{user}" } };
            body { h1    { "Hello, $vars->{user}" } };
        };
    };

Render the view from MyApp::Controller::SomeController:

    sub message : Global {
        my ( $self, $c ) = @_;
        $c->stash->{template} = 'hello';
        $c->stash->{user}     = 'Slim Shady';
        $c->forward( $c->view('HTML') );
    }

=cut

sub new {
    my ( $class, $c, $args ) = @_;
    my $config = {
        strict => 1,
        %{ $class->config },
        %{ $args },
    };

    my $auto_alias = exists $config->{auto_alias} ? delete $config->{auto_alias} : 1;

    if (my $roots = $config->{dispatch_to}) {
        for my $root (@{ $roots }) {
            eval "require $root" or die $@ || "$root did not return a true value";
        }
    } else {
        $config->{dispatch_to} = _load_templates( $class, $auto_alias );
    }

    my $self = $class->next::method( $c, { init => $config } );

    # Set base template casses. Local'd in render if needed
    $self->dispatch_to( delete $config->{dispatch_to} );

    # Set other attributes.
    $self->auto_alias( $auto_alias );
    return $self;
}

sub _load_templates {
    my ($class, $auto_alias)  = @_;

    (my $root = $class) =~ s/::View::/::Templates::/;

    my @classes = $auto_alias ? Module::Pluggable::Object->new(
        require     => 0,
        search_path => $root,
    )->plugins : ();

    for my $mod ($root, @classes) {
        next unless $mod;
        # Load it.
        eval "require $mod" or die $@ || "$mod did not return a true value";

        # Make the module a subclass of TD (required by TD)
        unless ( $mod->isa('Template::Declare::Catalyst') ) {
            no strict 'refs';
            push @{ "$mod\::ISA" }, 'Template::Declare::Catalyst'
        }

        next if $mod eq $root;

        # Mix it in.
        (my $sub = $mod) =~ s/\Q$root\E:://;
        $mod->alias($root, join '/', map { lc } split /::/ => $sub);
    }
    return [$root];
}

sub process {
    my ( $self, $c ) = @_;

    my $template = $c->stash->{template} || $c->action;

    unless (defined $template) {
        $c->log->debug('No template specified for rendering') if $c->debug;
        return 0;
    }

    my $output = eval { $self->render($c, $template) };

    if (my $error = $@) {
        my $error = qq/Couldn't render template: "$error"/;
        $c->log->error($error);
        $c->error($error);
        return 0;
    }

    unless ( $c->response->content_type ) {
        $c->response->content_type('text/html; charset=utf-8');
    }

    $c->response->body($output);

    return 1;
}

sub render {
    my ($self, $c, $template, $args) = @_;

    $c->log->debug(qq/Rendering template "$template"/) if $c && $c->debug;

    # The do prevents warnings when $args is undef.
    my $vars = { do {
        if (ref $args) {
            %{ $args }
        } elsif ($c) {
            %{ $c->stash }
        } else {
            ()
        }
    } };

    my $init = $self->init;

    local $self->{dispatch_to} = [
        @{ $vars->{prepend_template_classes} },
        @{ $self->{dispatch_to} },
    ] if ref $vars->{prepend_template_classes};

    local $self->{dispatch_to} = [
        @{ $self->{dispatch_to} },
        @{ $vars->{append_template_classes} },
    ] if ref $vars->{append_template_classes};

    Template::Declare->init( %{ $init }, dispatch_to => $self->dispatch_to );
    Template::Declare::Catalyst->context($c);
    return Template::Declare->show($template, $vars);
}

1;
__END__

=head1 Description

This is the Catalyst view class for L<Template::Declare|Template::Declare>.
Your application should define a view class that subclasses this module. The
easiest way to achieve this is using the F<myapp_create.pl> script (where
F<myapp> should be replaced with whatever your application is called). This
script is created as part of the Catalyst setup.

    ./script/myapp_create.pl view HTML TD

This creates a C<MyApp::View::HTML> module in the F<lib> directory (again,
replacing C<MyApp> with the name of your application) that looks something
like this:

    package MyApp::View::HTML;

    use strict;
    use warnings;
    use parent 'Catalyst::View::TD';

    __PACKAGE__->config(
        # dispatch_to     => [qw(MyApp::Templates::HTML)],
        # auto_alias      => 1,
        # strict          => 1,
        # postprocessor   => sub { ... },
        # around_template => sub { ... },
    );

It also creates a C<MyApp::Templates::HTML> template class that looks
something like this:

    package MyApp::Templates::HTML;

    use strict;
    use warnings;
    use parent 'Template::Declare::Catalyst';
    use Template::Declare::Tags;

    # template hello => sub {
    #     my ($self, $vars) = @_;
    #     html {
    #         head { title { "Hello, $vars->{user}" } };
    #         body { h1    { "Hello, $vars->{user}" } };
    #     };
    # };

Now you can modify your action handlers in the main application and/or
controllers to forward to your view class. You might choose to do this in the
C<end()> method, for example, to automatically forward all actions to the TD
view class.

    # In MyApp::Controller::SomeController
    sub end : Private {
        my( $self, $c ) = @_;
        $c->forward( $c->view('HTML') );
    }

=head2 Configuration

There are a three different ways to configure your view class (see
L<config|/config> for an explanation of the configuration options). The first
way is to call the C<config()> method in the view subclass. This happens when
the module is first loaded.

    package MyApp::View::HTML;

    use strict;
    use parent 'Catalyst::View::TD';

    __PACKAGE__->config({
        dispatch_to     => [ 'MyApp::Templates::HTML' ],
        auto_alias      => 1,
        strict          => 1,
        postprocessor   => sub { ... },
        around_template => sub { ... },
    });

The second way is to define a C<new()> method in your view subclass. This
performs the configuration when the view object is created, shortly after
being loaded. Remember to delegate to the base class C<new()> method (via
C<< $self->next::method() >> in the example below) after performing any
configuration.

    sub new {
        my $self = shift;
        $self->config({
            dispatch_to     => [ 'MyApp::Templates::HTML' ],
            auto_alias      => 1,
            strict          => 1,
            postprocessor   => sub { ... },
            around_template => sub { ... },
        });
        return $self->next::method(@_);
    }

The final, and perhaps most direct way, is to call the ubiquitous C<config()>
method in your main application configuration. The items in the class hash are
added to those already defined by the above two methods. This happens in the
base class C<new()> method (which is one reason why you must remember to call
it via C<MRO::Compat> if you redefine the C<new()> method in a subclass).

    package MyApp;

    use strict;
    use Catalyst;

    MyApp->config({
        name     => 'MyApp',
        'View::HTML' => {
            dispatch_to     => [ 'MyApp::Templates::HTML' ],
            auto_alias      => 1,
            strict          => 1,
            postprocessor   => sub { ... },
            around_template => sub { ... },
        },
    });

Note that any configuration defined by one of the earlier methods will be
overwritten by items of the same name provided by the later methods.

=head2 Auto-Aliasing

In addition to the dispatch template class (as defined in the C<dispatch_to>
configuration, or defaulting to C<MyApp::Templates::ViewName>), you can write
templates in other classes and they will automatically be aliased into the
dispatch class. The aliasing of templates is similar to how controller actions
map to URLs.

For example, say that you have a dispatch template class for your
C<MyApp::View::XHTML> view named C<MyApp::Templates::XHTML>:

    package TestApp::Templates::XHTML;
    use parent 'Template::Declare::Catalyst';
    use Template::Declare::Tags;

    template home => sub {
        html {
            head { title { 'Welcome home' } };
            body { h1    { 'Welcome home' } };
        };
    };

This will handle a call to render the C</home> (or just C<home>):

        $c->stash->{template} = 'home';
        $c->forward( $c->view('XHTML') );

But let's say that you have a controller, C<MyApp::Controller::Users>, that
has an action named C<list>. Ideally what you'd like to do is to have it
dispatch to a view named C</users/list>. And sure enough, you can define one
right in the dispatch class if you like:

    template 'users/list' => sub {
        my ($self, $args) = @_;
        ul {
            li { $_ } for @{ $args->{users} };
        };
    };

But it can get to be a nightmare to manage I<all> of your templates in this
one class. A better idea is to define them in multiple template classes just
as you have actions in multiple controllers. The C<auto_alias> feature of
Catalyst::View::TD does just that. Rather than define a template named
C<users/list> in the dispatch class (C<MyApp::Templates::XHTML>), create a new
template class, C<MyApp::Templates::XHTML::Users>:

    ./script/myapp_create.pl TDClass XHTML::Users

Then create a C<list> template there:

    package TestApp::Templates::XHTML::Users;
    use parent 'Template::Declare::Catalyst';
    use Template::Declare::Tags;

    template list => sub {
        my ($self, $args) = @_;
        ul { li { $_ } for @{ $args->{users} } };
    };

Catalyst::View::TD will automatically import the templates found in all
classes defined below the dispatch class. Thus this template will be imported
as C<users/list>. The nice thing about this is it allows you to create
template classes with templates that correspond directly to controller classes
and their actions.

You can also use this approach to create utility templates. For example,
if you wanted to put the header and footer output into utility templates,
you could put them into a utility class:

    package TestApp::Templates::XHTML::Util;
    use parent 'Template::Declare::Catalyst';
    use Template::Declare::Tags;

    template header => sub {
        my ($self, $args) = @_;
        head { title {  $args->{title} } };
    };

    template footer => sub {
        div {
            id is 'fineprint';
            p { 'Site contents licensed under a Creative Commons License.' }
        };
    };

And then you can simply use these templates from the dispatch class or any
other aliased template class, including the dispatch class:

    package TestApp::Templates::XHTML;
    use parent 'Template::Declare::Catalyst';
    use Template::Declare::Tags;

    template home => sub {
        html {
            show '/util/header';
            body {
                h1 { 'Welcome home' };
                show '/util/footer';
            };
        };
    };

And the users class:

    package TestApp::Templates::XHTML::Users;
    use parent 'Template::Declare::Catalyst';
    use Template::Declare::Tags;

    template list => sub {
        my ($self, $args) = @_;
        html {
            show '/util/header';
            body {
                ul { li { $_ } for @{ $args->{users} } };
                show '/util/footer';
            };
        };
    };

If you'd rather control the importing of templates yourself, you can always
set C<auto_alias> to a false value. Then you'd just need to explicitly inherit
from C<Template::Declare::Catayst> and do the mixing yourself. The equivalent
to the auto-aliasing in the above examples would be:

    package TestApp::Templates::XHTML;
    use parent 'Template::Declare::Catalyst';
    use Template::Declare::Tags;

    use TestApp::Templates::XHTML::Users;
    use TestApp::Templates::XHTML::Util;

    alias TestApp::Templates::XHTML::Users under '/users';
    alias TestApp::Templates::XHTML::Util under '/util';

This would be the way to go if you wanted finer control over
Template::Declare's L<composition features|Template::Declare/"Template Composition">.

=head2 Dynamic C<dispatch_to>

Sometimes it is desirable to modify C<dispatch_to> for your templates at
runtime. Additional paths can be prepended or appended C<dispatch_to> via the
stash as follows:

    $c->stash->{prepend_template_classes} = [ 'MyApp::Other::Templates' ];
    $c->stash->{append_template_classes}  = [ 'MyApp::Fallback::Templates' ];

If you need to munge the list of dispatch classes in more complex ways, there
is also a C<dispatch_to()> accessor:

    my $view = $c->view('HTML')
    splice @{ $view->dispatch_to }, 1, 0, 'My::Templates'
        unless grep { $_ eq 'My::Templates' } $view->dispatch_to;

Note that if you use C<dispatch_to()> to change template classes, they are
I<permanently> changed. You therefore B<must> check for duplicate paths if you
do this on a per-request basis, as in this example. Otherwise, the class will
continue to be added on every request, which would be a rather ugly memory
leak.

A safer approach is to use C<dispatch_to()> to overwrite the array of template
classes rather than adding to it. This eliminates both the need to perform
duplicate checking and the chance of a memory leak:

    $c->view('HTML')->dispatch_to( ['My::Templates', 'Your::Templates'] );

This is safe to do on a per-request basis. But you're really better off using
the stash approach. I suggest sticking to that when you can.

If you are calling C<render> directly, then you can specify extra template
classes under the C<prepend_template_classes> and C<append_template_classes>
keys. See L</"Capturing Template Output"> for an example.

=head2 Rendering Views

The Catalyst C<view()> method renders the template specified in the C<template>
item in the stash.

    sub message : Global {
        my ( $self, $c ) = @_;
        $c->stash->{template} = 'message';
        $c->forward( $c->view('HTML') );
    }

If a stash item isn't defined, then it instead uses the stringification of the
action dispatched to (as defined by C<< $c->action >>). In the above example,
this would be C<message>.

The items defined in the stash are passed to the the Template::Declare template
as a hash reference. Thus, for this controller action:

    sub default : Private {
        my ( $self, $c ) = @_;
        $c->stash->{template} = 'message';
        $c->stash->{message}  = 'Hello World!';
        $c->forward( $c->view('TD') );
    }

Your template can use access the C<message> key like so:

    template message => sub {
        my ($self, $args) = @_;
        h1 { $args->{message} };
    };

Template classes are automatically subclasses of Template::Declare::Catalyst,
which is itself a subclass of L<Template::Declare|Template::Declare>.
L<Template::Declare::Catalyst|Template::Declare::Catalyst> provides a few
extra accessors for use in your templates (though note that they will return
C<undef> if you call C<render()> without a context object):

=over

=item C<context>

A reference to the context object, C<$c>

=item C<c>

An alias for C<context()>

=back

These can be accessed from the template like so:

    template message => sub {
        my ($self, $args) = @_;
        p { "The message is $args->{message}" };
        p { "The base is " . $self->context->req->base };
        p { "The name is " . $self->c->config->{name} };
    };

The output generated by the template is stored in C<< $c->response->body >>.

=head2 Capturing Template Output

If you wish to use the output of a template for some purpose other than
displaying in the response, e.g. for sending an email, use
L<Catalyst::Plugin::Email|Catalyst::Plugin::Email> and the L<render> method:

    sub send_email : Local {
        my ($self, $c) = @_;

        $c->email(
            header => [
                To      => 'me@localhost',
                Subject => 'A TD Email',
            ],
            body => $c->view('TD')->render($c, 'email', {
                prepend_template_classes => [ 'My::EmailTemplates' ],
                email_tmpl_param1        => 'foo'
            }),
        );
        # Redirect or display a message
    }

=head2 Template Class Helper

In addition to the usual helper for creating TD views, you can also use the
C<TDClass> helper to create new template classes:

    ./script/myapp_create.pl TDClass HTML::Users

This will create a new Template::Declare template class,
C<MyApp::Templates::HTML::Users> in the F<lib> directory. This is perhaps best used
in conjunction with creating a new controller for which you expect to create
views:

    ./script/myapp_create.pl controller Users
    ./script/myapp_create.pl TDClass HTML::Users

As explained in L</"Auto-Aliasing">, if you already have the TD view
C<MyApp::View::HTML>, the templates in the C<MyApp::Templates::HTML::Users> class
will be aliased under the C</users> path. So if you defined a C<list> action
in the C<Users> controller and a corresponding C<list> view in the
C<HTML::Users> view, both would resolve to C</users/list>.

=head1 Methods

=head2 Constructor

=head3 C<new>

    my $view = MyApp::View::HTML->new( $c, $args );

The constructor for the TD view. Sets up the template provider and reads the
application config. The C<$args> hash reference, if present, overrides the
application config.

=head2 Class Methods

=head3 C<config>

    __PACKAGE__->config(
        dispatch_to     => [qw(MyApp::Templates::HTML)],
        auto_alias      => 1,
        strict          => 1,
        postprocessor   => sub { ... },
        around_template => sub { ... },
    );

Sets up the configuration your view subclass. All the settings are the same as
for Template::Declare's L<C<init()>|Template::Declare/init> method except:

=over

=item auto_alias

Additional option. Determines whether or not classes found under the dispatch
template's namespace are automatically aliased as described in
L</"Auto-Aliasing">.

=item strict

Set to true by default so that exceptional conditions are appropriately fatal
(it's false by default in Template::Declare).

=back

=head2 Instance Methods

=head3 C<process>

  $view->process($c);

Renders the template specified in C<< $c->stash->{template} >> or
C<< $c->action >> (the private name of the matched action). Calls L<render()>
to perform actual rendering. Output is stored in C<< $c->response->body >>.

=head3 C<render>

  my $output = $view->render( $c, $template_name, $args );

Renders the given template and returns output. Dies on error.

If C<$args> is a hash reference, it will be passed to the template. Otherwise,
C<< $c->stash >> will be passed if C<$c> is defined.

=head1 SEE ALSO

L<Catalyst>, L<Catalyst::View::TT>, L<Catalyst::Helper::View::TD>,
L<Catalyst::Helper::TDClass>, L<Template::Manual>,
L<http://justatheory.com/computers/programming/perl/catalyst/>

=head1 Author

David E. Wheeler <david@justatheory.com>

=head1 Copyright

This program is free software. You can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
