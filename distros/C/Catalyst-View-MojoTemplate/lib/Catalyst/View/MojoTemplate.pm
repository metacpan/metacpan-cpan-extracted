package Catalyst::View::MojoTemplate;

use Moo;
use Mojo::Template;
use Mojo::ByteStream qw(b);

extends 'Catalyst::View';

our $VERSION = 0.004;

has app => (is=>'ro');
has auto_escape => (is=>'ro', required=>1, default=>1);
has append => (is=>'ro', required=>1, default=>'');
has prepend => (is=>'ro', required=>1, default=>'');
has capture_end => (is=>'ro', required=>1, default=>sub {'end'});
has capture_start => (is=>'ro', required=>1, default=>sub {'begin'});
has comment_mark => (is=>'ro', required=>1, default=>'#');
has encoding => (is=>'ro', required=>1, default=>'UTF-8');
has escape_mark => (is=>'ro', required=>1, default=>'=');
has expression_mark => (is=>'ro', required=>1, default=>'=');
has line_start => (is=>'ro', required=>1, default=>'%');
has replace_mark => (is=>'ro', required=>1, default=>'%');
has trim_mark => (is=>'ro', required=>1, default=>'%');
has tag_start=> (is=>'ro', required=>1, default=>'<%');
has tag_end => (is=>'ro', required=>1, default=>'%>');
has ['name', 'namespace'] => (is=>'rw');

has template_extension => (is=>'ro', required=>1, default=>sub { '.ep' });

has content_type => (is=>'ro', required=>1, default=>sub { 'text/html' });
has helpers => (is=>'ro', predicate=>'has_helpers');
has layout => (is=>'ro', predicate=>'has_layout');

sub build_mojo_template {
  my $self = shift;
  my $prepend = 'my $c = _C;' . $self->prepend;
  my %args = (
    auto_escape => $self->auto_escape,
    append => $self->append,
    capture_end => $self->capture_end,
    capture_start => $self->capture_start,
    comment_mark => $self->comment_mark,
    encoding => $self->encoding,
    escape_mark => $self->escape_mark,
    expression_mark => $self->expression_mark,
    line_start => $self->line_start,
    prepend => $prepend,
    trim_mark => $self->trim_mark,
    tag_start => $self->tag_start,
    tag_end => $self->tag_end,
    vars => 1,
  );

  return Mojo::Template->new(%args);
}


has path_base => (
  is=>'ro',
  required=>1,
  lazy=>1,
  builder=>'_build_path_base');
 
  sub _build_path_base {
    my $self = shift;
    my $root = $self->app->path_to('root');
    die "No directory '$root'" unless -e $root;

    return $root;
  }

sub COMPONENT {
  my ($class, $app, $args) = @_;
  $args = $class->merge_config_hashes($class->config, $args);
  $args->{app} = $app;

  return $class->new($app, $args);
}

sub ACCEPT_CONTEXT {
  my ($self, $c, @args) = @_;
  $c->stash->{'view.layout'} = $self->layout
    if $self->has_layout && !exists($c->stash->{'view.layout'});

  if(@args) {
    my %template_args = %{ pop(@args)||+{} };
    my $template = shift @args || $self->find_template($c);
    my %global_args = $self->template_vars($c);
    my $output = $self->render($c, $template, +{%global_args, %template_args});
    $self->set_response_from($c, $output);
    return $self;
  } else {
    return $self;
  }
}

sub set_response_from {
  my ($self, $c, $output) = @_;
  $c->response->content_type($self->content_type) unless $c->response->content_type;
  $c->response->body($output) unless $c->response->body;
}

sub process {
  my ($self, $c) = @_;
  my $template = $self->find_template($c); 
  my %template_args = $self->template_vars($c);
  my $output = $self->render($c, $template, \%template_args);
  $self->set_response_from($c, $output);

  return 1;
}

sub find_template {
  my ($self, $c) = @_;
  my $template = $c->stash->{template}
    ||  $c->action . $self->template_extension;

  unless (defined $template) {
    $c->log->debug('No template specified for rendering') if $c->debug;
    return 0;
  }

  return $template;
}

sub render {
  my ($self, $c, $template, $template_args) = @_;
  my $output = $self->render_template($c, $template, $template_args);

  if(ref $output) {
    # Its a Mojo::Exception;
    $c->response->content_type('text/plain');
    $c->response->body($output);
    return $output;
  }

  return $self->apply_layout($c, $output);
}

sub apply_layout {
  my ($self, $c, $output) = @_;
  if(my $layout = $self->find_layout($c)) {
    $c->log->debug(qq/Applying layout "$layout"/) if $c->debug;
    $c->stash->{'view.content'}->{main} = b $output;
    $output = $self->render($c, $layout, +{ $self->template_vars($c) });
  }
  return $output;
}

sub find_layout {
  my ($self, $c) = @_;
  return exists $c->stash->{'view.layout'} ? delete $c->stash->{'view.layout'} : undef;
}

sub render_template {
  my ($self, $c, $template, $template_args) = @_;
  $c->log->debug(qq/Rendering template "$template"/) if $c->debug;

  my $mojo_template = $self->{"__mojo_template_${template}"} ||= do {
    my $mojo_template = $self->build_mojo_template;
    $mojo_template->name($template);

    my $namespace_part = $template;
    $namespace_part =~s/\//::/g;
    $namespace_part =~s/\.ep$//;
    $mojo_template->namespace( ref($self) .'::Sandbox::'. $namespace_part);

    my $template_full_path = $self->path_base->file($template);
    my $template_contents = $template_full_path->slurp;
    $c->log->debug(qq/Found template at path "$template_full_path"/) if $c->debug;

    my $output = $mojo_template->parse($template_contents);
  };

  my $ns = $mojo_template->namespace;
  
  no strict 'refs';
  no warnings 'redefine';
  local *{"${ns}::_C"} = sub { $c };

  unless($self->{"__mojo_helper_${ns}"}) {
    $self->inject_helpers($c, $ns);
    $self->{"__mojo_helper_${ns}"}++;
  }

  return my $output = $mojo_template->process($template_args);
}

sub inject_helpers {
  my ($self, $c, $namespace) = @_;
  my %helpers = $self->get_helpers;
  foreach my $helper(keys %helpers) {
    eval qq[
      package $namespace;
      sub $helper { \$self->get_helpers('$helper')->(\$self, _C, \@_) }
    ]; die $@ if $@;
  }
}

sub template_vars {
  my ($self, $c) = @_;
  my %template_args = (
    base => $c->req->base,
    name => $c->config->{name} || '',
    self => $self,
    %{$c->stash||+{}},
  );

  return %template_args;
}

sub default_helpers {
  my $self = shift;
  return (
    layout => sub {
      my ($self, $c, $template, %args) = @_;
      $c->stash('view.layout' => $template);
      $c->stash(%args) if %args;
    },
    wrapper => sub {
      my ($self, $c, $template, @args) = @_;
      $c->stash->{'view.content'}->{main} = pop @args;
      my %args = @args;
      my %global_args = $self->template_vars($c);
      return b($self->render_template($c, $template, +{ %global_args, %args }));
    },
    include => sub {
      my ($self, $c, $template, %args) = @_;
      my %global_args = $self->template_vars($c);
      return b($self->render_template($c, $template, +{ %global_args, %args }));
    },
    content => sub {
      my ($self, $c, $name, $proto) = @_;

      $name ||= 'main';
      $c->stash->{'view.content'}->{$name} = _block($proto) if $proto && !exists($c->stash->{'view.content'}->{$name});

      my $value = $c->stash->{'view.content'}->{$name};
      $value = '' unless defined($value);

      return b $value;
    },
    content_with => sub {
      my ($self, $c, $name, $proto) = @_;

      $name ||= 'main';
      $c->stash->{'view.content'}->{$name} = _block($proto) if $proto;

      my $value = $c->stash->{'view.content'}->{$name};
      $value = '' unless defined($value);

      return b $value;
    },
    content_for => sub {
      my ($self, $c, $name, $proto) = @_;

      $name ||= 'main';
      $c->stash->{'view.content'}->{$name} .= _block($proto) if $proto;

      my $value = $c->stash->{'view.content'}->{$name};
      $value = '' unless defined($value);

      return b $value;
    },
    stash => sub {
      my ($self, $c, $name, $proto) = @_;

      $c->stash->{$name} = _$proto if $proto;

      my $value = $c->stash->{$name};
      $value = '' unless defined($value);

      return b $value;
    },

  );
}

sub _block { ref $_[0] eq 'CODE' ? $_[0]() : $_[0] }

sub get_helpers {
  my ($self, $helper) = @_;
  my %helpers = ($self->default_helpers, %{ $self->helpers || +{} });

  return $helpers{$helper} if defined $helper;
  return %helpers;
}

1;

=head1 NAME

Catalyst::View::MojoTemplate - Use Mojolicious Templates for your Catalyst View

=head1 SYNOPSIS

    package Example::View::HTML;

    use Moose;
    extends 'Catalyst::View::MojoTemplate';

    __PACKAGE__->config(helpers => +{
      now => sub {
        my ($self, $c, @args) = @_;
        return localtime;
      },
    });

    __PACKAGE__->meta->make_immutable;

Then called from a controller:

    package Example::Controller::Root;

    use Moose;
    use MooseX::MethodAttributes;

    extends 'Catalyst::Controller';

    sub root :Chained(/) PathPart('') CaptureArgs(0) { } 

      sub home :Chained(root) PathPart('') Args(0) {
        my ($self, $c) = @_;
        $c->stash(status => $c->model('Status'));
      }

      sub profile :Chained(root) PathPart(profile) Args(0) {
        my ($self, $c) = @_;
        $c->view('HTML' => 'profile.ep', +{ 
          me => $c->user,
        });
      }

    sub end : ActionClass('RenderView') {}

    __PACKAGE__->config(namespace=>'');
    __PACKAGE__->meta->make_immutable;

=head1 DESCRIPTION

Use L<Mojo::Template> as your L<Catalyst> view.  While ths might strike some as
odd, if you are using both L<Catalyst> and L<Mojolicious> you might like the option to
share the template code and expertise.  You might also just want to use a Perlish
template system rather than a dedicated mini language (such as L<Xslate>) since you
already know Perl and don't have the time or desire to become an expert in another
system.

This works just like many other L<Catalyst> views.  It will load and render a template
based on either the current action private name or a stash variable called C<template>.
It will use the stash to populate variables in the template.  It also offers an alternative
interface that lets you set a template in the actual call to the view, and pass variables.

By default we look for templates in C<$APPHOME/root> which is the standard default location
for L<Catalyst> templates.

Also like a lot of other template systems you can define helper methods which are injected
into your template and can take parameters (including text blocks).

The intention here is to try and make this as similar to how L<Mojo::Template> is used
in L<Mojolicious> so that people that need to work in both frameworks could in theory use
this view in L<Catalyst> and be able to switch between the two with less trouble (at least
for doing view development).  To that end we've added some default helpers that hopefully
work the same way as they do in L<Mojolicious>.  These are helpers for template layouts
and includes as well as for sharing data between them.  We've also added a 'wrapper'
helper because the author has found that feature of Template::Toolkit (L<Template>) to be so
useful he would have a hard time living without it.  We did not include the L<Mojolicious>
tag helpers but there's no reason those could not be added as an add on role at a later
date should people take an interest in this thing.

There's an example of sorts in the C<example> directory of the module distribution.  You can
start the example server with the following command:

     perl -Ilib -I example/lib/ example/lib/Example/Server.pm

B<NOTE> Warning, this is an early access module and I reserve the right to make breaking
changes if it turns out I totally confused how L<Mojolicious> works.  There's actually
not a ton of code here since its just a thin wrapper over L<Mojo::Template> so you should
be confortable looking that over and coping if there's issues.

=head1 CONFIGURATION

This view defines the following configuration attributes.  For the most part these
are just pass thru to the underlying L<Mojo::Template>.  You would do well to review
those docs if you are not familiar.

=head2 auto_escape

=head2 append

=head2 prepend

=head2 capture_start

=head2 capture_end

=head2 encoding

=head2 comment_mark

=head2 escape_mark

=head2 expression_mark

=head2 line_start

=head2 replace_mark

These are just pass thru to L<Mojo::Template>.  See that for details

=head2 content_type

The HTTP content-type that is set in the response unless it is already set.

=head2 helpers

A hashref of helper functions.  For example:

    __PACKAGE__->config(helpers=>+{
      now => sub {
        my ($self, $c, @args) = @_;
        return localtime;
      },
    );

All arguments are passed from the template.  If you are building a block
helper then the last argument will be a coderef to the enclosed block.  You
may wish to view the source code around the default helpers for more examples of
this.

=head2 layout

Set a default layout which will be used if none are defined.  Optional.

=head1 HELPERS

The following is a list of the default helpers.

=head2 layout

    % layout "layout.ep", title => "Hello";
    <h1>The Awesome new Content</h1>
    <p>You are doomed to discover you can never recover from the narcoleptic
    country in which you once stood, where the fires alway burning but there's
    never enough wood</p>

C<layout> sets a global template wrapper around your content.  Arguments passed
get merged into the stash and are available to the layout.  The output of your
template is placed into the 'main' content block.  See L<Mojolicious::Plugin::DefaultHelpers/layout>
for more.

=head2 include

See L<Mojolicious::Plugin::DefaultHelpers/include>

=head2 content

See L<Mojolicious::Plugin::DefaultHelpers/content>

=head2 wrapper

Similar to the C<layout> helper, the C<wrapper> helper wraps the contained content
inside a another template.  However unlike C<layout> you can have more than one
C<wrapper> in your template.  Example:

    %= wrapper "wrapper.ep", header => "The Story Begins...", begin
      <p>
        The story begins like many others; something interesting happend to someone
        while sone other sort of interesting thing was happening all over.  And then
        there wre monkeys.  Monkeys are great, you ever get stuck writing a story I
        really recommend adding monkeys since they help the more boring story.
      </p>
    %end

This works similar to the WRAPPER directive in Template::Toolkit, if you are familiar
with that system.

=head1 AUTHOR
 
    jnap - John Napiorkowski (cpan:JJNAPIORK)  L<email:jjnapiork@cpan.org>
    With tremendous thanks to SRI and the Mojolicious team!

=head1 SEE ALSO
 
L<Catalyst>, L<Catalyst::View>, L<Mojolicious>
    
=head1 COPYRIGHT & LICENSE
 
Copyright 2020, John Napiorkowski L<email:jjnapiork@cpan.org>
 
This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
