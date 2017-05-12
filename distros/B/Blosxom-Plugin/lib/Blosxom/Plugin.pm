package Blosxom::Plugin;
use 5.008_009;
use strict;
use warnings;
use Carp qw/croak/;

our $VERSION = '0.02004';

sub import {
    my $class     = shift;
    my $component = scalar caller;
    my $stash     = do { no strict 'refs'; \%{"$component\::"} };

    my %is_excluded;
    while ( my ($method, $glob) = each %{$stash} ) {
        next unless defined *{$glob}{CODE};
        $is_excluded{$method}++;
    }

    my ( @requires, @accessors );

    my @exports = (
        requires => sub { shift; push @requires, @_ },
        mk_accessors => sub { 
            my $pkg = shift;
            my @args = ref $_[0] eq 'HASH' ? %{$_[0]} : map { $_ => undef } @_;
            push @accessors, @args,
        },
        init => sub {
            my ( $comp, $plugin ) = @_;

            if ( my @methods = grep { !$plugin->can($_) } @requires ) {
                my $methods = join ', ', @methods;
                croak "Can't apply '$comp' to '$plugin' - missing $methods";
            }

            for ( my $i = 0; $i < @accessors; $i += 2 ) {
                $plugin->add_attribute( @accessors[$i, $i+1] );
            }

            while ( my ($method, $glob) = each %{$stash} ) {
                if ( my $code = *{$glob}{CODE} ) {
                    next if $is_excluded{$method};
                    $plugin->add_method( $method => $code );
                }
            }

            return;
        },
    );

    # export mixin methods
    no strict 'refs';
    while ( my ( $method, $code ) = splice @exports, 0, 2 ) {
        *{ "$component\::$method" } = $code;
        $is_excluded{ $method }++;
    }

    return;
}

my %attribute_of;

sub mk_accessors {
    my $package   = shift;
    my @accessors = ref $_[0] eq 'HASH' ? %{ $_[0] } : map { $_ => undef } @_;

    no strict 'refs';
    while ( my ($field, $default) = splice @accessors, 0, 2 ) {
        *{"$package\::$field"} = $package->make_accessor($field, $default);
    }

    return;
}

sub make_accessor {
    my $package   = shift;
    my $name      = shift;
    my $default   = shift;
    my $attribute = $attribute_of{$package} ||= {};

    if ( ref $default eq 'CODE' ) {
        return sub {
            return $attribute->{$name} = $_[1] if @_ == 2;
            return $attribute->{$name} if exists $attribute->{$name};
            return $attribute->{$name} = $package->$default;
        };
    }
    elsif ( defined $default ) {
        return sub {
            return $attribute->{$name} = $_[1] if @_ == 2;
            return $attribute->{$name} if exists $attribute->{$name};
            return $attribute->{$name} = $default;
        };
    }
    else {
        return sub {
            @_ > 1 ? $attribute->{$name} = $_[1] : $attribute->{$name};
        };
    }

    return;
}

sub end { %{ $attribute_of{$_[0]} } = () if exists $attribute_of{$_[0]} }

sub dump {
    my $package = shift;
    require Data::Dumper;
    local $Data::Dumper::Maxdepth = shift || 1;
    Data::Dumper::Dumper( $attribute_of{$package} );
}

sub component_base_class { __PACKAGE__ }

sub load_components {
    my $package = shift;
    my @args    = @_;
    my $prefix  = $package->component_base_class;

    my ( $component, %is_loaded, %has_conflict, %code_of );

    local *add_component 
        = sub { push @args, @_ > 2 ? @_[1, 2] : $_[1] };

    local *add_method = sub {
        my ( $pkg, $method, $code ) = @_;
        unless ( defined &{"$package\::$method"} ) {
            push @{ $has_conflict{$method} ||= [] }, $component;
            $code_of{ $method } = $code;
        }
    };

    while ( @args ) {
        $component = do {
            my $class = shift @args;

            if ( $class !~ s/^\+// and $class !~ /^$prefix/ ) {
                $class = "$prefix\::$class";
            }

            if ( $is_loaded{$class}++ ) {
                shift @args if ref $args[0] eq 'HASH';
                next;
            }

            ( my $file = $class ) =~ s{::}{/}g;
            require "$file.pm";

            $class;
        };

        my $config = ref $args[0] eq 'HASH' ? shift @args : undef;

        $component->init( $package, $config );
    }

    if ( %code_of ) {
        no strict 'refs';
        while ( my ( $method, $components ) = each %has_conflict ) {
            delete $has_conflict{ $method } if @{ $components } == 1;
            *{ "$package\::$method" } = $code_of{ $method };
        }
    }

    if ( %has_conflict ) {
        croak join "\n", map {
            "Due to a method name conflict between components " .
            "'" . join( ' and ', sort @{ $has_conflict{$_} } ) . "', " .
            "the method '$_' must be implemented by '$package'";
        } keys %has_conflict;
    }

    return;
}

sub add_attribute {
    my ( $pkg, $name, $default ) = @_;
    $pkg->add_method( $name => $pkg->make_accessor($name, $default) );
}

sub has_method { defined &{"$_[0]::$_[1]"} }

1;

__END__

=head1 NAME

Blosxom::Plugin - Base class for Blosxom plugins

=head1 SYNOPSIS

  package my_plugin;
  use strict;
  use warnings;
  use parent 'Blosxom::Plugin';

  # generates a class attribute called foo()
  __PACKAGE__->mk_accessors( 'foo' );

  # does Blosxom::Plugin::DataSection
  __PACKAGE__->load_components( 'DataSection' );

  sub start {
      my $pkg = shift;

      $pkg->foo( 'bar' );
      my $value = $pkg->foo; # => "bar"

      my $template = $pkg->get_data_section( 'my_plugin.html' );
      # <!DOCTYPE html>
      # ...

      # merge __DATA__ into Blosxom default templates
      $pkg->merge_data_section_into( \%blosxom::template );

      return 1;
  }

  1;

  __DATA__

  @@ my_plugin.html

  <!DOCTYPE html>
  <html>
  <head>
    <title>My Plugin</title>
  </head>
  <body>
  <h1>Hello, world</h1>
  </body>
  </html>

=head1 DESCRIPTION

This module enables Blosxom plugins to create class attributes
and load additional components.

Blosxom never creates instances of plugins,
and so they can't have instance attributes.
This module creates class attributes instead,
and always undefines them after all output has been processed.

Components will abstract routines from Blosxom plugins.
It's intended that they will be shared on CPAN.

=head2 METHODS

=over 4

=item $class->mk_accessors( @fields )

=item $class->mk_accessors({ $field => \&default, ... })

This creates class attributes for each named field given
in C<@fields>.

  __PACKAGE__->mk_accesssors(qw/foo bar car/);

Attributes can have default values which is not generated
until the field is read. C<&default> is called as a method on the class
with no additional parameters.

  use Path::Class::File;

  __PACKAGE__->mk_accessors({
      'path' => undef,
      'file' => sub {
          my $pkg = shift; # => "my_plugin"
          Path::Class::File->new( $pkg->path );
      },
  });

  sub start {
      my $pkg = shift;

      $pkg->path( '/path/to/entry.txt' );
      my $path = $pkg->path; # => "/path/to/entry.txt"

      # file() is a Path::Class::File object
      my $basename = $pkg->file->basename; # => "entry.txt"

      return 1;
  }

=item $class->load_components( @components )

=item $class->load_components( $component => \%configuration, ... )

Loads the given components into the current module.
Components can be configured by the loaders.
If a module begins with a C<+> character,
it is taken to be a fully qualified class name,
otherwise C<Blosxom::Plugin> is prepended to it.

  __PACKAGE__->load_components( '+MyComponent' => \%config );

This method calls C<init()> method of each component.
C<init()> is called as follows:

  MyComponent->init( 'my_plugin', \%config )

If multiple components are loaded in a single call, then if any of their
provided methods clash, an exception is raised unless the class provides
the method.

=item $class->add_method( $method_name => $coderef )

This method takes a method name and a subroutine reference,
and adds the method to the class.
Available while loading components.
If a method is already defined on the class, that method will not be added.

  package MyComponent;

  sub init {
      my ( $class, $caller, $config ) = @_;
      $caller->add_method( 'foo' => sub { ... } );
  }

=item $class->add_attribute( $attribute_name )

=item $class->add_attribute( $attribute_name, \&default )

This method takes an attribute name, and adds the attribute to the class.
Available while loading components.
Attributes can have default values which is not generated
until the attribute is read.
C<&default> is called as a method on the class with no additional arguments.

  sub init {
      my ( $class, $caller ) = @_;
      $caller->add_attribute( 'foo' );
      $caller->add_attribute( 'bar' => sub { ... } );
  }

=item $class->add_component( $component )

=item $class->add_component( $component => \%configuration )

This adds the component to the list of components to be loaded
while loading components.

  sub init {
      my ( $class, $caller ) = @_;
      $caller->add_component( 'DataSection' );
  }

=item $bool = $class->has_method( $method_name )

Returns a Boolean value telling whether or not the class defines the named
method. It does not include methods inherited from parent classes.

=item $class->end

Undefines class attributes generated by C<mk_accessors()>
or C<add_attribute()>.
Since C<end()> is one of recognized hooks,
it's guaranteed that Blosxom always invokes this method.

  sub end {
      my $class = shift;
      # do something
      $class->SUPER::end;
  }

=item $class->dump( $max_depth )

This method uses L<Data::Dumper> to dump the class attributes.
You can pass an optional maximum depth, which will set
C<$Data::Dumper::Maxdepth>. The default maximum depth is 1.

=back

=head1 DEPENDENCIES

L<Blosxom 2.0.0|http://blosxom.sourceforge.net/> or higher.

=head1 SEE ALSO

L<Blosxom::Plugin::Web>,
L<Amon2>,
L<Moose::Manual::Roles>,
L<MooseX::Role::Parameterized::Tutorial>

=head1 ACKNOWLEDGEMENT

Blosxom was originally written by Rael Dohnfest.
L<The Blosxom Development Team|http://sourceforge.net/projects/blosxom/>
succeeded to the maintenance.

=head1 BUGS AND LIMITATIONS

There are no known bug in this module. Please report problems to
ANAZAWA (anazawa@cpan.org). Patches are welcome.

=head1 AUTHOR

Ryo Anazawa <anazawa@cpan.org>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2012 Ryo Anzawa. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=cut
