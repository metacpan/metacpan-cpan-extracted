#!perl

# ########################################################################## #
# Title:         Statement handle to datastream importer
# Creation date: 2007-03-05
# Author:        Michael Zedeler
# Description:   Produces a datastream from a DBI statement handle (DBI::st)
#                Data Stream class
#                Data importer
# File:          $Source: /data/cvs/lib/DSlib/lib/DS/Importer/Sth.pm,v $
# Repository:    kronhjorten
# State:         $State: Exp $
# Documentation: inline
# Recepient:     -
# ########################################################################## #

package DS::Importer::Sth;

use base qw{ DS::Importer };

use strict;
use Carp::Assert;

use DS::TypeSpec;
use DS::TypeSpec::Field;

our ($VERSION) = $DS::VERSION;
our ($REVISION) = '$Revision: 1.1 $' =~ /(\d+\.\d+)/;


sub new {
    my( $class, $sth, $target ) = @_;

    assert($sth->isa('DBI::st')); 
    
    my $type_fields = [];
    # TODO (V3) Replace NAME_lc with NAME to let developers choose case themselves
    foreach my $field_name ( @{$sth->{NAME_lc}} ) {
        push @$type_fields, new DS::TypeSpec::Field( $field_name );
    }

    my $typespec = new DS::TypeSpec( $type_fields );
    assert( $typespec );

    my $self = $class->SUPER::new( $typespec, $target );

    # Create keys in hash from $sth->{NAME_lc}
    @{ $self->{row} }{ @{$sth->{NAME_lc}} } = ();
    # Bind key row to statement handle
    $sth->bind_columns( \( @{ $self->{row} }{ @{$sth->{NAME_lc}} } ) );

    $self->{sth} = $sth;

    return $self;
}

sub _fetch {
    my($self) = @_;

    return $self->{sth}->fetch ? $self->{row} : undef;

}

1;
