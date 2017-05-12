#!perl 

# ########################################################################## #
# Title:         Hash to datastream generator
# Creation date: 2007-03-05
# Author:        Michael Zedeler
# Description:   Produces a datastream from a hash reference
#                Data Stream class
#                Data importer
# File:          $Source: /data/cvs/lib/DSlib/lib/DS/Importer/Hash.pm,v $
# Repository:    kronhjorten
# State:         $State: Exp $
# Documentation: inline
# Recepient:     Dataservice
# ########################################################################## #

package DS::Importer::Hash;

use base qw{ DS::Importer };

use strict;
use Carp::Assert;

our ($VERSION) = $DS::VERSION;
our ($REVISION) = '$Revision: 1.1 $' =~ /(\d+\.\d+)/;


use constant DS_IMPORTER_HASH_INIT    => 1;
use constant DS_IMPORTER_HASH_FETCHED => 2;
use constant DS_IMPORTER_HASH_DONE    => 3;

#TODO Get type spec from keys in hash
sub new {
    my( $class, $data_source, $target, $typespec) = @_;

    my $self = $class::SUPER->new( $typespec, $target );

    assert(ref($data_source) eq 'HASH');    
    $self->{data_source} = {%$data_source};
    $self->{state} = DS_IMPORTER_HASH_INIT;

    return $self;
}

sub _fetch {
    my($self) = @_;

    my $result = undef;
    
    if($self->{state} == DS_IMPORTER_HASH_INIT) {
        %{$self->{row}} = %{$self->{data_source}};
        $self-> {state} = DS_IMPORTER_HASH_FETCHED;
        $result = 1;
    } elsif($self->{state} == DS_IMPORTER_HASH_FETCHED) {
        %{$self->{row}} = ();
        $self-> {state} = DS_IMPORTER_HASH_DONE;
    }

    return $result ? $self->{row} : undef;
}

1;


