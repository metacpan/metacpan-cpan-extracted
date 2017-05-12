package CGI::Application::Plugin::YAML;


=head1 NAME

CGI::Application::Plugin::YAML - YAML methods for CGI::App

=head1 SYNOPSIS

Just a little wrapper. Useful to add YAML methods to you CGI::App object. The
whole YAML module is lazy loaded, so all that gets loaded at first is this
little wrapper.

    use CGI::Application::Plugin::YAML qw( :std );

Load YAML:-

    $self->YAML->Load( $yamldata );

Dump YAML:-

    $self->YAML->Dump( $perldata );

The methods LoadFile and DumpFile can also be imported. You need to specify
:max on your use.

    use CGI::Application::Plugin::YAML qw( :all );

Load YAML file:-

    $self->YAML->LoadFile( $yamldata );

Dump YAML file:-

    $self->YAML->DumpFile( $perldata );

=head1 DESCRIPTION

This module is a wrapper around C<YAML::Any>.
It uses YAML::Any so looks for the best YAML module your system has to offer.
There are Pure Perl YAML modules (such as YAML::Old) that you can easily
package with your app.
If like me you didn't like the idea of having functions called Dump and Load
imported to your namespace, then I'd use this wapper.

=head1 Methods

=head2 YAML

This is the object that gets exported.
See L</SYNOPSIS>

=head1 Export groups

Only an object called YAML is exported. The export groups allow you to choose
what methods that object contains.

:all exports:-

    Dump Load DumpFile LoadFile

:std exports:-

    Dump Load

=head1 FAQ

=head2 Why?

Having C<Dump> and C<Load> as functions are far to ambiguous for my liking.
This also making inheritance on the YAML methods a lot easier.

=head1 Thanks to:-

L<YAML>

=head1 Come join the bestest Perl group in the World!

Bristol and Bath Perl moungers is renowned for being the friendliest Perl group
in the world. You don't have to be from the UK to join, everyone is welcome on
the list:-
L<http://perl.bristolbath.org>

=head1 AUTHOR

Lyle Hopkins ;)

=cut



use strict;
use warnings;
use Carp;

use vars qw ( $VERSION @ISA @EXPORT_OK %EXPORT_TAGS $IMPORTGROUP );

require Exporter;
@ISA = qw(Exporter);

@EXPORT_OK = ( 'YAML' );

%EXPORT_TAGS = (
    all => [ 'YAML' ],
    std => [ 'YAML' ],
);

$VERSION = '0.03';

#$IMPORTGROUP = ':std';

my $yaml;

sub import {
#    local( $IMPORTGROUP );
#    $IMPORTGROUP = $_[1];
    $yaml = new CGI::Application::Plugin::YAML::guts( $_[1] );
    CGI::Application::Plugin::YAML->export_to_level(1, @_);
}#sub

sub YAML {
    unless ( $yaml->{params}->{__loaded} ) {
        $yaml->__LoadYAML();
    }#unless
    return $yaml;
}#sub


package CGI::Application::Plugin::YAML::guts;

sub new {
    my $class = shift;
#    require YAML::Any;
    my $obj = {
        params => {
            group => shift,
        },
    };
    $obj->{params}->{group} = ':std' unless $obj->{params}->{group};
    
#    if ( $CGI::Application::Plugin::YAML::IMPORTGROUP eq ':all' ) {
    if ( $obj->{params}->{group} eq ':all' ) {
#        YAML->import( qw( Dump Load DumpFile LoadFile ) );
        ### Overloading imported routines as class causes problems when called
        sub LoadFile {
            shift; ### get rid of class
            YAML::Any::LoadFile( @_ );
        }#sub
        sub DumpFile {
            shift;
            YAML::Any::DumpFile( @_ );
        }#sub
    }#if
    else {
        YAML->import( qw( Dump Load ) );
    }#else
    sub Load {
        shift;
        YAML::Any::Load( @_ );
    }#sub
    sub Dump {
        shift;
        YAML::Any::Dump( @_ );
    }#sub
    bless( $obj, $class );
    return $obj;
}#sub


sub __LoadYAML {
    require YAML::Any;
    YAML->import( qw( Dump Load DumpFile LoadFile ) );
}#sub


1;
