package Catalyst::Controller::Public;

use Moose;
extends 'Catalyst::Controller';

our $VERSION = '0.004';

has show_debugging => (is=>'ro', required=>1, default=>sub {0});
has cache_control => (is=>'ro', isa=>'Str', predicate=>'has_cache_control');
has content_types => (is=>'ro', isa=>'ArrayRef[Str]', predicate=>'has_content_types');
has chain_base_action => (is=>'ro', isa=>'Str', predicate=>'has_chain_base_action');
has chain_pathpart => (is=>'ro', isa=>'Str', predicate=>'has_chain_pathpart');
 
has at => (
  is=>'ro',
  isa=>'Str',
  required=>1,
  default=>'/:namespace/:args');
 
after 'register_actions' => sub {
  my ($self, $app) = @_;
  my %base_path_attributes = $self->has_chain_base_action ?
    (
      Chained => [$self->chain_base_action],
      PathPart => [$self->has_chain_pathpart ? $self->chain_pathpart : $self->action_namespace],
      Args => []
    ) : (Path => [ $self->action_namespace ]);

  my $action = $self->create_action(
    name => 'serve_file',
    code => sub { },
    reverse => $self->action_namespace . '/' .'serve_file',
    namespace => $self->action_namespace,
    class => ref($self),
    attributes => {
      %base_path_attributes,
      Does => ['Catalyst::ActionRole::Public'],
      At => [$self->at],
      ShowDebugging => [$self->show_debugging],
      ( $self->has_cache_control ? (CacheControl => [$self->cache_control]) : ()),
      ( $self->has_content_types ? (ContentTypes => $self->content_types)
        : ()),
    });
 
  $app->dispatcher->register( $app, $action );
};
 
sub uri_args {
  my $self = shift;
  return $self->action_for('serve_file'), @_;
}
 
__PACKAGE__->meta->make_immutable;

=head1 NAME 

Catalyst::Controller::Public - mount a public url to files in your Catalyst project

=head1 SYNOPSIS

    package MyApp::Controller::Public;

    use Moose;
    extends 'Catalyst::Controller::Public';

    __PACKAGE__->meta->make_immutable;

Will create an action that matches '$HOST/public/@args', for example like a URL
'localhost/public/a/b/c/d.js', that will serve file $c->{root} . '/public' . '/a/b/c/d.js'.

Will also set content type, length and Last-Modified HTTP headers as needed.
If the file does not exist, will not match (allowing possibly other actions to match).

You can create a URL for a static file programmtically via the following:

    sub myaction :Local {
      my ($self, $c) = @_;
      my $static_url = $c->uri_for(controller('Public')->uri_args('example.txt'));
    }

If you are using Chaining then you will probably need to specify the 'root' chain

    package MyApp::Controller::Public;

    use Moose;
    extends 'Catalyst::Controller::Public';

    __PACKAGE__->meta->make_immutable;
    __PACKAGE__->config(chain_base_action=>'/root');

=head1 DESCRIPTION

This is a simple controller that uses L<Catalyst::ActionRole::Public>
to create a single public folder for you webapplication, doing as much
of the right thing as possible.  Useful for starting a new project, although
I imagine as time goes on you'll probably want something stronger.

This controller doesn't do anything like compile LESS to CSS, etc.  If you
are looking for that you might find L<Catalyst::Controller::SimpleCAS> has
more power for what you wish.  This is really aimed at helping people move
away from L<Catalyst::Plugin::Static::Simple> which I really don't want
to support anymore :)

=head1 METHODS

This controller defines the following methods

=head2 uri_args

Used as a helper to correctly generate a URI.  For example:

    sub myaction :Local {
      my ($self, $c) = @_;
      my $static_url = $c->uri_for(controller('Public')
        ->uri_args('example.txt'));
    }

=head1 ATTRIBUTES

This controller defines the following configuration attributes.  They
are pretty much all just wrappers for the same configuration options for
the L<Catalyst::ActionRole::Public>

has chain_base_action => (is=>'ro', isa=>'Str', predicate=>'has_chain_base_action');
has chain_pathpart => (is=>'ro', isa=>'Str', predicate=>'has_chain_pathpart');

=head2 chain_base_action

Should be the full private path of the root chain action.  This is the value you'd
normally put into the subroutine attribute 'Chained'. If you are doing
the normal thing this is probably called '/root'.

If you leave this undefined we assume you are not using chaining and we will create
a new base path for this controller / action to match.

=head2 chain_pathpart

The value for 'PathPart' in your chaining declaration.  This defaults to the namespace,
which is often correct but if you are doing something fussy you might need control
over it.

=head2 at

Template used to control how we build the path to find your public file.
You probably want to leave this alone if you are seeking the most simple
thing (which this controller is aimed at).  See the documentation for 'At'
over in L<Catalyst::ActionRole::Public> if you really need to mess with this
(and you might want the increased control that action role gives you anyway.

=head2 content_types

Content types that we allow to be served.  By default we allow all standard
types (might be more than you want, if your public directory contains things
you don't want the public to see.

=head2 show_debugging

Enabled developer debugging output.  Default to 0 (false, no debugging).  Change
to 1 if you want extended debugging info.

=head2 cache_control

Used to set the Cache-Control HTTP header (useful for caching your static assets).

Example values "public, max-age=600"

=head1 AUTHOR
 
John Napiorkowski L<email:jjnapiork@cpan.org>
  
=head1 SEE ALSO
 
L<Catalyst>, L<Catalyst::Controller>, L<Plack::App::Directory>,
L<Catalyst::Controller::Assets>.  L<Catalyst::Controller::SimpleCAS>
 
=head1 COPYRIGHT & LICENSE
 
Copyright 2017, John Napiorkowski L<email:jjnapiork@cpan.org>
 
This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
