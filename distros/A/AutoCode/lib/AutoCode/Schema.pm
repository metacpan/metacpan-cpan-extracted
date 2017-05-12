package AutoCode::Schema;
use strict;
use vars qw(@ISA);
use AutoCode::Root;
our @ISA=qw(AutoCode::Root);
our %PLURALS;
use AutoCode::ModuleModel;
use AutoCode::AccessorMaker(
    '$'=>[qw(plurals modules package_prefix)], 
    '@'=>[qw(friendship)]
);
use AutoCode::Friendship;

use AutoCode::Plurality;

sub _initialize {
    my ($self, @args)=@_;
    $self->SUPER::_initialize(@args);
    
    my ($modules, $package_prefix, $plurals, $modules_type_grouped)=
        $self->_rearrange(
            [qw(MODULES PACKAGE_PREFIX PLURALS modules_type_grouped)], @args);
    
    (ref($modules) eq 'HASH') and $self->modules($modules);
    if(defined $modules_type_grouped){
#        print STDERR "FOUND modules_type_grouped\n";
        $modules= {} unless defined $modules;
        $self->throw('modules_type_grouped must be a hash ref')
            unless ref($modules_type_grouped) eq 'HASH';
        foreach my $module_name(keys %$modules_type_grouped){
            $self->throw("one key '$module_name' in modules_type_grouped has been defined\nCURRENT KEYS:\t". join("\t", keys %$modules))
                if exists $modules->{$module_name};
            my $module_type_grouped = $modules_type_grouped->{$module_name};
            my %module;
            foreach my $field_type (keys %$module_type_grouped){
                foreach (@{$module_type_grouped->{$field_type}}){
                $module{$_}= $field_type;
                }
            }
            $modules->{$module_name}= \%module;
        }
        $self->modules($modules);
    }
    
    our $FRIENDSHIP_TYPE='~friends';
    if(exists $modules->{$FRIENDSHIP_TYPE}){
        my $friends=$modules->{$FRIENDSHIP_TYPE};
        delete $modules->{$FRIENDSHIP_TYPE};
        foreach my $friend(keys %$friends){
            my @peers=split /-/, $friend;
            my $extras=$friends->{$friend};
            $extras=~ s/;$//;
            my @extras=split /;/, $extras;
            my $friendship = AutoCode::Friendship->new(
                -peer_string => $friend,
                -peers => \@peers,
                -extras => \@extras
            );
            $self->add_friendship($friendship);
        }
    }

    $self->package_prefix($package_prefix);
    $self->plurals({});
    if(defined $plurals){
        if(ref($plurals) eq 'HASH'){
            # not directly assign to the package variable, avoiding overwrite
            $self->plurals($plurals);
            foreach (keys %$plurals){
                AutoCode::Plurality->add_plural($_, $plurals->{$_});
            }
        }else{
            $self->throw("plurals must be a hash reference");
        }
    } # else{ %PLURALS=();} wrongly to initialize the package variable.

}

# Only be invoked by ModuleModel.
# 
sub _get_module_definition {
    my ($self, $type)=@_;
    $self->_check_type($type);
    return $self->modules->{$type};
}

sub get_all_types {
    my $self=shift;
    return grep !/^\W/, keys %{$self->modules};
}

sub get_friends {
    my $friends=shift->modules->{'~friends'};
    return (defined $friends)? @$friends : [];
}

sub dependence {
    my $self=shift;
    my %dependance=();
    my %modules=%{$self->modules};
    my @types = keys %modules;
    foreach my $type(@types){
        my $module = $self->get_module_model($type);
        foreach my $tag ($module->get_all_value_attributes){
            my ($context, $kind, $content, $required) =
                $module->_classify_value_attribute($tag);
            if($kind eq 'M'){
                $dependance{$type} = {} unless exists $dependance{$type};
                $dependance{$type}->{$content} = [$context, $tag];
            }
        }
    }

    return %dependance;
}

sub find_friends {
    my ($self, $module)=@_;
    $module = ref($module) || $module;
    my @friends; # to return
    my @friendship=$self->get_friendships;
    foreach my $friendship ($self->get_friendships){
        if(grep /^$module$/, $friendship->get_peers){
            push @friends, grep !/^$module$/, $friendship->get_peers;
        }
    }
    return @friends;
}

sub has_a {
    my ($self, $type)=@_;
    my %dependence = $self->dependence;
    return ${$dependence{$type}};
}

sub fks {
    my ($self)=@_;
    my %has_a=$self->dependence;
    my %fks;
    foreach my $type(keys %has_a){
        my %type=%{$has_a{$type}};
        foreach(keys %type){
            $fks{$_}={} unless exists $fks{$_};
            $fks{$_}->{$type}=$type{$_};
        }
    }
    return %fks;
}

our %MODULE_MODELS;
sub get_module_model {
    my ($self, $type)=@_;
    return $MODULE_MODELS{$type} if exists $MODULE_MODELS{$type};
    my $model=AutoCode::ModuleModel->new(
        -schema => $self,
        -type => $type
    );
    $MODULE_MODELS{$type} = $model;
    return $model;
}

sub _check_type {
    my ($self, $type)=@_;
    $self->throw("[$type] does not exist in the schema")
        unless exists $self->modules->{$type};
}

sub get_plural {
    my ($self, $singular)=@_;
    my $plurals=$self->plurals;
    return (exists $plurals->{$singular})?$plurals->{$singular}:"${singular}s";
}

sub ref_plural {
    my ($self, $singular)=@_;
    return [$singular, $self->get_plural($singular)];
}

1;
