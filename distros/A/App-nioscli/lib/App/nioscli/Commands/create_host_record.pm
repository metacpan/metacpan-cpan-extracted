#
# This file is part of App-nioscli
#
# This software is Copyright (c) 2021 by Christian Segundo.
#
# This is free software, licensed under:
#
#   The Artistic License 2.0 (GPL Compatible)
#
## no critic
package App::nioscli::Commands::create_host_record;
$App::nioscli::Commands::create_host_record::VERSION = '0.001';

# VERSION
# AUTHORITY

## use critic
use strictures 2;
use JSON qw(from_json);
use MooseX::App::Command;

extends qw(App::nioscli);

command_short_description 'Create a HOST record';

with 'App::nioscli::Roles::Creatable';

option 'name' => (
  is       => 'ro',
  isa      => 'Str',
  required => 1
);

option 'address' => (
  is       => 'ro',
  isa      => 'ArrayRef[Str]',
  required => 1
);

option 'extattrs' => (
  is  => 'ro',
  isa => 'Str'
);

has 'payload' => (
  is      => 'ro',
  isa     => 'HashRef',
  lazy    => 1,
  default => sub {
    my $self = shift;

    my $payload = {
      name      => $self->name,
      ipv4addrs => []
    };

    foreach ( @{ $self->address } ) {
      push( @{ $payload->{ipv4addrs} }, { ipv4addr => $_ } );
    }

    $payload->{extattrs} = from_json( $self->extattrs ) if defined $self->extattrs;

    return $payload;
  }
);

has 'exe' => (
  is      => 'ro',
  isa     => 'CodeRef',
  traits  => ['Code'],
  lazy    => 1,
  default => sub {
    sub { shift->nios_client->create_host_record(@_); }
  },
  handles => {
    call => 'execute'
  }
);

sub run {
  shift->execute;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::nioscli::Commands::create_host_record

=head1 VERSION

version 0.001

=head1 OVERVIEW

Create a HOST record

B<Examples>

=over

=item * Create a HOST record with extattrs

    nioscli create-host-record \
        --name foo.bar \
        --address 10.0.0.1 \
        --address 10.0.0.2 \
        --extattrs '{
            "Cloud API Owned" : { "value" : "True" },
            "Tenant ID" : { "value" : "foo" },
            "CMP Type" : { "value" : "bar" }
        }' [long options...]

=back

=head1 AUTHOR

Christian Segundo <ssmn@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2021 by Christian Segundo.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
