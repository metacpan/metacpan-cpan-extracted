package CPAN::Mini::Inject::REST::Model::CMI;

use Moose;
use CPAN::Mini::Inject;

BEGIN { extends 'Catalyst::Model'; }

sub COMPONENT {
    my ($class, $c, $args) = @_;
    
    $args = $class->merge_config_hashes($class->config, $args);
    return CPAN::Mini::Inject->new->loadcfg($args->{config_file})->parsecfg;
}

1;
