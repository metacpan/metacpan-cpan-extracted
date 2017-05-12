# ============================================================================
package CatalystX::I18N::TraitFor::Response;
# ============================================================================

use namespace::autoclean;
use Moose::Role;
requires qw(headers);

sub content_language {
    my ($self,@languages) = @_;
    
    if (scalar @languages) {
        my $language = join(', ',@languages);
        return $self->headers->header( 'Content-Language' => $language );
    } else {
        return $self->header->header( 'Content-Language' );
    }
}

no Moose::Role;
1;

=encoding utf8

=head1 NAME

CatalystX::I18N::TraitFor::Response - Adds the Content-Language header to the Catalyst::Response object

=head1 SYNOPSIS

 package MyApp::Catalyst;
 
 use CatalystX::RoleApplicator;
 use Catalyst qw/MyPlugins 
    CatalystX::I18N::Role::Base/;
 
 __PACKAGE__->apply_response_class_roles(qw/CatalystX::I18N::TraitFor::Response/);

=head1 DESCRIPTION

This role simply adds the 'Content-Language' header to your response.

=head1 METHODS

=head3 content_language

 $c->response->content_language('de_AT','en');

Accepts a list of languages. This header will be automatically set
if you use it in conjunction with the L<CatalystX::I18N::Role::Base> role.

=head1 SEE ALSO

L<Catalyst::Respone>

=head1 AUTHOR

    Maroš Kollár
    CPAN ID: MAROS
    maros [at] k-1.com
    
    L<http://www.k-1.com>
