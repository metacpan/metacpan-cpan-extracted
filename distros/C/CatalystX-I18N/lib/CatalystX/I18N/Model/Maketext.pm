# ============================================================================
package CatalystX::I18N::Model::Maketext;
# ============================================================================

use namespace::autoclean;
use Moose;
extends 'CatalystX::I18N::Model::Base';

use CatalystX::I18N::TypeConstraints;
use Path::Class;


has 'gettext_style' => (
    is          => 'rw', 
    isa         => 'Bool',
    default     => 1,
);

sub BUILD {
    my ($self) = @_;
    
    my $class = $self->class;

    # Load Maketext class
    my ($ok,$error) = Class::Load::try_load_class($class);
    Catalyst::Exception->throw(sprintf("Could not load '%s' : %s",$class,$error))
        unless $ok;
    
    Catalyst::Exception->throw(sprintf("Could initialize '%s' because is is not a 'Locale::Maketext' class",$class))
        unless $class->isa('Locale::Maketext');
    
    my $app = $self->_app;
    
    # Load lexicons in the Maketext class if possible
    if ($class->can('load_lexicon')) {
        my (@locales,%inhertiance,$config);
        $config = $app->config->{I18N}{locales};
        foreach my $locale (keys %$config) {
            push(@locales,$locale);
            $inhertiance{$locale} = $config->{$locale}{inherits}
                if defined $config->{$locale}{inherits};
        }
        $app->log->debug(sprintf("Loading maketext lexicons for locales %s",join(',',@locales)))
            if $app->debug;
            
        $class->load_lexicon( 
            locales             => \@locales, 
            directories         => $self->directories,
            gettext_style       => $self->gettext_style,
            inheritance         => \%inhertiance,
        );
    } else {
        $app->log->warn(sprintf("'%s' does not implement a 'load_lexicon' method",$class))
    }
    
    return;
}

sub ACCEPT_CONTEXT {
    my ( $self, $c ) = @_;
    
    # set locale and fallback
    my $handle = $self->class->get_handle( $c->locale );
    
    # Catch error
    Catalyst::Exception->throw(sprintf("Could not fetch lanuage handle for locale '%s'",$c->locale))
        unless ( scalar $handle );
    
    if ($self->can('fail_with')) {
        $handle->fail_with( sub { 
            $self->fail_with($c,@_);
        } );
    } else {
        $handle->fail_with( sub { } );
    }
    
    return $handle;
}

__PACKAGE__->meta->make_immutable( inline_constructor => 0 );
no Moose;
1;

=encoding utf8

=head1 NAME

CatalystX::I18N::Model::Maketext - Glues Locale::Maketext into Catalyst

=head1 SYNOPSIS

 # In your catalyst base class
 package MyApp::Catalyst;
 use Catalyst qw/CatalystX::I18N::Role::Base/;
 
 __PACKAGE__->config( 
    'Model::Maketext' => {
        class           => 'MyApp::Maketext', # optional
        directory       => '/path/to/maketext/files', # optional
    },
 );
 
 
 # Create a model class
 package MyApp::Model::Maketext;
 use parent qw/CatalystX::I18N::Model::Maketext/;
 
 
 # Create a Maketext class (must be a Locale::Maketext class)
 package MyApp::Maketext;
 use parent qw/CatalystX::I18N::Maketext/;
 
 
 # In your controller class(es)
 package MyApp::Controller::Main;
 use parent qw/Catalyst::Controller/;
 
 sub action : Local {
     my ($self,$c) = @_;
     
     my $model = $c->model('Maketext');
     $c->stash->{title} = $model->maketext('Hello world');
     # See CatalystX::I18N::Role::Maketext for a convinient wrapper
 }

=head1 DESCRIPTION

This model glues a L<Locale::Maketext> class 
(eg. L<CatalystX::I18N::Maketext>) into you Catalyst application. 

The method C<fail_with> will be called for each missing msgid if present
in your model class. 

 package MyApp::Model::Maketext;
 use parent qw/CatalystX::I18N::Model::Maketext/;
 
 sub fail_with {
     my ($self,$c,$language_handle,$msgid,$params) = @_;
     # Do somenthing clever
     return $string;
 }

See L<Catalyst::Helper::Model::Maketext> for gerating an Maketext model from 
the command-line.

=head1 CONFIGURATION

=head3 class

Set the L<Locale::Maketext> class you want to use from this model.

Defaults to $APPNAME::Maketext

=head3 gettext_style

Enable gettext style. C<%quant(%1,document,documents)> instead of 
C<[quant,_1,document,documents]>

Default TRUE

=head3 directory

List of directories to be searched for maketext files.

See L<CatalystX::I18N::Maketext> for more details on the C<directory> 
parameter

=head1 SEE ALSO

L<CatalystX::I18N::Maketext>, L<Locale::Maketext>, 
L<Locale::Maketext::Lexicon> and L<CatalystX::I18N::Role::Maketext>

=head1 AUTHOR

    Maroš Kollár
    CPAN ID: MAROS
    maros [at] k-1.com
    
    L<http://www.k-1.com>