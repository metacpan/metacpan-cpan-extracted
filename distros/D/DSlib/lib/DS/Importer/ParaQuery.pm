#!perl 

# ########################################################################## #
# Title:         Parameterized query builder
# Creation date: 2007-03-05
# Author:        Michael Zedeler
# Description:   Builds a query based on various parameters and a type
#                specification. 
# File:          $Source: /data/cvs/lib/DSlib/lib/DS/Importer/ParaQuery.pm,v $
# Repository:    kronhjorten
# State:         $State: Exp $
# Documentation: inline
# Recepient:     -
# #TODO make this class an importer that produces a DS 
# #TODO fix direct reference to $typespec->{name} and various obsolete attributes
# #TODO Inheritance seems to be broken, since DS::Producer is obsolete
# #TODO Probably defunct since 2.0
# ########################################################################## #

package DS::Importer::ParaQuery;

use base qw { DS::Importer };

use strict;
use Carp::Assert;

our ($VERSION) = $DS::VERSION;
our ($REVISION) = '$Revision: 1.1 $' =~ /(\d+\.\d+)/;


sub query {
    my($self, $filter, $sortby) = @_;

    my $select = "SELECT * FROM " . $self->{typespec}->{name};
    if(defined($filter)) {
        assert(ref($filter) eq 'HASH');
        
        my @ands = ();
        foreach my $field (keys %$filter) {
            if(exists($$filter{$field})) {
                if(defined($$filter{$field})) {
                    push @ands, "$field = ?";
                } else {
                    push @ands, "$field IS NULL";
                }
            }
        }
        
        if( $#ands > -1 ) {
            $select .= " WHERE " . join(" AND ", @ands);
        }
    }
    
    if(defined($sortby)) {
        assert(ref($sortby) eq 'HASH');

        my @sortkeys = ();
        foreach my $sortkey (keys %$sortby) {
            push @sortkeys, "$sortkey " . ($$sortby{$sortkey} < 0 ? 'DESC':'ASC');
        }
       
        if( $#sortkeys > -1 ) {
            $select .= ' ORDER BY ' . join(', ', @sortkeys);
        }
    }

    my $sth = $self->{dbh}->prepare_cached( $select, undef, 3 );
    assert(defined($sth));
    
    my $p_num = 1;
    foreach my $field (keys %$filter) {
        if(defined($$filter{$field})) {
           $sth->bind_param( $p_num++, $$filter{$field});
        }
    }

    #TODO This stuff is probably obsolete
    $self->bind($sth);

    $sth->execute();

    return $sth;
}

1;
