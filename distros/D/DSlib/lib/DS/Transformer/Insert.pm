#!perl

# ########################################################################## #
# Title:         Inserts rows - processor
# Creation date: 2007-03-05
# Author:        Michael Zedeler
# Description:   Inserts row found in stream
#                Data Stream class
# File:          $Source: /data/cvs/lib/DSlib/lib/DS/Transformer/Insert.pm,v $
# Repository:    kronhjorten
# State:         $State: Exp $
# Documentation: inline
# Recepient:     -
# ########################################################################## #

package DS::Transformer::Insert;

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

    my @placeholders = '';
    foreach my $field (@{$self->{typespec}->{fields}}) {
        push @placeholders, '?';
    }
    
    my $insert = join(' ',
        'INSERT INTO',
        $self->{typespec}->{name},
        ' (',
        join(', ', @{$self->{typespec}->{fields}}),
        ') VALUES (',
        join(', ', @placeholders),
        ')'
    );

    my $sth = $self->{dbh}->prepare_cached( $insert, undef, 3 );
    assert(defined($sth));
    
    $self->{insert_sth} = $sth;
}


sub process {
    my( $self, $row ) = @_;
    my $p_num = 1;
    
    foreach my $field (@{$self->{typespec}->{fields}}) {
        $self->{insert_sth}->bind_param( $p_num++, $row->{$field} );
    }

    return $row;   
}

1;
