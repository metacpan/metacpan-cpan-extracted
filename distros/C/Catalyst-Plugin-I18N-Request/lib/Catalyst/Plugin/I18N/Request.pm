package Catalyst::Plugin::I18N::Request;

use strict;
use warnings;

use MRO::Compat;
use URI;
use URI::QueryParam;
use utf8;
use Scalar::Util ();

our $VERSION = '0.08';

=head1 NAME

Catalyst::Plugin::I18N::Request - A plugin for localizing/delocalizing 
paths and parameters.

=head1 SYNOPSIS
    
    package My::App;
    
    use Catalyst qw( ConfigLoader Static::Simple I18N I18N::Request );
    
    1;
    
    ...
    
    package My::App::Controller::Root;
    
    use base qw( Catalyst::Controller );
    
    sub search : Private {
        my ($self, $c) = @_;
        my $searchTerms = $c->req->param('searchTerms');
        # yadda, yadda, yadda...
    }
    
    ...
    
    French:
        
        Requested as:
            GET /recherche?terms_de_recherche=Pirates HTTP/1.0
            Accept-Language: fr
            
        Dispatched as:
            GET /search?searchTerms=Pirates HTTP/1.0
            Accept-Language: fr
            
        $c->uri_for('/search'):
            http://localhost/recherche
        
    German:
        
        Requested as:
            GET /suche?searchTerms=Pirates HTTP/1.0
            Accept-Language: de
            
        Dispatched as:
            GET /search?searchTerms=Pirates HTTP/1.0
            Accept-Language: de    
            
        $c->uri_for('/search'):
            http://localhost/suche

=head1 DESCRIPTION

This plugin is designed to work alongside Catalyst::Plugin::I18N in 
order to provide localization / delocalization of request paths and 
request parameter names.

=head1 DELOCALIZATION

Delocalization occurs when a request is first received, before any 
dispatching takes place. Delocalization assumes that there may exist 
paths or parameter names within the request which do not correlate to 
actual names used within the application itself. When functioning 
properly, this plugin will allow users to activate an action called 
'search' using:
    
    'recherche' (French requests)
    'suche'     (German requests)
     etc... 

This relies on the localize method provided to the application by 
Catalyst::Plugin::I18N. For the above examples to work, the following 
localizations must occur:
    
    Key                       | Localized text  | Language
    ==========================================================
    PATH_delocalize_recherche | search          | French
    PATH_delocalize_suche     | search          | German

That is, $c->localize('PATH_delocalize_recherche') must return 'search'.
A very similar behaviour applies to parameter names within the query 
string. The keys for these delocalizations begin with 
'PARAMETER_delocalize_' instead of 'PATH_delocalize_'.

=head1 LOCALIZATION

Localization involves taking paths and parameter names and replacing 
them with values which make more sense to users speaking the requested 
language. In the above example, 'search' may not look intuitive to 
German users. Out of the box, this plugin allows you to localize these 
values transparently via the standard $c->uri_for and 
$c->request->uri_with methods which are already standard features of 
the Catalyst framework. 

Like delocalization, this functionality depends upon the $c->localize 
method. However, PATH_delocalize_ is replaced with PATH_localize and 
PARAMETER_delocalize_ is replaced with PARAMETER_localize_. 
    
    Key                  | Localized text  | Language
    ==========================================================
    PATH_localize_search | recherche       | French
    PATH_localize_search | suche           | German

=head1 METHODS

=head2 setup ( )

Allows Catalyst::Request to localize the results of calls to uri_with. 

=cut

sub setup {
    my $self = shift;
    $self->next::method( @_ );
    
    no strict 'refs';
    no warnings 'redefine';
    
    my $uri_with = \&Catalyst::Request::uri_with;
    
    *Catalyst::Request::uri_with = sub {
        my ($request) = @_;
        my $uri = $uri_with->( @_ );
        
        return $request->{_context}->localize_uri( $uri );
    };
}

=head2 prepare ( )

Overrides Catalyst's C<prepare> method to push the context object to the request
object.

=cut

sub prepare {
    my $c = shift;
    $c = $c->next::method( @_ );

    unless( $c->request->{ _context } ) {
        Scalar::Util::weaken( $c->request->{ _context } = $c );
    }

    return $c;
}

=head2 uri_for ( $path [, @args ] [, \%query_values ] )

Calls the native uri_for, but proceeds to localize the resulting path 
and query values.

=cut

sub uri_for {
    my $c = shift;
    $c->localize_uri( $c->next::method( @_ ) );
}

=head2 localize_uri ( $uri )

Localizes a URI using the current context.

=cut

sub localize_uri {
    my ($c, $uri) = @_;
    return undef unless defined $uri;
    
    $uri = URI->new( $uri ) unless Scalar::Util::blessed( $uri );
    
    # parameters
    my $query_form = $uri->query_form_hash;
    
    # decode all strings for character logic rather than byte logic
    for my $value ( values %$query_form ) {
        for ( ref $value eq 'ARRAY' ? @$value : $value ) {
            $_ = "$_";
            utf8::decode( $_ );
        }
    }
    
    # localize the parameters
    my $parameters = $c->localize_parameters( $query_form );
    
    # encode all strings for byte logic rather than character logic
    for my $value ( values %$parameters ) {
        for ( ref $value eq 'ARRAY' ? @$value : $value ) {
            $_ = "$_";
            utf8::encode( $_ );
        }
    }
    
    $uri->query_form_hash( $parameters );
    
    # path
    $uri->path( $c->localize_path( $uri->path ) );
    
    return $uri;
}

=head2 localize_path ( $path )

Localizes all components of the provided path. 

=cut

sub localize_path {
    my ($c, $path) = @_;
    return undef unless defined $path;
    return join '/', map { $c->localize_path_component( $_ ) } split m!/!, $path;
}

=head2 delocalize_path ( $path )

Delocalizes all components of the provided path.

=cut

sub delocalize_path {
    my ($c, $path) = @_;
    return undef unless defined $path;
    return join '/', map { $c->delocalize_path_component( $_ ) } split m!/!, $path;
}

=head2 transform_parameters ( \%parameters, $transformer )

Transforms the given parameter names using the given transformer. The 
transformer may be one of the following:

=over 4

=item * A CODE reference which accepts the context object as the first 
        argument and a parameter name as the second argument. 

=item * The name of a particular accessor that can be called on the 
        context object, accepting a parameter name as the argument. 

=back

=cut

sub transform_parameters {
    my ($c, $parameters, $transformer) = @_;
    my %parameters = ref $parameters eq 'HASH' ? %$parameters : ();
    
    my %transformed;
    for ( keys %parameters ) {
        my $name  = ref $transformer eq 'CODE' ? $transformer->( $c, $_ )
                  : $c->can($transformer)      ? $c->$transformer( $_ )
                  : $_;
        
        my $value = $parameters{ $_ };
        
        if ( exists $transformed{$name} ) {
            if ( ref $transformed{$name} eq 'ARRAY' ) {
                push @{ $transformed{$name} }, ref $value eq 'ARRAY' ? @$value : $value;
            }
            else {
                $transformed{$name} = [ $transformed{$name}, ref $value eq 'ARRAY' ? @$value : $value ];
            }
        }
        else {
            $transformed{$name} = $value;
        }
    }
    
    return wantarray ? %transformed : \%transformed;
}

=head2 localize_parameters ( \%parameters )

Localizes the keys within a hash of parameters. 

=cut

sub localize_parameters {
    my $c = shift;
    my %parameters = ref $_[0] eq 'HASH' ? %{ $_[0] } : @_;
    $c->transform_parameters( \%parameters, 'localize_parameter_name' );
}


=head2 delocalize_parameters ( \%parameters )

Delocalizes the keys within a hash of parameters. 

=cut

sub delocalize_parameters {
    my $c = shift;
    my %parameters = ref $_[0] eq 'HASH' ? %{ $_[0] } : @_;
    $c->transform_parameters( \%parameters, 'delocalize_parameter_name' );
}


=head2 prepare_path ( )

Delocalizes the requested path. 

=cut

sub prepare_path {
    my $c = shift;
    $c->next::method( @_ );
    $c->req->path( $c->delocalize_path( $c->req->path ) );
}

=head2 prepare_parameters ( )

Delocalizes the requested parameter names. 

=cut

sub prepare_parameters {
    my $c = shift;
    $c->next::method( @_ );
    
    my %parameters = $c->delocalize_parameters( $c->request->params );
    
    $c->request->uri->query_form( \%parameters );
    $c->request->params( \%parameters );
}

=head2 localize_path_component ( $delocalized )

Localizes a component of a path. 

=cut

sub localize_path_component {
    my ($c, $delocalized) = @_;
    return undef unless defined $delocalized;
    
    if ( $c->can('localize') ) {
        my $key = "PATH_localize_$delocalized";
        my $localized = $c->localize($key);
        return $localized unless $localized eq $key;
    }
    
    return $delocalized;
}

=head2 delocalize_path_component ( $localized )

Delocalizes a component of a path. 

=cut

sub delocalize_path_component {
    my ($c, $localized) = @_;
    return undef unless defined $localized;
    
    if ( $c->can('localize') ) {
        my $key = "PATH_delocalize_$localized";
        my $delocalized = $c->localize($key);
        return $delocalized unless $delocalized eq $key;
    }
    
    return $localized;
}

=head2 localize_parameter_name ( $delocalized )

Localizes a parameter name. 

=cut

sub localize_parameter_name {
    my ($c, $delocalized) = @_;
    return undef unless defined $delocalized;
    
    if ( $c->can('localize') ) {
        my $key = "PARAMETER_localize_$delocalized";
        my $localized = $c->localize($key);
        return $localized unless $localized eq $key;
    }
    
    return $delocalized;
}

=head2 delocalize_parameter_name ( $localized )

Delocalizes a parameter name. 

=cut

sub delocalize_parameter_name {
    my ($c, $localized) = @_;
    return undef unless defined $localized;
    
    if ( $c->can('localize') ) {
        my $key = "PARAMETER_delocalize_$localized";
        my $delocalized = $c->localize($key);
        return $delocalized unless $delocalized eq $key;
    }
    
    return $localized;
}

=head1 SEE ALSO

=over 4

=item * L<Catalyst::Plugin::I18N>

=item * L<Catalyst>

=back

=head1 AUTHORS

Adam Paynter E<lt>adapay@cpan.orgE<gt>

Brian Cassidy E<lt>bricas@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2006-2012 by Adam Paynter, Brian Cassidy

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

1;
