package BPM::Engine::Store::Result::ProcessInstanceAttribute;
BEGIN {
    $BPM::Engine::Store::Result::ProcessInstanceAttribute::VERSION   = '0.01';
    $BPM::Engine::Store::Result::ProcessInstanceAttribute::AUTHORITY = 'cpan:SITETECH';
    }

use namespace::autoclean;
use Moose;
use BPM::Engine::Exceptions qw/throw_abstract/;
extends qw/BPM::Engine::Store::Result/;

__PACKAGE__->load_components(qw/InflateColumn::Serializer/);
__PACKAGE__->table('wfe_process_instance_attr');
__PACKAGE__->add_columns(
    process_instance_id => {
        data_type         => 'INT',
        is_nullable       => 0,
        size              => 11,
        is_foreign_key    => 1,
        extras            => { unsigned => 1 },
        },
    name => {
        data_type         => 'VARCHAR',
        size              => 64,
        is_nullable       => 0,
        },
    scope => {
        data_type         => 'ENUM',
        is_nullable       => 0,
        default           => 'fields',
        default_value     => 'fields', # sqlite
        extra             => { list => [qw/container fields params/] },
        },
    mode => {
        data_type         => 'ENUM',
        is_nullable       => 0,
        default           => 'INOUT',
        default_value     => 'INOUT',
        extra             => { list => [qw/IN OUT INOUT/] },
        },
    type => {        
        data_type         => 'ENUM',
        is_nullable       => 0,
        default           => 'BasicType',
        default_value     => 'BasicType',
        extra             => { list => [qw/BasicType SchemaType/] },
        },
    type_attr => {
        data_type         => 'TEXT',
        is_nullable       => 1,
        serializer_class  => 'JSON',
        },
    is_readonly => {
        data_type         => 'BOOLEAN', # synonym for TINYINT(1)
        default_value     => 0,
        is_nullable       => 1,
        extras            => { unsigned => 1 },
        },
    is_array => {
        data_type         => 'BOOLEAN', # synonym for TINYINT(1)
        default_value     => 0,
        is_nullable       => 1,
        extras            => { unsigned => 1 },
        },
    is_correlation => {
        data_type         => 'BOOLEAN', # synonym for TINYINT(1)
        default_value     => 0,
        is_nullable       => 1,
        extras            => { unsigned => 1 },
        },
    'length'  => {
        data_type         => 'INT',
        is_nullable       => 1,
        size              => 6,
        extras            => { unsigned => 1 },
        },
    value => {
        accessor          => '_value',
        data_type         => 'TEXT',
        is_nullable       => 1,
        serializer_class  => 'JSON',
        is_serializable   => 1,
        },
    );

__PACKAGE__->set_primary_key(qw/ process_instance_id name /);

__PACKAGE__->belongs_to(
    process_instance => 'BPM::Engine::Store::Result::ProcessInstance',
    'process_instance_id'
    );

sub new {
    my ($class, $attrs) = @_;

    #confess("Attribute 'name' missing") unless $attrs->{name};
    $attrs->{mode} ||= 'INOUT';
    $attrs->{type} ||= 'BasicType';

    return $class->next::method($attrs);
    }

sub validate {
    my ($self, $value) = @_;
    
    throw_abstract error => 'BlockActivity not implemented yet';
    }

sub value {
    my ($self, $newvalue) = @_;

    if($newvalue) {
        my $name = $self->name;
        die("Attribute '$name' is read-only") if($self->is_readonly);
        die("Attribute value $newvalue should be a reference") 
            unless(ref($newvalue));
        return $self->_value($newvalue);
        }

    my $value = $self->_value;
    return ($self->type eq 'BasicType' && !$self->is_array) ? 
        $value->[0] : $value;
    }

__PACKAGE__->meta->make_immutable( inline_constructor => 0 );

1;
__END__