# ============================================================================
package CatalystX::I18N::Role::Maketext;
# ============================================================================

use namespace::autoclean;
use Moose::Role;

sub maketext {
    my ($c,$msgid,@args) = @_;
    
    my @args_expand;
    foreach my $arg (@args) {
        push @args_expand,
            (ref $arg eq 'ARRAY') ? @$arg : $arg;
    }
    
    # TODO: Check if Maketext model is available
    my $handle = $c->model('Maketext');
    my $msgstr = $handle->maketext( $msgid, @args_expand );
    
    return $msgstr
        if defined $msgstr;
    
    # Method expansion
    my $replacesub = sub {
        my $method = shift;
        my @params = split(/,/,shift);
        if ($handle->can($method)) {
            return $handle->$method(@params);
        }
        return $method;
    };
    
    # TODO: use gettext/maketext style
    $msgstr = $msgid;
    $msgstr =~s{%(\d+)}{ $args[$1-1] || 'missing value %'.$1 }eg;
    $msgstr =~s/%(\w+)\(([^)]+)\)/$replacesub->($1,$2)/eg;
    
    return $msgstr;
}

no Moose::Role;
1;

=encoding utf8

=head1 NAME

CatalystX::I18N::Role::Maketext - Support for maketext

=head1 SYNOPSIS

 # In your catalyst base class
 package MyApp::Catalyst;
 
 use Catalyst qw/MyPlugins 
    CatalystX::I18N::Role::Base
    CatalystX::I18N::Role::Maketext/;

 # Maketext model class
 package MyApp::Model::Maketext;
 use parent qw/CatalystX::I18N::Model::Maketext/;

 # Create a Maketext class (must be a Locale::Maketext class)
 package MyApp::Maketext;
 use parent qw/CatalystX::I18N::Maketext/;

 # In your controller class(es)
 package MyApp::Catalyst::Controller::Main;
 use strict;
 use warnings;
 use parent qw/Catalyst::Controller/;
 
 sub action : Local {
     my ($self,$c) = @_;
     
     $c->stash->{results} = $c->maketext('Your search found %quant(%1,result,results)',$count);
 }

=head1 DESCRIPTION

This role adds support for L<Locale::Maketext> localisation via the
L<CatalystX::I18N::Model::Maketext> model. 

In order to work properly this role needs a model called C<Maketext>. A call
to C<$c-E<gt>model('Maketext')> should return a handle for a Maketext / 
L<Locale::Maketext> class. You can either write your own Model and Maketext 
class or use L<CatalystX::I18N::Model::Maketext> and 
L<CatalystX::I18N::Maketext>.

=head1 METHODS

=head3 maketext

 my $translated_string = $c->maketext($msgid,@params);
 OR
 my $translated_string = $c->maketext($msgid,\@params);

Translates a string via L<Locale::Maketext>. 

=head1 SEE ALSO

L<Locale::Maketext>, L<CatalystX::I18N::Model::Maketext> 
and L<CatalystX::I18N::Maketext>

=head1 AUTHOR

    Maroš Kollár
    CPAN ID: MAROS
    maros [at] k-1.com
    
    L<http://www.k-1.com>