package AutoCode::ModuleLoader;
use strict;
use AutoCode::ModuleFactory;
our $SCHEMA;
our $FACTORY;
our %LOADED; # Cache

# In the previous design, the method 'import' can load any specific type. And 
# we forbid the feature, since it cannot return virtual package we want, and 
# the users should not guess/predict what the virtual package is, which is the 
# internal business to decide the VP of this AutoCode.

sub import {
    my $pkg=shift;
    $pkg->load_schema(@_) if @_;
}

sub load_schema {
    my ($pkg, $schema, $prefix)=@_;
    AutoCode::Root->_load_module($schema);
    my @args = (defined $prefix and $prefix ne 'default')
        ? (-package_prefix => $prefix):();
    $SCHEMA= $schema->new(@args);
    $FACTORY=AutoCode::ModuleFactory->new(
        -schema => $SCHEMA
    );
}

# Cache is at work.
sub load {
    my ($pkg, $type, $prefix)=@_;
    return $LOADED{$type} if(exists $LOADED{$type});        
    my $vp = $FACTORY->make_module($type);
    $LOADED{$type}=$vp;
    return $vp;
    
}

sub load_all {
    my ($pkg)=@_;
    my @types=$SCHEMA->get_all_types;
    foreach(@types){
        $pkg->load($_);
    }

}

1;
__END__
=head1 USAGE

    use AutoCode::ModuleLoader 'MySchema', 'Person', 'JuguangWeb::Contact';

=head1 DESCRIPTION

This is a very easy loader to make your virtual module in memory.

=cut

