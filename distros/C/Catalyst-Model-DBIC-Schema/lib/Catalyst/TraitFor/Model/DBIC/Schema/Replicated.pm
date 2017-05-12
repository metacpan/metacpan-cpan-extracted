package Catalyst::TraitFor::Model::DBIC::Schema::Replicated;

## WARNING WARNING WARNING WARNING WARNING WARNING WARNING WARNING
## If you make changes to this code and don't actually go and test it
## on a real replicated environment I will rip you an new hole.  The
## test suite DOES NOT properly test this.  --JNAP

use namespace::autoclean;
use Moose::Role;
use Carp::Clan '^Catalyst::Model::DBIC::Schema';

use Catalyst::Model::DBIC::Schema::Types qw/ConnectInfos LoadedClass/;
use MooseX::Types::Moose qw/Str HashRef/;

use Module::Runtime;

=head1 NAME

Catalyst::TraitFor::Model::DBIC::Schema::Replicated - Replicated storage support for
L<Catalyst::Model::DBIC::Schema>

=head1 SYNOPSiS

    __PACKAGE__->config({
        traits => ['Replicated']
        connect_info =>
            ['dbi:mysql:master', 'user', 'pass'],
        replicants => [
            ['dbi:mysql:slave1', 'user', 'pass'],
            ['dbi:mysql:slave2', 'user', 'pass'],
            ['dbi:mysql:slave3', 'user', 'pass'],
        ],
        balancer_args => {
          master_read_weight => 0.3
        }
    });

=head1 DESCRIPTION

Sets your storage_type to L<DBIx::Class::Storage::DBI::Replicated> and connects
replicants provided in config. See that module for supported resultset
attributes.

The default L<DBIx::Class::Storage::DBI::Replicated/balancer_type> is
C<::Random>.

Sets the
L<DBIx::Class::Storage::DBI::Replicated::Balancer::Random/master_read_weight> to
C<1> by default, meaning that you have the same chance of reading from master as
you do from replicants. Set to C<0> to turn off reads from master.

=head1 CONFIG PARAMETERS

=head2 replicants

Array of connect_info settings for every replicant.

The following can be set via L<Catalyst::Model::DBIC::Schema/connect_info>, or
as their own parameters. If set via separate parameters, they will override the
settings in C<connect_info>.

=head2 pool_type

See L<DBIx::Class::Storage::DBI::Replicated/pool_type>.

=head2 pool_args

See L<DBIx::Class::Storage::DBI::Replicated/pool_args>.

=head2 balancer_type

See L<DBIx::Class::Storage::DBI::Replicated/balancer_type>.

=head2 balancer_args

See L<DBIx::Class::Storage::DBI::Replicated/balancer_args>.

=cut

has replicants => (
    is => 'ro', isa => ConnectInfos, coerce => 1, required => 1
);

# If you change LoadedClass with LoadableClass I will rip you a new hole,
# it doesn't work exactly the same - JNAP

has pool_type => (is => 'ro', isa => LoadedClass);
has pool_args => (is => 'ro', isa => HashRef);
has balancer_type => (is => 'ro', isa => Str);
has balancer_args => (is => 'ro', isa => HashRef);

after setup => sub {
    my $self = shift;

# check storage_type compatibility (if configured)
    if (my $storage_type = $self->storage_type) {
        my $class = $storage_type =~ /^::/ ?
            "DBIx::Class::Storage$storage_type"
            : $storage_type;

            # For some odd reason if you try to use 'use_module' as an export
            # the code breaks.  I guess something odd about MR and all these
            # runtime loaded crazy trait code.  Please don't "tidy the code up" -JNAP
            Module::Runtime::use_module($class);

        croak "This storage_type cannot be used with replication"
            unless $class->isa('DBIx::Class::Storage::DBI::Replicated');
    } else {
        $self->storage_type('::DBI::Replicated');
    }

    my $connect_info = $self->connect_info;

    $connect_info->{pool_type} = $self->pool_type
        if $self->pool_type;

    $connect_info->{pool_args} = $self->pool_args
        if $self->pool_args;

    $connect_info->{balancer_type} = $self->balancer_type ||
        $connect_info->{balancer_type} || '::Random';

    $connect_info->{balancer_args} = $self->balancer_args ||
        $connect_info->{balancer_args} || {};

    $connect_info->{balancer_args}{master_read_weight} = 1
        unless exists $connect_info->{balancer_args}{master_read_weight};
};

sub BUILD {}

after BUILD => sub {
    my $self = shift;

    $self->storage->connect_replicants(map [ $_ ], @{ $self->replicants });
};

=head1 SEE ALSO

L<Catalyst::Model::DBIC::Schema>, L<DBIx::Class>,
L<DBIx::Class::Storage::DBI::Replicated>,
L<Catalyst::TraitFor::Model::DBIC::Schema::Caching>

=head1 AUTHOR

See L<Catalyst::Model::DBIC::Schema/AUTHOR> and
L<Catalyst::Model::DBIC::Schema/CONTRIBUTORS>.

=head1 COPYRIGHT

See L<Catalyst::Model::DBIC::Schema/COPYRIGHT>.

=head1 LICENSE

This program is free software, you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
