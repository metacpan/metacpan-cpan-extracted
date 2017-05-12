# ============================================================================
package CatalystX::I18N::Model::DataLocalize;
# ============================================================================

use namespace::autoclean;
use Moose;
extends 'CatalystX::I18N::Model::Base';

has 'data_localize' => (
    is          => 'rw', 
    isa         => 'Data::Localize',
    lazy_build  => 1,
);

sub _build_data_localize {
    my ($self) = @_;
    
    # Get DataLocalize class
    my $class = $self->class || $self->_app .'::DataLocalize';
    
    # Load DataLocalize class
    my ($ok,$error) = Class::Load::try_load_class($class);
    Catalyst::Exception->throw(sprintf("Could not load '%s' : %s",$class,$error))
        unless $ok;
    
    Catalyst::Exception->throw(sprintf("Could initialize '%s' because is is not a 'Data::Localize' class",$class))
        unless $class->isa('Data::Localize');
    
    return $class->new();
}

sub BUILD {
    my ($self) = @_;
    
    my $loc = $self->data_localize;
    my $app = $self->_app;
    
    # Add localizers if possible
    if ($loc->can('add_localizers')) {
        my (@locales,$config);
        $config = $app->config->{I18N}{locales};
        @locales = keys %$config;
        $app->log->debug(sprintf("Adding localizers for locales %s",join(',',@locales)))
            if $app->debug;
        $loc->add_localizers( 
            locales             => \@locales, 
            directories         => $self->directories,
        );
    } else {
        $app->log->warn(sprintf("'%s' does not implement a 'add_localizers' method",ref($loc)))
    }
    
    $self->data_localize($loc);
    return;
}

sub ACCEPT_CONTEXT {
    my ( $self, $c ) = @_;
    
    my @languages = ($c->locale);
    push(@languages,@{$c->i18n_config->{_inherits}});
    
    # set locale and inheritance
    $self->data_localize->set_languages(@languages);
    
    return $self->data_localize;
}

__PACKAGE__->meta->make_immutable( inline_constructor => 0 );
no Moose;
1;