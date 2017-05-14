package AutoSQL::AdaptorFactory;
use strict;
use AutoSQL::DBModuleFactory;
our @ISA=qw(AutoSQL::DBModuleFactory);
use AutoSQL::DBSQL::DBAdaptor;
use AutoSQL::DBSQL::ObjectAdaptor;
use AutoSQL::DBObject;

sub _initialize {
    my ($self, @args)=@_;
    $self->SUPER::_initialize(@args);
    $self->throw("AdaptorFactory accepts AutoSQL::Schema only, so far")
        unless $self->schema->isa('AutoSQL::Schema');
}

sub get_adaptor_instance {
    my ($self, @args)=@_;
    push @args, -factory => $self;
    my $dba = AutoSQL::DBSQL::DBAdaptor->new(@args);
    foreach my $type ($self->schema->get_all_types){
        $dba->add_object_adaptor($type, 
            $self->get_object_adaptor_instance($type, $dba));
    }
    return $dba;
}

sub get_object_adaptor_instance {
    my ($self, $type, $dba)=@_;
    my $vp = $self->make_object_adaptor($type); 
    my $object_adaptor = $vp->new(
        -dba => $dba,
        -factory => $self, # I do not use it yet
        -model => $self->schema->get_table_model($type)
    );
    return $object_adaptor;
}

our %OBJECT_ADAPTORS;
sub make_object_adaptor {
    my ($self, $type) =@_;
    return $OBJECT_ADAPTORS{$type} if exists $OBJECT_ADAPTORS{$type};
    my $schema=$self->schema;
    my $model=$schema->get_table_model($type);
    
    my $vp = $self->_get_object_adaptor_package($type);
    no strict 'refs';
    push @{"$vp\::ISA"}, 'AutoSQL::DBSQL::ObjectAdaptor'
        unless grep /^AutoSQL::DBSQL::ObjectAdaptor$/, @{"$vp\::ISA"};
#    $self->_make_table_name_method($vp, $model->table_name);
#    $self->_make_slots_method($vp, $model->slots);
    print __PACKAGE__ ." : no customized table_name method made\n";
    $self->_make_only_fetch_methods($model);
    $OBJECT_ADAPTORS{$type} = $vp;
#    print "$vp\n";
    return $vp;
}

sub _get_object_adaptor_package {
    my ($self, $type)=@_;
    my $package_prefix=$self->package_prefix;
    "$package_prefix\::Virtual::DBSQL::${type}Adaptor";
}

sub _make_table_name_method {
    my ($self, $vp, $table_name)=@_;
    no strict 'refs';
    *{"$vp\::_table_name"} = sub { return $table_name; };
}

sub _make_slots_method {
    my ($self, $vp, @args)=@_;
    my @slots;
    push @slots, ((ref($args[0])eq'ARRAY')?@{$args[0]}:@args);
    no strict 'refs';
    *{"$vp\::_slots"} = sub { return @slots; };   
}

sub _make_only_fetch_methods {
    my ($self, $model)=@_;
    my $type = $model->type;
    my $vp = $self->_get_object_adaptor_package($type);
    no strict 'refs';
    foreach my $scalar_slot ($model->get_scalar_slots){
        *{"$vp\::only_fetch_$scalar_slot\_by_dbID"}=sub {
            my ($self, $dbid)=@_;
            my $where = $self->_primary_key_name .' = ?';
            ($self->_only_fetch_by_where($scalar_slot, $where, [$dbid]))[0];
        };
    }
    foreach my $slot ($model->get_array_slots){
        *{"$vp\::only_fetch_$slot\_by_dbID"}=sub{
            undef;
        };
    }
}

1;
