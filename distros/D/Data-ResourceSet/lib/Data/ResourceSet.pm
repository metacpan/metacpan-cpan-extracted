# $Id: /mirror/coderepos/lang/perl/Data-ResourceSet/trunk/lib/Data/ResourceSet.pm 54071 2008-05-19T06:52:45.149433Z daisuke  $

package Data::ResourceSet;
use Moose;

has 'resources' => (
    is       => 'rw',
    isa      => 'HashRef',
    required => 1,
    default  => sub { +{} }
);

has 'resources_config' => (
    is       => 'rw',
    isa      => 'HashRef',
    default  => sub { +{} },
);

our $VERSION = '0.00003';

sub resource
{
    my ($self, $type, $name, @args) = @_;

    my $resource = $self->resources->{$type}->{$name};
    if (! $resource) {
        my $config = $self->find_config($type, $name);
        if ($config) {
            $resource = $self->construct_resource($name, $config, @args);
            if ($resource) {
                $self->resources->{$type}->{$name} = $resource;
            }
        }
    }

    if ($resource && $resource->can('ACCEPT_CONTEXT')) {
        return $resource->ACCEPT_CONTEXT($self, @args);
    }

    return $resource;
}

sub find_config
{
    my ($self, $type, $name) = @_;

    my $config;
    # find a per-instance config
    $config = $self->resources_config->{$type}->{$name};
    if ($config) {
        return $config;
    }

    # find a per-package config
    $config = $self->can('config') ?
        $self->config('resources')->{$type}->{$name} : ();
    if ($config) {
        return $config;
    }

    return ();
}

sub construct_resource
{
    my ($self, $name, $config, @args) = @_;

    my $pkg         = $config->{module};
    if ($pkg !~ s/^\+//) {
        $pkg = join('::', blessed $self, $pkg);
    }
    if (! Class::MOP::is_class_loaded($pkg)) {
        eval "require $pkg";
        die if $@;
    }

    my $constructor = $config->{constructor} || 'new';
    my $args        = $config->{args} || {};
    my $deref       = $config->{deref};
    my $ref         = ref $args;
    $pkg->$constructor( ($deref && $ref) ?
        ($ref eq 'ARRAY' ? @$args :
        $ref eq 'HASH' ? %$args : $args) :
        $args
    );
}

1;

__END__

=head1 NAME

Data::ResourceSet - A Bundle Of Resources

=head1 SYNOPSIS

  my $cluster = Data::ResourceSet->new(
    resources => {
      schema => {
        name1 => $dbic_schema1
        name2 => $dbic_schema2
      },
      s3bucket => {
        name1 => $s3bucket1,
        name2 => $s3bucket2,
      }
    }
  );

  my $photo_meta =
    $cluster->resource('schema', 'Name')->resultset('Photo')->find($photo_id);
  my $photo_file =
    $cluster->resource('s3bucket', 'Name')->get_key($key, $filename);

=head1 DESCRIPTION

Data::ResourceSet is a bag of "stuff", where you can refer to the "stuff"
by name, and the "stuff" will be initialized for you.

For example, say you have multiple DBIx::Class::Schema objects in your
app. You would like to make the reference to each resource as abstract
as possible so you don't hard code anything. Then you can create an
instance of Data::ResourceSet and refer to these schemas by name.

Here are two ways to do it. First is to simply create a resource set from
already instantiated schemas:

  my $schema1 = MyCluster1->connect($dsn, $user, $pass);
  my $schema2 = MyCluster2->connect($dsn, $user, $pass);
  my $resources = Data::ResourceSet->new({
    resources => {
      schema => {
        cluster1 => $schema1,
        cluster2 => $schema2,
      }
    }
  });

  $resources->resource('schema', 'cluster1')->resultset('FooBar')->search(...)

The other way to do it is by giving a similar hash, but give only the config

  my $resources = Data::ResourceSet->new({
    resources_config => {
      schema => {
        cluster1 => {
          module      => '+DBIx::Class::Schema',
          consturctor => 'connect',
          args        => [ $dsn, $user, $pass ],
        },
        cluster2 => {
          module      => '+DBIx::Class::Schema',
          consturctor => 'connect',
          args        => [ $dsn, $user, $pass ],
        }
      }
    }
  });
  $resources->resource('schema', 'cluster1')->resultset('FooBar')->search(...)

The difference between the first and the second example above is that
the latter does a lazy initialization. So if you don't want to connect
until you actually use the connection, then the second way is the way to go.

You can also specify this config on a per-package level, say, when you subclass
Data::ResourceSet:

  package MyApp::ResourceSet;
  use base qw(Data::ResourceSet);

  __PACKAGE__->config(
    resources => {
      schema => {
        cluster1 => {
          module      => '+DBIx::Class::Schema',
          consturctor => 'connect',
          args        => [ $dsn, $user, $pass ],
        },
        cluster2 => {
          module      => '+DBIx::Class::Schema',
          consturctor => 'connect',
          args        => [ $dsn, $user, $pass ],
        }
      }
    }
  });

  my $resources = MyApp::ResourceSet->new;
  $resources->resource('schema', 'cluster1')->resultset('FooBar')->search(...)

You can also use Data::ResourceSet::Adaptor, which can be a proxy between
Data::ResourceSet and your actual resource.

  package MyProxy;
  use base qw(Data::ResourceSet::Adaptor);

  sub ACCEPT_CONTEXT
  {
    my($self, $c, @args) = @_;
    ...
    return $whatever;
  }

  my $resource = Data::ResourceSet->new({
    resource_config => {
      foo => {
        bar => {
          module => '+MyProxy',
          args   => \%whatever
        }
      }
    }
  });

=head1 APPLICATION

Data::ResourceSet is inspired by Catalyst and its method of being a glue
mediator between components. You can use it in applications where you have
multiple components, and you don't want to refer to a hardcoded resource.

Also, it's quite handy when you want to partition your storage on large
applications. In such cases, you should create multiple Data::ResourceSet
objects with the same keys:

  my $schema1 = DBIx::Class::Schema->connect(...);
  my $schema2 = DBIx::Class::Schema->connect(...);

  my $cluster1 = Data::ResourceSet->new({
    resources => {
      schema => {
        name => $schema1,
      }
    }
  });
  
  my $cluster2 = Data::ResourceSet->new({
    resources => {
      schema => {
        name => $schema2,
      }
    }
  });

  # For whichever cluster above...
  $cluster->resource('schema', 'name')->resultset(...)
  
=head1 METHODS

=head2 new(\%args)

=over 4

=item resources => \%data

=item resources_config => \%config

=back

=head2 resource($type, $name)

Gets a resource by its type and name

=head2 construct_resource

Constructs a resource by its config

=head2 find_config

Find the configuration for a resource

=head1 AUTHOR

Copyright (c) 2008 Daisuke Maki C<< daisuke@endeworks.jp >>

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself (Artistic License v1.0/v2.0).

See http://www.perl.com/perl/misc/Artistic.html

=cut

