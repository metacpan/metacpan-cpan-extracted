# ============================================================================
package CatalystX::I18N::Role::DataLocalize;
# ============================================================================

use namespace::autoclean;
use Moose::Role;

sub localize {
    my ($c,$msgid,@args) = @_;
    
    my @args_expand;
    foreach my $arg (@args) {
        push @args_expand,
            (ref $arg eq 'ARRAY') ? @$arg : $arg;
    }
    
    # TODO: Check if DataLocalize model is available
    my $loc = $c->model('DataLocalize');
    my $msgstr = $loc->localize( $msgid, @args_expand );
    
    return $msgstr;
}

no Moose::Role;
1;

=encoding utf8

=head1 NAME

CatalystX::I18N::Role::DataLocalize - Support for localize

=head1 SYNOPSIS

 # In your catalyst base class
 package MyApp::Catalyst;
 
 use Catalyst qw/MyPlugins 
    CatalystX::I18N::Role::Base
    CatalystX::I18N::Role::DataLocalize/;

 # Maketext model class
 package MyApp::Model::DataLocalize;
 use parent qw/CatalystX::I18N::Model::DataLocalize/;

 # Create a Maketext class (must be a Data::Localize class)
 package MyApp::Maketext;
 use parent qw/CatalystX::I18N::DataLocalize/;

 # In your controller class(es)
 package MyApp::Catalyst::Controller::Main;
 use strict;
 use warnings;
 use parent qw/Catalyst::Controller/;
 
 sub action : Local {
     my ($self,$c) = @_;
     
     $c->stash->{results} = $c->localize('Your search found %quant(%1,result,results)',$count);
 }

=head1 DESCRIPTION

This role adds support for L<Data::Localize> localisation via the
L<CatalystX::I18N::Model::DataLocalize> model. 

In order to work properly this role needs a model called C<DataLocalize>. A 
call to C<$c-E<gt>model('DataLocalize')> should return a L<Data::Localize> 
object. You can either write your own Model and use L<Data::Localize> directly
or use L<CatalystX::I18N::Model::DataLocalize> togheter with  
L<CatalystX::I18N::DataLocalize>.

=head1 METHODS

=head3 localize

 my $translated_string = $c->localize($msgid,@params);
 OR
 my $translated_string = $c->localize($msgid,\@params);

Translates a string via L<Data::Localize>. 

=head1 SEE ALSO

L<Data::Localize>, L<CatalystX::I18N::Model::DataLocalize> 
and L<CatalystX::I18N::DataLocalize>

=head1 AUTHOR

    Maroš Kollár
    CPAN ID: MAROS
    maros [at] k-1.com
    
    L<http://www.k-1.com>