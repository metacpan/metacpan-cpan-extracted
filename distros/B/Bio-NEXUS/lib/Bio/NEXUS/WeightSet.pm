######################################################
# WeightSet.pm
######################################################
# Author: Chengzhi Liang, Weigang Qiu, Peter Yang, Thomas Hladish
# $Id: WeightSet.pm,v 1.26 2007/09/24 04:52:11 rvos Exp $

#################### START POD DOCUMENTATION ##################

=head1 NAME

Bio::NEXUS::WeightSet - Represents column weights in alignment ( for each character)

=head1 SYNOPSIS

new Bio::NEXUS::WeightSet($name, \@weights, $iswt);

=head1 DESCRIPTION

A module representing column weights in alignment (for each character)

=head1 FEEDBACK

All feedback (bugs, feature enhancements, etc.) are all greatly appreciated. 

=head1 AUTHOR

 Chengzhi Liang (liangc@umbi.umd.edu)
 Weigang Qiu (weigang@genectr.hunter.cuny.edu)
 Thomas Hladish (tjhladish at yahoo)

=head1 CONTRIBUTORS

 Peter Yang (pyang@rice.edu)

=head1 METHODS

=cut

package Bio::NEXUS::WeightSet;

use strict;
use Bio::NEXUS::Functions;
#use Data::Dumper; # XXX this is not used, might as well not import it!
#use Carp; # XXX this is not used, might as well not import it!
use Bio::NEXUS::Util::Exceptions;
use Bio::NEXUS::Util::Logger;
use vars qw($VERSION $AUTOLOAD);
use Bio::NEXUS; $VERSION = $Bio::NEXUS::VERSION;

my $logger = Bio::NEXUS::Util::Logger->new();

=head2 new

 Title   : new
 Usage   : $node = new Bio::NEXUS::WeightSet($name, \@weights);
 Function: Creates a new Bio::NEXUS::WeightSet object
 Returns : Bio::NEXUS::WeightSet object
 Args    : none

=cut

sub new {
    my ( $class, $name, $weights, $iswt, $tokens, $type ) = @_;
    my $self = {
        'name'       => $name,
        'weights'    => $weights,
        'is_wt'      => $iswt,
        '_is_tokens' => $tokens,
        'type'       => $type
    };
    bless $self, $class;
    return $self;
}

=begin comment

 Title   : _parse_weights
 Usage   : $self->_parse_weights(weight_string);
 Function: parses the weight string and store the contents to the object ($self)
 Returns : none
 Args    : weight-string from the WeightSet block in the NEXUS file

=end comment 

=cut

sub _parse_weights {
    my ( $self, $wt_string ) = @_;
    $wt_string =~ s/^\s+//;

    my $delimiter = '';
    if ( $self->_is_tokens() ) { $delimiter = '\s+' }

    my @weights = split /$delimiter/, $wt_string;
    $self->{'weights'} = [@weights];
}

=head2 set_weights

 Title   : set_weights
 Usage   : $weight->set_weights(\@weights);
 Function: stores it in the list weights
 Returns : none
 Args    : list of weights

=cut

sub set_weights {
    my ( $self, $weights ) = @_;
    $self->{'weights'} = $weights;
}

=head2 get_weights

 Title   : get_weights
 Usage   : @wts=@{$weightset->get_weights()};
 Function: Returns the weights array
 Returns : reference to array containing weights
 Args    : none

=cut

sub get_weights { shift->{'weights'} }

=head2 select_weights

 Title   : select_weights
 Usage   : $set->select_weights($columns);
 Function: select a subset of characters
 Returns : new self with subset of weights
 Args    : column numbers

=cut

sub select_weights {
    my ( $self, $columns ) = @_;
    my @weights    = @{ $self->{'weights'} };
    my @newweights = ();
    for my $i ( @{$columns} ) {
        push @newweights, $weights[$i];
    }
    $self->{'weights'} = \@newweights;
}

=head2 is_wt

 Title   : is_wt
 Usage   : croak unless $weight->is_wt();
 Function: Returns if object has weights (1 yes, 0 no)
 Returns : weight existence (integer)
 Args    : none

=cut

sub is_wt { !!shift->{'is_wt'} }

=begin comment

 Title   : _is_tokens
 Usage   : if ( $weight->_is_tokens() ) {}
 Function: tests whether tokens attribute is set to true
 Returns : boolean
 Args    : none

=end comment 

=cut

sub _is_tokens { !!shift->{'_is_tokens'} }

=begin comment

 Title   : _is_vector
 Usage   : if ( $weight->_is_vector() ) {}
 Function: tests whether type attribute is set to vector
 Returns : boolean
 Args    : none

=end comment 

=cut

sub _is_vector { uc( shift->{'type'} ) eq 'VECTOR' }

=head2 set_name

 Title   : set_name
 Usage   : $weight->set_name($name);
 Function: Sets the name of the weightset
 Returns : none
 Args    : name (string)

=cut

sub set_name {
    my ( $self, $name ) = @_;
    $self->{'name'} = $name;
}

=head2 get_name

 Title   : get_name
 Usage   : $name=$weight->get_name();
 Function: Returns the name of the weightset
 Returns : name (string)
 Args    : none

=cut

sub get_name { shift->{'name'} }

=head2 equals

 Name    : equals
 Usage   : $set->equals($another);
 Function: compare if two WeightSet objects are equal
 Returns : boolean 
 Args    : an WeightSet object

=cut

sub equals {
    my ( $self, $weights ) = @_;
    if ( $self->get_name() ne $weights->get_name() ) { return 0; }
    my @weights1 = @{ $self->get_weights() };
    my @weights2 = @{ $weights->get_weights() };
    if ( @weights1 != @weights2 ) { return 0; }
    for ( my $i = 0; $i < @weights1; $i++ ) {
        if ( $weights1[$i] eq $weights2[$i] ) { return 0; }
    }
    return 1;
}

sub AUTOLOAD {
    return if $AUTOLOAD =~ /DESTROY$/;
    my $package_name = __PACKAGE__ . '::';

    # The following methods are deprecated and are temporarily supported
    # via a warning and a redirection
    my %synonym_for = (
        "${package_name}is_tokens" => "${package_name}_is_tokens",
        "${package_name}is_vector" => "${package_name}_is_vector",
    );

    if ( defined $synonym_for{$AUTOLOAD} ) {
        $logger->warn( "$AUTOLOAD() is deprecated; use $synonym_for{$AUTOLOAD}() instead" );
        goto &{ $synonym_for{$AUTOLOAD} };
    }
    else {
        Bio::NEXUS::Util::Exceptions::UnknownMethod->throw(
        	'error' => "ERROR: Unknown method $AUTOLOAD called"
        );
    }
}

1;
