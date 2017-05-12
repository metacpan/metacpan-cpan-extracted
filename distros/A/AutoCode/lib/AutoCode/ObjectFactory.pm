package AutoCode::ObjectFactory;
use strict;
use AutoCode::ModuleFactory;
# use AutoCode::Object;
our @ISA=qw(AutoCode::ModuleFactory);


sub get_instance {
    my ($self, $type, @args)=@_;
    my $module = $self->schema->get_module_definition($type);
    my %module =%$module;
    my @subs = grep /^[_a-zA-Z]/, keys %module;
    my @decls= grep /^\~/, keys %module;
    my @scalar_accessors = grep /^\$/, @subs;
    my @array_accessors  = grep /^\@/, @subs;

    my $virtual_package = $self->make_virtual_module($type);
    # The package and constructor are fixed as 'AutoSQL::Object' and 'new'
    my $instance;

    $instance = $virtual_package->new(@args);
=item
    this is wrongdoing, since the scalar_accessors and array_accessors will 
    be placed under AutoSQL::Object typeglob
    
    $instance = AutoSQL::Object->new(
        -scalar_accessors => \@scalar_accessors,
        -array_accessors => \@array_accessors,
        -factory => $self,
        -type => $type,
        @args);
=cut

    # Cache it, by $type and digest of @args.
    # Implement it later.
    
    
    return $instance;
}

1;

