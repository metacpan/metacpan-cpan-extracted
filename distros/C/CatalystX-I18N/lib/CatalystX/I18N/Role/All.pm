# ============================================================================
package CatalystX::I18N::Role::All;
# ============================================================================

use namespace::autoclean;
use Moose::Role;
requires qw(response_class request_class);

with qw(
    CatalystX::I18N::Role::Base
    CatalystX::I18N::Role::DateTime
    CatalystX::I18N::Role::Maketext
    CatalystX::I18N::Role::GetLocale
    CatalystX::I18N::Role::NumberFormat
    CatalystX::I18N::Role::Collate
);
# CatalystX::I18N::Role::PosixLocale

before 'setup' => sub {
    my ($class) = @_;
    
    for my $type (qw(Response Request)) {
        my $accessor_method = lc($type).'_class';
        my $super_class = $class->$accessor_method();
        
        # Get role
        my $role_class = 'CatalystX::I18N::TraitFor::'.$type;
        Class::Load::load_class($role_class);
        
        # Check if role has already been applied
        next
            if grep { $_->meta->does_role($role_class) } $super_class->meta->linearized_isa;
        
        # Build anon class with our roles
        my $meta = Moose::Meta::Class->create_anon_class(
            superclasses => [$super_class],
            roles        => [$role_class],
            cache        => 1,
        );
        
        $class->$accessor_method($meta->name);
    }
};

around 'setup_component' => sub {
    my $orig  = shift;
    my ($class,$component) = @_;
    
    Class::Load::load_class($component);
    
    # Load View::TT role
    if ($component->isa('Catalyst::View::TT')
        && $component->can('meta')) {
        my $component_meta = $component->meta;
        unless ($component_meta->does_role('CatalystX::I18N::TraitFor::ViewTT')) {
            if ($component_meta->is_mutable) {
                Moose::Util::apply_all_roles($component_meta, 'CatalystX::I18N::TraitFor::ViewTT')
            }
        }
    }
    
    return $class->$orig($component);
};

no Moose::Role;
1;

=encoding utf8

=head1 NAME

CatalystX::I18N::Role::All - Load all available roles

=head1 SYNOPSIS

 package MyApp::Catalyst;
 
 use Catalyst qw/MyPlugins 
    CatalystX::I18N::Role::All/;

=head1 DESCRIPTION

This role is just a shortcut for loading every I18N role and trait (except POSIX)
individually.

 use Catalyst qw/CatalystX::I18N::Role::All/;

Is same as

 use Catalyst qw/
     +CatalystX::I18N::Role::Base
     +CatalystX::I18N::Role::GetLocale
     +CatalystX::I18N::Role::DateTime
     +CatalystX::I18N::Role::Maketext
     +CatalystX::I18N::Role::Collate
     +CatalystX::I18N::Role::NumberFormat
 /;
 
 use CatalystX::RoleApplicator;
 __PACKAGE__->apply_request_class_roles(qw/CatalystX::I18N::TraitFor::Request/);
 __PACKAGE__->apply_response_class_roles(qw/CatalystX::I18N::TraitFor::Response/);

=head1 AUTHOR

    Maroš Kollár
    CPAN ID: MAROS
    maros [at] k-1.com
    
    L<http://www.k-1.com>
