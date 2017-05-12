package AutoCode::ModuleFactory;
use strict;
use AutoCode::Root;
our @ISA=qw(AutoCode::Root);
use AutoCode::ModuleModel;
# use AutoCode::Initializer;
use AutoCode::Plurality;

use AutoCode::AccessorMaker('$'=>[qw(schema package_prefix)]);

use AutoCode::Compare;

sub _initialize {
    my ($self, @args)=@_;

    my ($schema, $package_prefix)=
        $self->_rearrange([qw(SCHEMA PACKAGE_PREFIX)], @args);
    defined $schema or $self->throw("NO Schema set");
    $self->schema($schema);
    $package_prefix ||= $schema->package_prefix;
    $package_prefix ||= 'AutoCode';
    $self->package_prefix($package_prefix);
}

# *make_virtual_module = \&make_module;

sub make_module {
    my ($self, $type, $isa) =@_;
    ## this is added due to AutoSQL::ModuleFactory
    $isa='AutoCode::Root' unless defined $isa; 
    my $schema=$self->schema;
    my $package_prefix=$self->package_prefix;
    my $vp = $self->_get_virtual_package($type);
    
    my $model = $schema->get_module_model($type);
    # generate its parents modules if any.
    my @isa=$model->get_isas($type);
    if(@isa){
        no strict 'refs';
        foreach(@isa){
            push @{"$vp\::ISA"}, $self->make_module($_);
        }   
    }

    # virtual package is with the consideration of schema name and type.    
    my $vp = $self->_get_virtual_package($type);
    no strict 'refs';                                         
    push @{"$vp\::ISA"}, $isa unless grep /^$isa$/, @{"$vp\::ISA"};                     
#    $self->_add_scalar_accessor(@scalar_accessors);           
    $self->debug("making $type in $vp");
    
#    map {*{"$vp\::$_"} = \&{__PACKAGE__."::$_"}} @scalar_accessors;         
    map {AutoCode::AccessorMaker->make_scalar_accessor($_, $vp);} 
        $model->get_scalar_attributes;
    map {AutoCode::AccessorMaker->make_array_accessor(
        [$_, $schema->get_plural($_)], $vp);
    } $model->get_array_attributes;
    $self->_make_initialize($type, $vp);
    $self->_make_friends($type, $vp);
    return $vp;
}


sub _make_initialize {
    my ($self, $type, $pkg)=@_;
    my $schema = $self->schema;
    my $package_prefix=$self->package_prefix;
    my $model = $self->schema->get_module_model($type);
    my $pkg=$self->_get_virtual_package($type);
    AutoCode::AccessorMaker->make_initialize_by_model($model, $pkg);
}

sub _make_friends {
    my ($self, $type, $pkg)=@_;
    my $schema = $self->schema;
    my @friends=$schema->find_friends($type);
    foreach my $friend_nickname (@friends){
#        print STDERR "$_ as a friend\n\L$_\n";
        AutoCode::AccessorMaker->make_hash_accessor("$friend_nickname", $pkg);
        $self->_make_friend_add($type, $friend_nickname, $pkg);
            
    }
}

sub _make_friend_add {
    my ($self, $my_nickname, $friend_nickname, $pkg)=@_;
    
    my $glob="$pkg\::get_". AutoCode::Plurality->query_plural($friend_nickname);
    $glob="$pkg\::add_$friend_nickname";
    my $slot="$pkg\::$friend_nickname\_\%";
    no strict 'refs';
    *$glob=sub{
        my ($self, $friend, $extra)=@_;
        return unless defined $friend;
        $self->{$slot}={} unless exists $self->{$slot};
        $self->{$slot}->{$friend}=$extra;
        # add itself to its friend as friend.
        my $method="get_". AutoCode::Plurality->query_plural($my_nickname);
        my %hash=$friend->$method(); 
        unless(grep {AutoCode::Compare->equal($_, "$self")} keys %hash){
            my $my_method="add_$my_nickname";
            $friend->$my_method($self, $extra);
        }
    };
}

sub _get_virtual_package {
    my ($self, $type)=@_;
    my $package_prefix=$self->package_prefix;
    return "$package_prefix\::Virtual::$type"; # 'virtual package'
}

1;
