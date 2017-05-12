package Catalyst::View::Component::SubInclude;
use Moose::Role;

use Carp qw/croak/;
use Catalyst::Utils ();
use Class::MOP ();
use MooseX::Types::Moose qw/Str HashRef/;
use namespace::clean -except => 'meta';

with 'Catalyst::Component::ContextClosure';

=head1 NAME

Catalyst::View::Component::SubInclude - Use subincludes in your Catalyst views

=head1 VERSION

Version 0.10

=cut

our $VERSION = '0.10';
$VERSION = eval $VERSION;

=head1 SYNOPSIS

  package MyApp::View::TT;
  use Moose;

  extends 'Catalyst::View::TT';
  with 'Catalyst::View::Component::SubInclude';

  __PACKAGE__->config( subinclude_plugin => 'SubRequest' );

Then, somewhere in your templates:

  [% subinclude('/my/widget') %]
  [% subinclude_using('SubRequest', '/page/footer') %]

=head1 DESCRIPTION

C<Catalyst::View::Component::SubInclude> allows you to include content in your
templates (or, more generally, somewhere in your view's C<render> processing)
which comes from another action in your application. It's implemented as a
L<Moose::Role|Moose::Role>, so using L<Moose|Moose> in your view is required.

Simply put, it's a way to include the output of a Catalyst sub-request somewhere
in your page.

It's built in an extensible way so that you're free to use sub-requests,
Varnish ESI (L<http://www.catalystframework.org/calendar/2008/17>) or any other
sub-include plugin you might want to implement.

=head1 STASH FUNCTIONS

This component does its magic by exporting a C<subinclude> coderef entry to the
stash. This way, it's easily accessible by the templates (which is the most
common use-case).

=head2 C<subinclude( $path, @args )>

This will render and return the body of the included resource (as specified by
C<$path>) using the default subinclude plugin.

=head2 C<subinclude_using( $plugin, $path, @args )>

This will render and return the body of the included resource (as specified by
C<$path>) using the specified subinclude plugin.

The C<subinclude> function above is implemented basically as a shortcut which
calls this function using the default plugin as the first parameter.

=head1 SUBINCLUDE PLUGINS

The module comes with two subinclude plugins:
L<SubRequest|Catalyst::Plugin::View::Component::SubRequest>,
L<Visit|Catalyst::Plugin::View::Component::Visit> and
L<ESI|Catalyst::Plugin::View::Component::ESI>.

By default, the C<SubRequest> plugin will be used. This can be changed in the
view's configuration options (either in the config file or in the view module
itself).

Configuration file example:

  <View::TT>
      subinclude_plugin   ESI
  </View::TT>

=head2 C<set_subinclude_plugin( $plugin )>

This method changes the current active subinclude plugin in runtime. It expects
the plugin suffix (e.g. C<ESI> or C<SubRequest>) or a fully-qualified class
name in the C<Catalyst::View::Component::SubInclude> namespace.

=head2 Writing plugins

If writing your own plugin, keep in kind plugins are required to implement a
class method C<generate_subinclude> with the following signature:

  sub generate_subinclude {
      my ($class, $c, @args) = @_;
  }

The default plugin is stored in the C<subinclude_plugin> which can be changed
in runtime. It expects a fully qualified class name.

=cut

has 'subinclude_plugin' => (
    is => 'rw',
    isa => Str,
);

has subinclude => (
    is => 'ro',
    isa => HashRef,
    default => sub { {} },
);

around 'new' => sub {
    my $next = shift;
    my $class = shift;

    my $self = $class->$next( @_ );

    my $subinclude_plugin = $self->config->{subinclude_plugin} || 'SubRequest';
    $self->set_subinclude_plugin( $subinclude_plugin );

    $self;
};

before 'render' => sub {
    my ($self, $c, @args) = @_;

    $c->stash->{subinclude}       = $self->make_context_closure(sub { $self->_subinclude( @_ ) }, $c);
    $c->stash->{subinclude_using} = $self->make_context_closure(sub { $self->_subinclude_using( @_ ) }, $c);
};

sub set_subinclude_plugin {
    my ($self, $plugin) = @_;

    my $subinclude_class = blessed $self->_subinclude_plugin_class_instance( $plugin );
    $self->subinclude_plugin( $subinclude_class );
}

sub _subinclude {
    my ($self, $c, @args) = @_;
    $self->_subinclude_using( $c, $self->subinclude_plugin, @args );
}

sub _subinclude_using {
    my ($self, $c, $plugin, @args) = @_;
    $plugin = $self->_subinclude_plugin_class_instance($plugin);
    $plugin->generate_subinclude( $c, @args );
}

has _subinclude_plugin_class_instance_cache => (
    isa => HashRef,
    is => 'ro',
    default => sub { {} },
);

sub _subinclude_plugin_class_instance {
    my ($self, $plugin) = @_;

    my $cache = $self->_subinclude_plugin_class_instance_cache;
    return $cache->{$plugin} if exists $cache->{$plugin};

    my $plugin_config = Catalyst::Utils::merge_hashes(
        $self->subinclude->{ALL}||{},
        $self->subinclude->{$plugin}||{}
    );
    my $short_class = $plugin_config->{'class'} ?
        delete $plugin_config->{'class'}
        : $plugin;
    my $class = $short_class =~ /::/ ?
        $short_class
        : __PACKAGE__ . '::' . $short_class;

    Class::MOP::load_class($class);

    return $cache->{$class} = $class->new($plugin_config);
}

=head1 SEE ALSO

L<Catalyst::Plugin::SubRequest|Catalyst::Plugin::SubRequest>,
L<Moose::Role|Moose::Role>, L<Moose|Moose>,
L<http://www.catalystframework.org/calendar/2008/17>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-catalyst-view-component-subinclude at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Catalyst-View-Component-SubInclude>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 AUTHOR

Nilson Santos Figueiredo Junior, C<< <nilsonsfj at cpan.org> >>

=head1 CONTRIBUTORS

Tomas Doran (t0m) C<< <bobtfish@bobtfish.net >>.

Vladimir Timofeev, C<< <vovkasm at gmail.com> >>.

Wallace Reis (wreis) C<< <wreis@cpan.org> >>.

=head1 SPONSORSHIP

Development sponsored by Ionzero LLC L<http://www.ionzero.com/>.

=head1 COPYRIGHT & LICENSE

Copyright (C) 2010 Nilson Santos Figueiredo Junior and the above contributors.

Copyright (C) 2009 Nilson Santos Figueiredo Junior.

Copyright (C) 2009 Ionzero LLC.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
