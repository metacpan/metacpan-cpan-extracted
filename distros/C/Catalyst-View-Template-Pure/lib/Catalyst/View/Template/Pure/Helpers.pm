use strict;
use warnings;

package Catalyst::View::Template::Pure::Helpers;

use Exporter 'import';
use Template::Pure::DataProxy;

our @EXPORT_OK = (qw/Uri Apply Wrap/);
our %EXPORT_TAGS = (All => \@EXPORT_OK, ALL => \@EXPORT_OK);

sub Uri {
  my ($path, @args) = @_;
  die "$path is not a string" unless ref \$path eq 'SCALAR';

  # What type of path?  Controller.action_name or relative action/namespace
  my ($controller_proto, $action_proto) = ();
  if($path=~m/^(.*)\.(.+)$/) {
    ($controller_proto, $action_proto) = ($1,$2);
  } else {
    # probably namespace
    $action_proto = $path;
  }

  return sub {
    my ($pure, $dom, $data) = @_;
    my $c = $pure->{view}{ctx};
    my $controller;
    if($controller_proto) {
      die "$controller_proto is not a controller!" unless
        $controller = $c->controller($controller_proto);
    } else {
      # if not specified, use the current
      $controller = $c->controller;
    }

    my $action = '';
    if(my ($data_path) = ($action_proto=~m/^\=\{(.+)\}$/)) {
      $action = $pure->data_at_path($data,$data_path);
    }
    elsif($action_proto =~/\//) {
      # proto is a relative action namespace.
      my $path = $action_proto=~m/^\// ? $action_proto : $controller->action_for($action_proto)->private_path;
      die "$action_proto is not an action for controller ${\$controller->component_name}" unless $path;
      die "$path is not a private path"
        unless $action = $c->dispatcher->get_action_by_path($path);
    } else {
      die "$action_proto is not an action for controller ${\$controller->component_name}"
        unless $action = $controller->action_for($action_proto);
    }

    $data = Template::Pure::DataProxy->new(
      $data,
      captures => $c->request->captures || [],
      args => $c->request->args || [],
      query => $c->request->query_parameters|| +{});

    # We need to unroll the @args and fill in any template values.
    my $resolve = sub {
      my $arg = shift;
      if(my ($v) = ($arg=~m/^\=\{(.+)\}$/)) {
        return $pure->data_at_path($data,$v);
      } else {
        return $arg;
      }
    };

    # Change any placeholders.
    my @local_args = map {
      my $arg = $_;
      if(ref \$_ eq 'SCALAR') {
        $arg = $resolve->($arg);
      } elsif(ref $arg eq 'ARRAY') {
        $arg = [map { $resolve->($_) } @$arg];
      } elsif(ref $arg eq 'HASH') {
        $arg = +{map { my $val = $arg->{$_}; $resolve->($_) => $resolve->($val) } keys %$arg};
      }
      $arg;
    } @args;

    my $uri = $c->uri_for($action, @local_args);
    return $pure->encoded_string("$uri"); 
  };
}

sub Apply {
  my ($view_name, @args) = @_;
  return sub {
    my ($pure, $dom, $data) = @_;
    my $c = $pure->{view}{ctx};
    return $c->view($view_name, $data, template=>$dom, clear_stash=>1, @args);
  };
}

sub Wrap {
  my ($view_name, @args) = @_;
  return sub {
    my ($pure, $dom, $data) = @_;
    my $c = $pure->{view}{ctx};
    return $c->view($view_name, $data, content=>$dom, clear_stash=>1, @args);
  };
}

1;

=head1 NAME
 
Catalyst::View::Template::Pure::Helpers - Simplify some boilerplate

=head1 SYNOPSIS
 
    package  MyApp::View::Story;

    use Moose;
    use Catalyst::View::Template::Pure::Helpers (':ALL');
    extends 'Catalyst::View::Template::Pure';

    has [qw/title body capture arg q/] => (is=>'ro', required=>1);

    __PACKAGE__->config(
      returns_status => [200],
      template => q[
        <!doctype html>
        <html lang="en">
          <head>
            <title>Title Goes Here</title>
          </head>
          <body>
            <a name="hello">hello</a>
          </body>
        </html>      
      ],
      directives => [

        'a[name="hello"]@href' => Uri('Story.last',['={year}'], '={id}', {q=>'={q}',rows=>5}),
      ],
    );
 
=head1 DESCRIPTION

Generates code for some common tasks you need to do in your templates, such
as build URLs etc.

=head2 Uri

Used to generate a URL via $c->uri_for.  Takes signatures like:

    Uri("$controller.$action", \@captures, @args, \%query)
    Uri(".$action", \@captures, @args, \%query)
    Uri("$relative_action_private_name", \@captures, @args, \%query)
    Uri("$absolute_action_private_name", \@captures, @args, \%query)

We fill placeholders in the arguments in the same was as in templates, for example:

    Uri('Story.last',['={year}'], '={id}', {q=>'={q}',rows=>5})

Would fill year, id and q from the current data context.  We also merge in the following
keys to the current data context:

    captures => $c->request->captures,
    args => $c->request->args,
    query => $c->request->query_parameters;

To make it easier to fill data from the current request.  For example:

    Uri('last', ['={captures}'], '={args}')

You can also use data paths placeholders to indicate the action on which we are building
a URI:

    Uri('={delete_link}', ['={captures}'], '={args}')

In this case the placeholder should refer to a L<Catalyst::Action> object, not a string:

    $c->view('List', delete_link => $self->action_for('item/delete'));

This may change in a future version.

=over

=item Uri("$controller.$action", \@captures, @args, \%query)

URI for an action at a specific Controller.  '$controller' should be
a controller namespace part, for example 'MyApp::Controller::User' would
be 'User' and 'MyApp::Controller::User::Info' would be 'User::Info'.

=item Uri(".$action", \@captures, @args, \%query)

Relative version of the previous helper.  Set the controller to the
current controller.

=item Uri("$absolute_action_private_name", \@captures, @args, \%query)

Creates a URI for an absolute action namespace.  Examples:

    Uri('/root/user')

=item Uri("$relative_action_private_name", \@captures, @args, \%query)

Creates a URI for a relative (under the current controller namespace)
action namespace. Examples:

    Uri('user/info')

=back

=head2 Apply

Takes a view name and optionally arguments that are passed to ->new.  Used to
apply a view over the results of a previous one, allowing for chained views.

    'ul.todo-list li' => {
      '.<-tasks' => Apply('Summary::Task'),
    },

Useful when you wish to delegate the job of processing a section of the template
to a different view, but you don't need a full include.

=head2 Wrap

Used to pass the response on a template to another template, via a 'content'
argument. Similar to the 'wrapper' processing instruction.

=head1 SEE ALSO
  
L<Template::Pure>, L<Catalyst::View::Template::Pure>
 
=head1 AUTHOR
  
    John Napiorkowski L<email:jjnapiork@cpan.org>
 
=head1 COPYRIGHT & LICENSE
  
Please see L<Catalyst::View::Template::Pure>> for copyright and license information.
 
