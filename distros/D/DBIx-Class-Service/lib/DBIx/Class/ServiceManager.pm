package DBIx::Class::ServiceManager;

use strict;
use warnings;

use Carp::Clan qw(^DBIx::Class);
use Module::Find qw();

use base qw(DBIx::Class);

__PACKAGE__->mk_classdata('service_mapping' => {});

=head1 NAME

DBIx::Class::ServiceManager - Load DBIx::Class::Service objects and create accessor for services.

=head1 VERSION

version 0.02

=cut

our $VERSION = '0.02';

=head1 SYNOPSIS

In your schema:

  package MySchema::Schema;
  
  use strict;
  use warnings;
  
  use base 'DBIx::Class::Schema';
  
  __PACKAGE__->load_classes;
  __PACKAGE__->load_components(qw/ServiceManager/);
  __PACKAGE__->load_services({ 'MySchema::Service' => [qw/
    User
  /] });
  
  1;

=head1 METHODS

=head2 service($service_name)

Accessor for DBIx::Class::ServiceProxy classes.
The access key is suffix of each service class name.

=cut

sub service {
    my ($self, $service_name) = @_;

    if ($service_name && exists $self->service_mapping->{$service_name}) {
        my $service = $self->service_mapping->{$service_name};
        $service->schema($self) unless (defined $service->schema);
        return $service;
    }

    return;
}

=head2 load_services(@args)

Load services from pair of class prefix and service class suffixes.
Default prefix value is added "::Service" end of the service class name.

If the schema class called "MySchema::Schema", then the default prefix is "MySchema::Schema::Service".

=over 4

=item ARRAY

The prefix is default. Each item in the array is service class suffix.

  package MySchema::Schema;
  
  use base 'DBIx::Class::Schema';
  
  __PACKAGE__->load_classes;
  __PACKAGE__->load_components(qw/ServiceManager/);
  
  __PACKAGE__->load_service(qw/User Diary/);
  ### Loads MySchame::Schema::Service::User, MySchame::Schema::Service::Diary

=item ARRAYREF

Same behavior as using ARRAY.

=item HASHREF

Use each keys of HASHREF as service class prefix.
Each values must be ARRAYREF include class name suffixes.

  package MySchema::Schema;
  
  use base 'DBIx::Class::Schema';
  
  __PACKAGE__->load_classes;
  __PACKAGE__->load_components(qw/ServiceManager/);
  __PACKAGE__->load_services({ 'MySchema::Service' => [qw/
    User Diary
  /] });
  ### Loads MySchame::Service::User, MySchame::Service::Diary

=back

=cut

sub load_services {
    my ($class, @args) = @_;

    my %services_for = ();
    my $prefix = "${class}::Service";

    $class->service_mapping({});

    if (@args) {
        for my $arg (@args) {
            if (ref $arg eq 'ARRAY') { ### array refernce
                my @modules = grep { $_ !~ /^#/ } @$arg;
                push(@{$services_for{$prefix}}, @modules);
            }
            elsif (ref $arg eq 'HASH') { ### hash reference
                for my $base (keys %$arg) {
                    my @modules = grep { $_ !~ /^#/ } @{$arg->{$base}};
                    push(@{$services_for{$base}}, @modules);
                }
            }
            else {
                push(@{$services_for{$prefix}}, $arg) if ($arg !~ /^#/);
            }
        }
    }
    else { 
        my @modules = Module::Find::findsubmod($prefix);
        push(@{$services_for{$prefix}}, map { $_ =~ s/${prefix}:://x; $_ } @modules);
    }

    ### register services with ensure_class_*
    for my $base (keys %services_for) {
        $class->ensure_class_loaded(join("::", $base, $_)) for (@{$services_for{$base}});
        $class->register_service($base, [
            grep { $class->ensure_class_found(join("::", $base, $_)) } 
            @{$services_for{$base}}
        ]);
    }
}

=head2 register_service($base, $services)

Register service classes. (internal)

=cut

sub register_service {
    my ($class, $base, $services) = @_;

    for my $service (@$services) {
        my $service_class = join('::', $base, $service);
        my $service_proxy_class = join('::', $service_class, 'Proxy');

        my $methods = $service_class->load_service_methods();

        return unless ($methods);

        {
            no strict 'refs';

            eval << "SERVICE_PROXY";
package $service_proxy_class;
use base qw(DBIx::Class::ServiceProxy);
__PACKAGE__->service_class(q|$service_class|);
1;
SERVICE_PROXY

            ### add transactional methods
            for my $method (@{$methods->{Transaction} || []}) {
                *{"${service_proxy_class}::${method}"} = sub {
                    my ($proto, @args) = @_;
                    my @ret;

                    my $schema = $proto->schema;

                    $schema->txn_begin;
                    eval {
                        @ret = $proto->service_class->$method($schema, @args) || ();
                    };
                    if (my $exception = $@) {
                        $schema->txn_rollback;
                        croak($exception);
                    }
                    $schema->txn_commit;
                    return wantarray ? @ret : $ret[0];
                };
            }

            ### add datasource methods
            for my $method (@{$methods->{DataSource} || []}) {
                *{"${service_proxy_class}::${method}"} = sub {
                    my ($proto, @args) = @_;
                    return $proto->service_class->$method($proto->schema, @args);
                };
            }
        }

        $class->service_mapping->{$service} = $service_proxy_class;
    }
}

=head1 SEE ALSO

=over 4

=item DBIx::Class::Service

=item DBIx::Class::ServiceProxy

=back

=head1 AUTHOR

Toru Yamaguchi, C<< <zigorou@cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-dbix-class-servicemanager@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.  I will be notified, and then you'll automatically be
notified of progress on your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2008 Toru Yamaguchi, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of DBIx::Class::ServiceManager
