package AutoSQL::DBSQL::DBAdaptor;
use strict;
use AutoCode::Root;
our @ISA=qw(AutoCode::Root);
use AutoSQL::DBSQL::DBContext;
use AutoCode::AccessorMaker ('$' => [qw(factory dbcontext)]);

sub _initialize {
    my ($self, @args)=@_;
    $self->SUPER::_initialize(@args);
    $self->{_object_adaptors} = {};
    my ($factory, $dbcontext)=$self->_rearrange([qw(FACTORY DBCONTEXT)], @args);
    
    defined $factory or $self->throw("Factory is compulsory");
    $self->factory($factory);
    
    unless(defined $dbcontext){
        $dbcontext = AutoSQL::DBSQL::DBContext->new(@args);
    }
    $self->dbcontext($dbcontext);
}

sub add_object_adaptor {
    my ($self, $type, $adaptor)=@_;
    unless(defined $adaptor){
        $adaptor = $self->factory->get_object_adaptor_instance($type, $self);
        # make_object_adaptor($type);
    }
    if(ref($adaptor)){
        $self->throw('not of ObjectAdaptor')
            unless $adaptor->isa('AutoSQL::DBSQL::ObjectAdaptor');
        $adaptor->factory($self->factory) unless defined $adaptor->factory;
    }else{
        
        eval{$self->_load_module($adaptor);};
        if($@){
            $self->throw("Failed to load: $adaptor\n$@");
        }
        $adaptor=$adaptor->new(
            -dba=>$self,
            -factory => $self->factory,
            -type => $type
        );
    }
    $self->{_object_adaptors}->{$type} = $adaptor;
}

sub get_object_adaptor {
    my ($self, $type)=@_;
    $self->throw("[$type] adaptor cannot be found")
        unless exists $self->{_object_adaptors}->{$type};
    return $self->{_object_adaptors}->{$type};
}

sub get_all_adaptor_type {
    my $self=shift;
    return keys %{$self->{_object_adaptors}};
}

sub db_handle {
    shift->dbcontext->db_handle;
}

sub prepare {
    shift->dbcontext->prepare(@_);
}

1;
__END__

=head1 NAME

AutoSQL::DBSQL::DBAdaptor,
the marshal adaptor in charge of all object adaptors

=head1 DESCRIPTION

=cut

