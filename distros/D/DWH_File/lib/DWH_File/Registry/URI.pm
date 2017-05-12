package DWH_File::Registry::URI;

use warnings;
use strict;
use vars qw( @ISA $VERSION %registrands );
use DWH_File::Registry;

@ISA = qw( DWH_File::Registry );
$VERSION = 0.01;

BEGIN { %registrands = () }

sub new {
    my ( $this, $kernel, $property ) = @_;
    my $class = ref $this || $this;
    my $self = $class->SUPER::new( $kernel, $property );
    $self->{ tags } = {};
    $self->register( $kernel );
    return $self;
}

sub retrieve {
    my ( $self, $tag ) = @_;
    if ( exists $self->{ $tag } ) { return $self->{ $tag } }
    else {
	my $uri = $self->fetch( $tag );
	my $registrand = $registrands{ $uri };
	$self->{ tags }{ $uri } = $tag;
	$self->{ $tag } = $registrand;
	return $registrand;
    }
}

sub register {
    my ( $self, $registrand ) = @_;
    $registrands{ $registrand->uri } = $registrand;
}

sub tag {
    my ( $self, $registrand ) = @_;
    my $uri = $registrand->uri;
    if ( exists $self->{ tags }{ $uri } ) { return $self->{ tags }{ $uri } }
    else {
	my $tag = $self->get_key( $uri );
	$self->{ tags }{ $uri } = $tag;
	$self->{ $tag } = $registrand;
	return $tag;
    }
}

sub release {
    my ( $self, $registrand ) = @_;
    #for my $registry ( @instances ) { $registry->sign_out( $registrand ) }
}

sub sign_out {
    my ( $self, $registrand ) = @_;
    #delete $self->{ tags }{ $registrand->uri };
}

1;

__END__

=head1 NAME

DWH_File::Registry::URI - 

=head1 SYNOPSIS

DWH_File::Registry:URI is part of the DWH_File distribution. For
user-oriented documentation, see DWH_File documentation (perldoc
DWH_File).

=head1 DESCRIPTION



=head1 COPYRIGHT

Copyright (c) Jakob Schmidt 2002

This module is part of the DWH_File distribution. See DWH_File.pm.

=head1 AUTHORS

    Jakob Schmidt <schmidt@orqwood.dk>

=cut

CVS-log (non-pod)

    $Log: URI.pm,v $
    Revision 1.1  2002/12/19 21:59:37  schmidt
    This module repaces Registry.pm (the new Registry.pm is a superclass for this and other...)


