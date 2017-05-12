package AutoCode::Object;
use strict;
use AutoCode::Root;
our @ISA=qw(AutoCode::Root);

# this method have to be overridden here, since the scalar_getst and 
# array_getset must be assigned before _initialize.
# 
sub new {
    my ($invocant, @args)=@_;
    my $class = ref($invocant) || $invocant;
    my $self={};
    bless $self, $class;
    $self->_initialize(@args);
    return $self;
}

sub _initialize {
    my ($self, @args)=@_;
    $self->SUPER::_initialize(@args);
    
    $self->_add_scalar_accessor('type', 'factory');
    
    my ($type, $factory, $scalar_accessors, $array_accessors)=
        $self->_rearrange(
            [qw(TYPE FACTORY SCALAR_ACCESSORS ARRAY_ACCESSORS)], @args);
    (ref($scalar_accessors)eq'ARRAY')
        or $self->throw("SCALAR_ACCESSORS should be a reference to an array");
    $self->_add_scalar_accessor(@$scalar_accessors);
    (ref($array_accessors)eq'ARRAY')
        or $self->throw("ARRAY_ACCESSORS should be a reference to an array");
    $self->_add_array_accessor(@$array_accessors);
    

    defined $type and $self->type($type);
    defined $factory and $self->factory($factory);

    # Now it is magic time to map the @args into accessors
    # First, grep all args' keys that are not intent to be used in this Object,
    # but the specific business objects
    my @reserved = qw(TYPE FACTORY SCALAR_ACCESSORS ARRAY_ACCESSORS);
    my %args = @args;
    my @args_keys = map {s/^\-//; $_} keys %args;
    %args=(); # recycle it.
    while(@args){
        (my $key=shift @args) =~ tr/a-z\055/A-Z/d;
        $args{$key}=shift @args;
    }
#    @args_keys = grep {my $z=$_; (map{$z eq $_}@reserved?():$z)}@args_keys;
    foreach(@args_keys){
        my $v=$args{uc $_};
        print "$_\t\t$v\t|\n";
        $_ = lc $_;
        $self->$_($v) if $self->can($_);
    }
    
}

1;
