package Catalyst::View::Templated;
use strict;
use warnings;
use Class::C3;

use base qw/Catalyst::Component::ACCEPT_CONTEXT Catalyst::View/;

our $VERSION = '0.02'; # beta!

=head1 NAME

Catalyst::View::Templated - generic base class for template-based views

=head1 SYNOPSIS

View::Templated makes all (template-based) Catalyst views work the same way:

   # setup the config
   MyApp->config->{View::SomeEngine} 
     = { TEMPLATE_EXTENSION => '.tmpl',
         CATALYST_VAR       => 'c',
         INCLUDE_PATH       => ['root', 'root/my_theme'], # defaults to root
         CONTENT_TYPE       => 'application/xhtml+xml', # defaults to text/html
       };
 
   # set the template in your action
   $c->view('View::SomeEngine')->template('the_template_name');
   # or let it guess the template name from the action name and EXTENSION

   # capture the text of the template
   my $output = $c->view('View::SomeEngine')->render;

   # process a template (in an end action)
   $c->detach('View::Name');
   $c->view('View::Name')->process;

=head1 METHODS

=head2 new($c, $args)

Called by Catalyst when creating the component.

=cut

sub new {
    my $self = shift;
    my ($c, $args) = @_;
    
    $args->{CONTENT_TYPE} ||= 'text/html';
    
    # default INCLUDE_PATH
    if (!$args->{INCLUDE_PATH}){
        $args->{INCLUDE_PATH} = [$c->path_to('root')];
    }
    
    # fixup INCLUDE_PATH if the user passes a scalar
    if (ref $args->{INCLUDE_PATH} ne 'ARRAY') {
        $args->{INCLUDE_PATH} = [$args->{INCLUDE_PATH}];
    }

    $args->{CATALYST_VAR} ||= 'c';
    
    return $self->next::method($c, $args);
}

=head2 template([$template])

Set the template to C<$template>, or return the current template
is C<$template> is undefined.

=cut

sub template {
    my ($self, $template) = @_;
    
    if ($template) {
        # store in _<self>_template
        $self->context->stash($self->_ident() => $template);
        return $template;
    }

    # hopefully they're using the new $c->view->template
    $template = $self->context->stash->{$self->_ident()};
    
    # if that's empty, get the template the old way, $c->stash->{template}
    $template ||= $self->context->stash->{template};
    
    # if those aren't set, try $c->action and the TEMPLATE_EXTENSION
    $template ||= $self->context->action . ($self->{TEMPLATE_EXTENSION}||q{});
    
    return $template;
}

sub _ident { # secret stash key for this template'
    return '__'. ref($_[0]). '_template';
}

=head2 process

Called by Catalyst to render a template.  Renders the template
returned by C<< $self->template >> and sets the response body to the
result of the template evaluation.

Also sets up a content-type header for text/html with the charset of
the data (utf8 if the data contains utf8 characters, iso-8859-1
otherwise).

=cut

sub process {
    my $self = shift;
    # c is also passed, but we don't care anymore

    my $template = $self->template;
    $self->context->log->debug(qq/Processing template "$template"/) 
      if $self->context->debug;
    my $output = $self->_do_render($template);
    
    unless ( $self->context->response->content_type ) {
        my $ct      = $self->{CONTENT_TYPE};
        my $charset = 'iso-8859-1';
        $charset = 'utf-8' if utf8::is_utf8($output);
        
        $self->context->response->content_type("$ct; charset=$charset");
    }
    
    $self->context->response->body($output);
    
    return 1; # backcompat, ick
}

=head2 render([[$c], [$template, [$args]]])

Renders the named template and returns the output.  If C<$template>
is omitted, it is determined by calling C<< $self->template >>.

You can also omit C<$c>.  If the first arg is a reference, it 
will be treated as C<$c>.  If it's not, then it will be treated
as the name of the template to render.  

If you only want to supply C<$args>, pass C<undef> as the first
argument, before C<$args>.

Supplying no arguments at all is also legal.

Old style:

   $c->view('TT')->render($c, 'template', { args => 'here' });

New style:

   $c->view('TT')->render('template', { args => 'here' });
   $c->view('TT')->render('template'); # no args

   $c->view('TT')->template('template');
   $c->view('TT')->render(undef, { args => 'here' });
   $c->view('TT')->render; # no args

=cut

sub render {
    my $self = shift;

    my ($c, $template, $args);
    if (ref $_[0]) {
        ($c, $template, $args) = @_;
    }
    else {
        ($template, $args) = @_;
    }

    $self->context->log->debug(qq/Rendering template "$template"/) 
      if $self->context->debug;
    
    return $self->_do_render($template, $args);
}

sub _do_render {
    my $self     = shift;
    my $template = shift || $self->template;
    my $args     = shift;
    
    my $stash    = {%{$self->context->stash}};
    my $catalyst = $self->{CATALYST_VAR};
    
    $stash->{$catalyst} = $self->context;
    $stash->{base} ||= $self->context->request->base;
    $stash->{name} ||= $self->context->config->{name};
    
    my $output = eval {
        $self->_render($template, $stash, $args);
    };
    
    if ($@) {
        my $error = "Couldn't render template '$template': $@";
        $self->context->error($error);
    }

    return $output;
}

=head1 IMPLEMENTING A SUBCLASS

All you need to do is implement a new method (for setup) and a
C<_render> method that accepts a template name, a hashref of
paramaters, and a hashref of arguments (optional, passed to C<render>
by the user), and returns the rendered template.  This class will
handle converting the stash to a hashref for you, so you don't need to
worry about munging it to get the context, base, or name.  Just render
with what you're given.  It's what the user wants.

Example:

   package Catalyst::View::MyTemplate;
   use base 'Catalyst::View::Templated';

   sub new {
      my ($class, $c, $args) = @_;
      my $self = $class->next::method($c, $args);
  
      $self->{engine} = MyTemplate->new(include => $self->{INCLUDE_PATH});
      return $self;
   }

   sub _render {
      my ($self, $template, $stash, $args) = @_;
      my $engine = $self->{engine};
  
      return $engine->render_template($template, $stash, $args);
   }

Now your View will work exactly like every other Catalyst View.  All
you have to worry about is sending a hashref into a template and
returning the result.  Easy!

=over 4

=item 

We're using L<Class::C3|Class::C3> instead of L<NEXT|NEXT>.
Don't use NEXT anymore.

=item

Returning false from C<_render> is not an error.  If something bad
happens, throw an exception.  The error will automatically be handled
appropriately; all you need to do is die with an informative message.

The message shown to the user is:

   Couldn't render template '$template': $@

C<$@> is whatever you invoked C<die> against.

=back 

=head2 VARIABLES FOR YOU

=over 4

=item $self->{INCLUDE_PATH}

An array ref containing the user's desired include paths.  This is set
to a reasonable default (C<root/>) if the user omits it from his
config.

=back

=head1 AUTHOR

Jonathan Rockway C<< jrockway AT cpan.org >>.

=head1 LICENSE

Copyright (c) 2007 Jonathan Rockway.  You may distribute this module
under the same terms as Perl itself.

=cut

1;
