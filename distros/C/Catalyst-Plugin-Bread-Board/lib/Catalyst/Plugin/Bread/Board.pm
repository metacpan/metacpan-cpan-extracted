package Catalyst::Plugin::Bread::Board;
use Moose;

our $VERSION   = '0.03';
our $AUTHORITY = 'cpan:STEVAN';

sub setup {
    my $c = shift;
    $c->config(
        $c->config
          ->{'Plugin::Bread::Board'}
          ->{'container'}
          ->as_catalyst_config
    );
    $c->next::method( @_ )
}


__PACKAGE__->meta->make_immutable;

no Moose; 1;

__END__

=pod

=head1 NAME

Catalyst::Plugin::Bread::Board - use Bread::Board to configure your Catalyst app

=head1 SYNOPSIS

  # ... the Catalyst application

  package My::App;
  use Moose;

  use Catalyst qw[
      Bread::Board
  ];

  __PACKAGE__->config(
      'Plugin::Bread::Board' => {
          container => My::App::Container->new(
              name     => 'My::App',
              app_root => __PACKAGE__->path_to('.')
          )
      }
  );

  # ... now the container

  package My::App::Container;
  use Moose;
  use Bread::Board;

  extends 'Catalyst::Plugin::Bread::Board::Container';

  sub BUILD {
      my $self = shift;

      container $self => as {

          container 'Model' => as {
              container 'DBIC' => as {
                  service 'schema_class' => 'Test::App::Schema::DB';
                  service 'connect_info' => [
                      'dbi:mysql:my_app_db',
                      'me',
                      '****'
                  ];
              };
          };

          container 'View' => as {
              container 'TT' => as {
                  service 'TEMPLATE_EXTENSION' => '.tt';
                  service 'INCLUDE_PATH'       => (
                      block => sub {
                          my $root = (shift)->param('app_root');
                          [ $root->subdir('root/templates')->stringify ]
                      },
                      dependencies => [ depends_on('/app_root') ]
                  );
              };
          };

      };
  }

=head1 CAVEAT

This is a B<very> early release of this module, so you have been warned!

=head1 DESCRIPTION

This module allows you to use Bread::Board as a replacement for you standard
Catalyst configuration. As you can see from the SYNOPSIS you subclass the
L<Catalyst::Plugin::Bread::Board::Container> class and create your own
Bread::Board container to hold all the normal Catalyst configuration data.

At first glance this may look just like a more verbose way to write your
Catalyst configuration. And on some level that is exactly what it is
right now. (We do have plans to write something to read in those old
Catalyst configurations and turn them into Bread::Board configs like above).
But, there is more to this then just more typing, this module provides
two features which are not present in your basic Catalyst configurations.

=over 4

=item I<Config info is easily accessible outside of Catalyst>

It is easy to instantiate the container completely outside of the
Catalyst application and use it in your utility scripts or in other
applications entirely. Here is an example of a parameterized container
that would allow you to use the DBIx::Class::Schema outside of
Catalyst.

  my $c = container 'DBIC' => [ 'SchemaInfo' ] => as {
      service 'schema' => (
          class => 'DBIx::Class::Schema',
          block => sub {
              my $s = shift;
              $s->param('schema_class')->connect(
                  @{ $s->param('connect_info') }
              )
          },
          dependencies => {
              schema_class => depends_on('SchemaInfo/schema_class'),
              connect_info => depends_on('SchemaInfo/connect_info'),
          }
      );
  };

  my $schema = $c->create(
      SchemaInfo => $catalyst_container->fetch('Model/DBIC')
  )->fetch('schema')->get;

There are plans to provide a set of common utility containers such as
this in the core module, look for future releases.

=item I<Configurations are easily subclassable>

As discussed in L<Bread::Board::Manual::Concepts::Advanced> it is possible
to subclass these containers in such ways that it would be possible to
essentially subclass and inherit your configurations. Here is an example
of doing just that with the container from the SYNOPSIS.

  package My::App::Extended::Container;
  use Moose;
  use Bread::Board;

  extends 'My::App::Container';

  sub BUILD {
      my $self = shift;
      $self->fetch('Model')->add_sub_container(
          container 'KiokuDB' => (
              model_class => 'My::App::Kioku::Model',
              dsn         => 'bdb:dir=root/db',
          );
      );
  }

This would give you all the same stuff as the original My::App::Container
but would also add another model.

=back

=head1 BUGS

All complex software has bugs lurking in it, and this module is no
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 AUTHOR

Stevan Little E<lt>stevan.little@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2010 Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
