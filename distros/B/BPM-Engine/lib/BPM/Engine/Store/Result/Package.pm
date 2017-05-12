package BPM::Engine::Store::Result::Package;
BEGIN {
    $BPM::Engine::Store::Result::Package::VERSION   = '0.01';
    $BPM::Engine::Store::Result::Package::AUTHORITY = 'cpan:SITETECH';
    }

use strict;
use warnings;
use base qw/DBIx::Class::Core/;

__PACKAGE__->load_components(qw/ InflateColumn::Serializer UUIDColumns Core /);
__PACKAGE__->table('wfd_package');
__PACKAGE__->add_columns(
    package_id => {
        data_type         => 'CHAR',
        size              => 36,
        #data_type         => 'VARBINARY',
        #size              => 16,
        is_nullable       => 0,
        default_value     => 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx',
        },    
    package_uid => {
        data_type         => 'VARCHAR',
        size              => 64,
        is_nullable       => 1,
        },
    package_name => {
        data_type         => 'VARCHAR',
        size              => 255,
        is_nullable       => 1,
        },
    version => {
        data_type         => 'VARCHAR',
        size              => 8,
        is_nullable       => 1,
        },    
    specification => {
        data_type         => 'VARCHAR',
        size              => 20,
        is_nullable       => 1,
        },
    specification_version => {
        data_type         => 'VARCHAR',
        size              => 255,
        is_nullable       => 1,
        },
    graph_conformance => {
        data_type         => 'ENUM',
        is_nullable       => 0,
        default           => 'NON_BLOCKED',
        default_value     => 'NON_BLOCKED', # sqlite
        extra             => { list => [qw/NON_BLOCKED LOOP_BLOCKED FULL_BLOCKED/] },
        },
    script => {
        data_type         => 'VARCHAR',
        size              => 20,
        is_nullable       => 0,
        default_value     => 'text/javascript',
        },
    author => {
        data_type         => 'VARCHAR',
        size              => 255,
        is_nullable       => 1,
        },
    codepage => {
        data_type         => 'VARCHAR',
        size              => 255,
        is_nullable       => 1,
        },
    country_geo => {
        data_type         => 'VARCHAR',
        size              => 20,
        is_nullable       => 1,
        },
    publication_status => {
        data_type         => 'ENUM',
        is_nullable       => 0,
        default           => 'UNDER_REVISION',
        default_value     => 'UNDER_REVISION',  # sqlite       
        extra             => { list => [qw/UNDER_REVISION RELEASED UNDER_TEST/] },
        },
    description => {
        data_type         => 'VARCHAR',
        size              => 255,
        is_nullable       => 1,
        },
    vendor => {
        data_type         => 'VARCHAR',
        size              => 255,
        is_nullable       => 1,
        },
    created => {
        data_type         => 'DATETIME',
        is_nullable       => 1,
        extra             => { timezone => 'UTC' }
        },
    priority_uom => {
        data_type         => 'VARCHAR',
        size              => 20,
        is_nullable       => 1,
        },
    cost_uom => {
        data_type         => 'VARCHAR',
        size              => 20,
        is_nullable       => 1,
        },
    documentation_url => {
        data_type         => 'VARCHAR',
        size              => 255,
        is_nullable       => 1,
        },
    imported_from_url => {
        data_type         => 'VARCHAR',
        size              => 255,
        is_nullable       => 1,
        },
    responsible_list_id => {
        data_type         => 'VARCHAR',
        size              => 20,
        is_nullable       => 1,
        },
    data_fields => {
        data_type         => 'TEXT',
        is_nullable       => 1,
        serializer_class  => 'JSON',
        },
    artifacts => {
        data_type         => 'TEXT',
        is_nullable       => 1,
        serializer_class  => 'JSON',
        },    
    extended_attr => {
        data_type         => 'TEXT',
        is_nullable       => 1,
        serializer_class  => 'JSON',
        },     
    );

__PACKAGE__->set_primary_key('package_id');
__PACKAGE__->uuid_columns('package_id');

__PACKAGE__->has_many(
    processes => 'BPM::Engine::Store::Result::Process','package_id'
    );

__PACKAGE__->has_many(
    participants => 'BPM::Engine::Store::Result::Participant',
    { 'foreign.parent_node' => 'self.package_id' }, 
    { where => { participant_scope => 'Package' } }
    );

#__PACKAGE__->many_to_many( package_transitions => 'processes', 'transitions' );

sub TO_JSON {
    my $self = shift;

    my %parms = map { $_ => $self->$_ } grep { $self->$_ }
        qw/package_name package_uid description version
           author vendor graph_conformance created
          /;
    # processes participants

    return \%parms;
    }


1;
__END__