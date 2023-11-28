package Dancer2::Plugin::LiteBlog::Widget;

use Moo;
use Carp 'croak';

=head1 NAME

Dancer2::Plugin::LiteBlog::Widget - Base class for LiteBlog widgets

=head1 SYNOPSIS

This is an abstract class and should be subclassed.

=head1 USAGE

    package MyWidget;
    use Moo;
    extends 'Dancer2::Plugin::LiteBlog::Widget';

    sub elements {
        # Implement the elements method
        # $element = []; ...
        return $elements;
    }

=head1 DESCRIPTION

This is a base class (interface) for widgets used in LiteBlog, a Dancer2
plugin. Widgets that extends that interface are expected to implement 
certain methods to be functional. 

Widgets in LiteBlog are used to render some UI elements in the site and 
can provide their own views and CSS.

=head1 ATTRIBUTES

=head2 root

The C<root> attribute specifies the root directory for the widget. It's a
required attribute and must be a valid directory, or an error will be thrown.

This directory is the base directory of the widget, where resources will be 
looked for such as YAML or Markdown files, depending on the implementation 
of the widget.

=cut

has root => (
    is => 'ro',
    required => 1,
    isa => sub {
        my $val = shift;
        croak "Not a valid directory ($val)" if ! -d $val;
    },
);

=head2 dancer 

Optional read-only attribute.

The C<dancer> attribute is a handle over the L<Dancer2::Core::DSL> instance of
Liteblog. This is useful for logging to the Dancer App.

Example:

   $self->dancer->info("Some debugging info from the widget");

=cut

has dancer => (
    is => 'ro',
);

=head1 METHODS

=head2 info ($message)

If a C<dancer> attribute is set, issue a C<info> call with the given message,
properly prefixed by the Widget's name. If no C<dancer> is defined, returns undef and does 
nothing.

=cut

sub info {
    my ($self, $message) = @_;
    return undef if ! defined $self->dancer;

    my $class = ref($self);
    $class =~ s/^Dancer2::Plugin:://;
    my $prefix = "[$class]";

    $self->dancer->info("$prefix $message");
}

=head2 error ($message)

If a C<dancer> attribute is set, issue a C<error> call with the given message,
properly prefixed by the Widget's name. If no C<dancer> is defined, returns undef and does 
nothing.

=cut

sub error {
    my ($self, $message) = @_;
    return undef if ! defined $self->dancer;

    my $class = ref($self);
    $class =~ s/^Dancer2::Plugin:://;
    my $prefix = "[$class]";

    $self->dancer->error("$prefix $message");
}

=head2 elements

This method must be implemented by any class inheriting from this module. It must 
return a list of objects that will be iterated over in the widget's template for 
rendering. The objects themselves depend on the widget and should be coherent 
with the associated view.

See L<Dancer2::LiteBlog::Widget::Activities> for a simple example.

=cut

sub elements {
    croak "Must be implemented by child class";
}

=head2 has_routes

If the widget adds route to the Dancer2 application, it should override
this method to return a true value. 

=cut

sub has_routes { 0 }


=head2 has_rss 

Returns true if the widget is supposed to expose a RSS feed. 
Defaults to false. If set to true in the child class, attribute 
C<mount> must be defined as well to construct the feed URL, and a 
C<mount/rss/> route must be declared.

=cut

sub has_rss { 0 }

=head2 declare_routes($self, $plugin, $config)

Any widget intending to declare its own routes should implement this method.
The method is passed the L<Dancer2::Plugin> C<$plugin> object associated with 
LiteBlog (which provides handlers to the DSL and other Dancer2's internal APIs, 
and the Widget's config section.

    sub declare_routes {
        my ($self, $plugin, $config) = @_;
        $plugin->app->add_route(
            ...
        );
    }

=cut

sub declare_routes { 
    croak "Must be implemented by chikld class";
}

=head2 cache ($key[, $val])

  $widget->cache($key, $value);  # set
  my $value = $widget->cache($key);  # get

Provides a simple caching interface within a widget, storing values in a
private singleton hash. Cache keys are constructed uniquely for each calling class and
the provided key to avoid collisions, formatted as "ClassName[$key]". When
called with a single argument, it acts as a getter, returning the value for the
given key if present. With two arguments, it stores the value under the
specified key, acting as a setter.

=cut

my $_cache = {};
sub cache {
    my ($self, $key, $val) = @_;
    
    my ($package) = caller();
    my $cache_key = "${package}[$key]";

    # getter
    if (@_ == 2) {
        return $_cache->{$cache_key};
    }

    return $_cache->{$cache_key} = $val;
}

1;
__END__

=head1 SEE ALSO

L<Dancer2::Plugin::LiteBlog>, L<Dancer2>, L<Moo>

=head1 AUTHOR

Alexis Sukrieh, C<sukria@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright 2023 by Alexis Sukrieh.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
