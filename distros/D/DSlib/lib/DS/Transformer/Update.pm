#!perl

# ########################################################################## #
# Title:         Update rows - processor
# Creation date: 2007-03-05
# Author:        Michael Zedeler
# Description:   Updates rows found in stream
#                Data Stream class
# File:          $Source: /data/cvs/lib/DSlib/lib/DS/Transformer/Update.pm,v $
# Repository:    kronhjorten
# State:         $State: Exp $
# Documentation: inline
# Recepient:     -
# ########################################################################## #

package DS::Transformer::Update;

use base qw { DS::Transformer };

use strict;
use Carp::Assert;

our ($VERSION) = $DS::VERSION;
our ($REVISION) = '$Revision: 1.1 $' =~ /(\d+\.\d+)/;


sub new {
    my( $class, $dbh, $typespec, $source ) = @_;

    my $self = $class->SUPER::new( $typespec, $source );

    assert($dbh->isa('DBI::db'));

    $self->{dbh} = $dbh;

    my $p_num = 1;
    my %bind_map = ();
    my @ands;
    my @sets;
    foreach my $field (@{$self->{typespec}->{fields}}) {
        next if $self->{typespec}->{pk_lookup}->{$field};
        push @sets, "$field = ?";
        $bind_map{$field} = $p_num++;
    }
    foreach my $pk (@{$self->{typespec}->{pks}}) {
        push @ands, "$pk = ?";
        $bind_map{$pk} = $p_num++;
    }
    my $update = join(' ',
        'UPDATE', 
        $self->{typespec}->{name},
        'SET',
        join(', ', @sets),
        'WHERE',
        join(' AND ', @ands)
    );

    my $sth = $self->{dbh}->prepare_cached( $update, undef, 3 );
    assert(defined($sth));
    
    $self->{update_sth} = $sth;
    $self->{bind_map} = \%bind_map;
    
    return $self;
}


sub process {
    my( $self, $row ) = @_;

    foreach my $field (keys %{$self->{bind_map}}) {
        assert(exists($row->{$field}));
        if( $self->{typespec}->{pk_lookup}->{$field} and not defined( $row->{$field} )) {
            die "The field $field is undefined but also primary key. Refusing to do an UPDATE ... WHERE ... $field IS NULL";
        }
        $self->{update_sth}->bind_param( $self->{bind_map}->{$field}, $row->{$field} );
    }

    $row = $self->{update_sth}->execute() ? $row : undef;

    return $row;   
}

1;
