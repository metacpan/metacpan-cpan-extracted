package Catalyst::Plugin::Bread::Board::Container;
use Moose;
use Bread::Board;
use MooseX::Types::Path::Class;

our $VERSION   = '0.03';
our $AUTHORITY = 'cpan:STEVAN';

extends 'Bread::Board::Container';

has 'app_root' => (
    is       => 'ro',
    isa      => 'Path::Class::Dir',
    coerce   => 1,
    required => 1,
);

sub BUILD {
    my $self = shift;

    container $self => as {
        service 'app_root' => $self->app_root;
    };
}

sub as_catalyst_config {
    my $self = shift;

    my $config = {};

    # process any top level stuff
    foreach my $service_name ( $self->get_service_list ) {
        $config->{ $service_name } = $self->get_service( $service_name )->get;
    }

    foreach my $container_name ( $self->get_sub_container_list ) {
        # FIXME
        # this is no doubt wrong, but
        # it will suffice for now
        # - SL
        next unless $container_name =~ /^Model|View|Plugin|Controller$/;

        my $container = $self->get_sub_container( $container_name );

        foreach my $sub_container_name ( $container->get_sub_container_list ) {

            my $sub_container = $container->get_sub_container( $sub_container_name );

            $config->{ join '::' => $container_name, $sub_container_name } = {
                map {
                    $_ => $sub_container->get_service( $_ )->get
                } $sub_container->get_service_list
            };
        }

    }

    $config;
}

__PACKAGE__->meta->make_immutable;

no Bread::Board; no Moose; 1;

__END__

=pod

=head1 NAME

Catalyst::Plugin::Bread::Board::Container - A Bread::Board container for use with Catalyst

=head1 SYNOPSIS

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

=head1 DESCRIPTION

This is a subclass of L<Bread::Board::Container> that is meant to be
used with L<Catalyst::Plugin::Bread::Board>. For now this is pretty
simple, but soon it will have more features.

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
