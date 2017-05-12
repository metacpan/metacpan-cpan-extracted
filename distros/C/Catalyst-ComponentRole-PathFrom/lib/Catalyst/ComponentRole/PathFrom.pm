package Catalyst::ComponentRole::PathFrom;

our $VERSION = '0.002';

use File::Spec;
use Moose::Role;

with 'Catalyst::Component::ApplicationAttribute';

has extension => (
  is=>'ro',
  predicate=>'has_extension');

has stash_key => (
  is=>'ro',
  required=>1,
  lazy=>1,
  builder=>'_build_stash_key');

  sub _build_stash_key { return 'path_from' }

has action_attribute => (
  is=>'ro',
  required=>1,
  lazy=>1,
  builder=>'_build_action_attribute');

  sub _build_action_attribute { return 'PathFrom' }

has path_base => (
  is=>'ro',
  required=>1,
  lazy=>1,
  builder=>'_build_path_base');

  sub _build_path_base {
    my $self = shift;
    my $app = $self->_application;
    return $app->config->{root};
  }

sub _normalized_extension {
  my $self = shift;
  # Because some people think the '.' is always needed...
  my $ext = $self->extension;
  $ext =~s/^\.?(.+)$/$1/;

  return $ext;
}

sub _path_from_proto {
  my ($self, @proto) = @_;
  my $filepath = $proto[0] eq '' ?
    File::Spec->catfile(@proto) :
    $self->path_base->file(@proto);

  if($self->has_extension) {
    $filepath = $filepath .'.'. $self->_normalized_extension;
  }

  return $filepath;
}

sub path_from {
  my $self = shift;
  my $proto = shift;

  my ($c, $action) = ();
  if($proto->isa('Catalyst::Action')) {
    $action = $proto;
  } else {
    $c = $proto;
    my $proto2 = shift;
    if(defined $proto2 && (ref(\$proto2) eq 'SCALAR')) {
      my @string_path = $self->_expand_template($c->action, $proto2);
      return $self->_path_from_proto(@string_path);
    }
    else {
      $action = $proto2;
    }
  }
  
  if(defined $action) {
    # If an action was submitted, create path ONLY from that.
    return $self->_path_from_action_attribute($action)||
      $self->_path_from_action($action);
  } else {
    $action = $c->action;
  }
  
  return $self->_path_from_stash($c) ||
    $self->_path_from_action_attribute($action) ||
      $self->_path_from_action($action);
}

sub _expand_template {
  my ($self, $action, $pattern) = @_;
  my %template_args = (
    ':namespace' => $action->namespace,
    ':reverse' => $action->reverse,
    ':actionname' => $action->name,
  );

  return my @parts =
    map { ref $_ ? @$_ : $_ } 
    map { defined($template_args{$_}) ? $template_args{$_} : $_ }
    split('/', $pattern);
}

sub _path_from_stash {
  my ($self, $c) = @_;
  my $proto = $c->stash->{$self->stash_key};
  return unless defined $proto;

  my @expanded_proto = $self->_expand_template($c->action, $proto);
  return $self->_path_from_proto(@expanded_proto);
}

sub _path_from_action_attribute {
  my ($self, $action) = @_;
  my ($proto, @more) = @{$action->attributes->{$self->action_attribute} || []};
  return unless defined $proto;

  die "Too many action attributes for $action" if @more;

  my @expanded_proto = $self->_expand_template($action, $proto);
  return $self->_path_from_proto(@expanded_proto);
}

sub _path_from_action {
  my ($self, $action) = @_;
  return unless defined $action;
  return $self->_path_from_proto("$action");
}

1;

=head1 NAME

Catalyst::ComponentRole::PathFrom - Derive a path using common Catalyst patterns

=head1 SYNOPSIS

    package MyApp::Model::Path;

    use Moose;

    extends 'Catalyst::Component';
    with 'Catalyst::ComponentRole::PathFrom',
      'Catalyst::Component::InstancePerContext';

    has ctx => (is=>'rw', weak_ref=>1);

    sub build_per_context_instance {
      my ($self, $c) = @_;
      $self->ctx($c);
      return $self;
    }

    around 'path_from', sub {
      my ($orig, $self, @args) = @_;
      return $self->$orig($self->ctx, @args);
    };

    __PACKAGE__->meta->make_immutable;

    package MyApp::Controller::Example;
    use base 'Catalyst::Controller';

    sub test_a :Local {
      my ($self, $c) = @_;
    }

    sub test_b :Local PathFrom('ffffff') {
      my ($self, $c) = @_;
    }

    sub test_c :Local  {
      my ($self, $c) = @_;
      $c->stash(path_from=>'foo/bar');
    }

=head1 DESCRIPTION

Common L<Catalyst> views set a template path using a standard process,
typically one based on the action or from a stash key.  This component
role trys to encapsulate that common pattern, with the hope that it makes
it easier for people to make new Views in a consistent way.  For example
if you make your own custom Views this could save you some time in getting
a common and expected setup.

=head1 ATTRIBUTES

This role exposes the following attributes for configuration

=head2 extension

Optional.  This is a file extension added to the end of your generated file
path.  For example 'html', 'tt2'.  You don't need to include the '.' separator.

=head2 stash_key

Has default, 'path_from'.  Used to set the stash key you wish to use to
programmatically set the file path pattern in your action body.

=head2 action_attribute

Has default, 'PathFrom'.  Used to set the action attribute we use to get a file
path pattern.

=head2 path_base

Has default "$app->config->{root}".  Used to set the base path for relative
paths.  Usually you leave this one alone :)

=head1 METHODS

This role exposes the following public methods

=head2 path_from ( $action | $c | $c, $action | $c, $string_path )

Builds a full path to a file on the filesystem using common L<Catalyst> conventions.

Given an $action, will return $base_path + $action->reverse + $extension OR if
the $action has an attribute value for $action_attribute, return $base_path +
$action_attribute + $extension.

Given $c, will do all the above (using $c->action for $action), but also check if
the stash contains $stash_key and if so use that path instead.

Given $c, $action, does as above but uses the given $action instead of $c->action

Given $c, $string_path, uses $string_path instead of $action->reverse.

When using a $string_path, a $stash_key value or a value in $action_attribute you
may use the following placeholders in the string (for example ':namespace/foo')

=over4

=item :namespace

The action namespace ($action->namespace), which is typically the controller
namespace

=item :reverse

"$action->reverse" (which is basically the default

=item :actionname

"action->name" (the subroutine method name, typically).

=back

B<NOTE>: if you use a $string_path, a $stash_key value or a value in
$action_attribute and that value starts with '/', that is a signal you wish to
use an absolute path, and we don't prepend $self->base_path.  You probably
won't need this...

=head1 SEE ALSO

L<Catalyst>, L<Catalyst::Component>, L<File::Spec>, L<Moose::Role>.

=head1 AUTHOR
 
John Napiorkowski L<email:jjnapiork@cpan.org>
  
=head1 COPYRIGHT & LICENSE
 
Copyright 2015, John Napiorkowski L<email:jjnapiork@cpan.org>
 
This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
